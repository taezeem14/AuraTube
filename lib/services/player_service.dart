import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import '../models/youtube_video.dart';
import 'youtube_service.dart';

enum PlayerMode { none, video, backgroundAudio }

class PlayerService extends ChangeNotifier {
  YouTubeVideo? _currentVideo;
  PlayerMode _mode = PlayerMode.none;
  bool _isLoading = false;
  String? _errorMessage;

  // Video controller
  VideoPlayerController? _videoController;

  // Audio controller with Hardware Equalizer DSP
  late final AudioPlayer _audioPlayer;
  final AndroidEqualizer _equalizer = AndroidEqualizer();
  bool _eqEnabled = true;
  double _bassBoost = 0.4;
  String _currentPreset = 'Flat';
  final Map<int, double> _customBandGains = {};

  // Quality & Playback settings
  List<String> _resolutions = [];
  double _playbackSpeed = 1.0;

  YouTubeVideo? get currentVideo => _currentVideo;
  PlayerMode get mode => _mode;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  VideoPlayerController? get videoController => _videoController;
  AudioPlayer get audioPlayer => _audioPlayer;
  bool get isPlaying =>
      _mode == PlayerMode.video
          ? (_videoController?.value.isPlaying ?? false)
          : _audioPlayer.playing;

  // EQ Getters
  AndroidEqualizer get equalizer => _equalizer;
  bool get eqEnabled => _eqEnabled;
  double get bassBoost => _bassBoost;
  String get currentPreset => _currentPreset;
  Map<int, double> get customBandGains => _customBandGains;
  List<String> get resolutions => _resolutions;
  double get playbackSpeed => _playbackSpeed;

  PlayerService() {
    _initAudio();
  }

  void _initAudio() {
    try {
      if (Platform.isAndroid) {
        _audioPlayer = AudioPlayer(
          audioPipeline: AudioPipeline(
            androidAudioEffects: [_equalizer],
          ),
        );
      } else {
        _audioPlayer = AudioPlayer();
      }
    } catch (_) {
      _audioPlayer = AudioPlayer();
    }

    _audioPlayer.playerStateStream.listen((_) => notifyListeners());
  }

  // Play a YouTube Video
  Future<void> playVideo(YouTubeVideo video, {bool startAsBackgroundAudio = false}) async {
    _isLoading = true;
    _errorMessage = null;
    _currentVideo = video;
    notifyListeners();

    try {
      // 1. Resolve direct streams
      final streams = await YouTubeService.resolveStreams(video.id);
      if (streams == null) {
        throw Exception('Failed to resolve playable streams for this video');
      }

      _resolutions = streams.availableResolutions;
      _currentVideo = video.copyWith(
        streamUrl: streams.videoUrl,
        audioStreamUrl: streams.audioUrl,
      );

      if (startAsBackgroundAudio) {
        await playBackgroundAudio(_currentVideo!);
      } else {
        // Stop audio player if active
        await _audioPlayer.stop();

        // Dispose previous video controller
        await _videoController?.dispose();
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(streams.videoUrl),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );

        await _videoController!.initialize();
        await _videoController!.setPlaybackSpeed(_playbackSpeed);
        await _videoController!.play();
        _videoController!.addListener(() => notifyListeners());

        _mode = PlayerMode.video;
      }
    } catch (e) {
      debugPrint('[PlayerService] Play error: $e');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Switch to background audio playback (with EQ enabled)
  Future<void> playBackgroundAudio(YouTubeVideo video) async {
    _isLoading = true;
    _currentVideo = video;
    notifyListeners();

    try {
      // Pause/dispose video
      final currentPos = _videoController?.value.position ?? Duration.zero;
      if (_videoController != null) {
        await _videoController!.pause();
      }

      String audioUrl = video.audioStreamUrl ?? '';
      if (audioUrl.isEmpty) {
        final streams = await YouTubeService.resolveStreams(video.id);
        audioUrl = streams?.audioUrl ?? streams?.videoUrl ?? '';
      }

      if (audioUrl.isNotEmpty) {
        await _audioPlayer.setUrl(audioUrl);
        if (currentPos > Duration.zero) {
          await _audioPlayer.seek(currentPos);
        }
        await _audioPlayer.setSpeed(_playbackSpeed);
        await _audioPlayer.play();
        _mode = PlayerMode.backgroundAudio;

        // Apply Equalizer
        await applyEqualizerPreset(_currentPreset);
      }
    } catch (e) {
      debugPrint('[PlayerService] Background audio error: $e');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle Play / Pause
  Future<void> togglePlayPause() async {
    if (_mode == PlayerMode.video && _videoController != null) {
      if (_videoController!.value.isPlaying) {
        await _videoController!.pause();
      } else {
        await _videoController!.play();
      }
    } else if (_mode == PlayerMode.backgroundAudio) {
      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    }
    notifyListeners();
  }

  // Seek
  Future<void> seek(Duration position) async {
    if (_mode == PlayerMode.video && _videoController != null) {
      await _videoController!.seekTo(position);
    } else if (_mode == PlayerMode.backgroundAudio) {
      await _audioPlayer.seek(position);
    }
    notifyListeners();
  }

  // Playback speed
  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    if (_videoController != null) {
      await _videoController!.setPlaybackSpeed(speed);
    }
    await _audioPlayer.setSpeed(speed);
    notifyListeners();
  }

  // ----------------------------------------------------
  // Equalizer & Sound Shaping Methods
  // ----------------------------------------------------
  Future<void> setEqualizerEnabled(bool enabled) async {
    _eqEnabled = enabled;
    try {
      if (Platform.isAndroid) {
        await _equalizer.setEnabled(enabled);
        if (enabled) {
          await applyEqualizerPreset(_currentPreset);
        }
      }
    } catch (e) {
      debugPrint('[PlayerService] setEqualizerEnabled error: $e');
    }
    notifyListeners();
  }

  Future<void> setBassBoost(double value) async {
    _bassBoost = value.clamp(0.0, 1.0);
    try {
      if (Platform.isAndroid && _eqEnabled) {
        await applyEqualizerPreset(_currentPreset);
      }
    } catch (e) {
      debugPrint('[PlayerService] setBassBoost error: $e');
    }
    notifyListeners();
  }

  Future<void> setBandGain(int bandIndex, double gain) async {
    _customBandGains[bandIndex] = gain;
    try {
      if (Platform.isAndroid) {
        final params = await _equalizer.parameters;
        if (bandIndex >= 0 && bandIndex < params.bands.length) {
          final clamped = gain.clamp(params.minDecibels, params.maxDecibels);
          await params.bands[bandIndex].setGain(clamped);
        }
      }
    } catch (e) {
      debugPrint('[PlayerService] setBandGain error: $e');
    }
    notifyListeners();
  }

  Future<void> applyEqualizerPreset(String preset) async {
    _currentPreset = preset;
    try {
      if (!Platform.isAndroid) return;
      final params = await _equalizer.parameters;
      final bands = params.bands;
      final n = bands.length;
      if (n == 0) return;

      final bassAdd = _bassBoost * 9.0;
      final lowMidAdd = _bassBoost * 4.5;

      switch (preset) {
        case 'Bass Heavy':
          for (int i = 0; i < n; i++) {
            if (i == 0) {
              await bands[i].setGain((8.0 + bassAdd).clamp(params.minDecibels, params.maxDecibels));
            } else if (i == 1) {
              await bands[i].setGain((5.0 + lowMidAdd).clamp(params.minDecibels, params.maxDecibels));
            } else {
              await bands[i].setGain(0.0);
            }
          }
          break;
        case 'Rock':
          if (n >= 5) {
            await bands[0].setGain((5.0 + bassAdd).clamp(params.minDecibels, params.maxDecibels));
            await bands[1].setGain((3.0 + lowMidAdd).clamp(params.minDecibels, params.maxDecibels));
            await bands[2].setGain((-1.0).clamp(params.minDecibels, params.maxDecibels));
            await bands[3].setGain((3.5).clamp(params.minDecibels, params.maxDecibels));
            await bands[4].setGain((5.5).clamp(params.minDecibels, params.maxDecibels));
          }
          break;
        case 'Pop':
          if (n >= 5) {
            await bands[0].setGain((-1.5 + bassAdd).clamp(params.minDecibels, params.maxDecibels));
            await bands[1].setGain((2.0 + lowMidAdd).clamp(params.minDecibels, params.maxDecibels));
            await bands[2].setGain((5.0).clamp(params.minDecibels, params.maxDecibels));
            await bands[3].setGain((2.5).clamp(params.minDecibels, params.maxDecibels));
            await bands[4].setGain((-1.0).clamp(params.minDecibels, params.maxDecibels));
          }
          break;
        case 'Vocal':
          if (n >= 5) {
            await bands[0].setGain((-2.0).clamp(params.minDecibels, params.maxDecibels));
            await bands[1].setGain((1.0).clamp(params.minDecibels, params.maxDecibels));
            await bands[2].setGain((5.5).clamp(params.minDecibels, params.maxDecibels));
            await bands[3].setGain((3.5).clamp(params.minDecibels, params.maxDecibels));
            await bands[4].setGain((1.0).clamp(params.minDecibels, params.maxDecibels));
          }
          break;
        case 'Electronic':
          if (n >= 5) {
            await bands[0].setGain((6.0 + bassAdd).clamp(params.minDecibels, params.maxDecibels));
            await bands[1].setGain((3.0 + lowMidAdd).clamp(params.minDecibels, params.maxDecibels));
            await bands[2].setGain((0.0).clamp(params.minDecibels, params.maxDecibels));
            await bands[3].setGain((2.0).clamp(params.minDecibels, params.maxDecibels));
            await bands[4].setGain((4.0).clamp(params.minDecibels, params.maxDecibels));
          }
          break;
        case 'Flat':
        default:
          for (int i = 0; i < n; i++) {
            if (i == 0) {
              await bands[i].setGain((0.0 + bassAdd).clamp(params.minDecibels, params.maxDecibels));
            } else if (i == 1) {
              await bands[i].setGain((0.0 + lowMidAdd).clamp(params.minDecibels, params.maxDecibels));
            } else {
              await bands[i].setGain(0.0);
            }
          }
          break;
      }
    } catch (e) {
      debugPrint('[PlayerService] applyEqualizerPreset error: $e');
    }
    notifyListeners();
  }

  Future<void> resetEqualizer() async {
    _currentPreset = 'Flat';
    _bassBoost = 0.0;
    _customBandGains.clear();
    await applyEqualizerPreset('Flat');
    notifyListeners();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}
