import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:new_youtube/models/song.dart';
import 'package:new_youtube/models/comment.dart';
import 'package:new_youtube/models/playlist.dart';
import 'package:new_youtube/models/subscription.dart';
import 'package:new_youtube/services/storage_service.dart';
import 'package:new_youtube/services/youtube_feed_service.dart';
import 'package:new_youtube/services/audio_handler.dart';
import 'package:new_youtube/services/sponsorblock_service.dart';
import 'package:new_youtube/services/youtube_cipher_service.dart';
import 'package:new_youtube/services/lyrics_service.dart';
import 'package:new_youtube/services/music_detection_service.dart';
import 'package:new_youtube/services/local_music_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuraTube Models & Data Structures', () {
    test('Song model serialization and formatted properties', () {
      final song = Song(
        id: 'dQw4w9WgXcQ',
        title: 'Never Gonna Give You Up',
        artist: 'Rick Astley',
        duration: const Duration(minutes: 3, seconds: 33),
        artworkUrl: 'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
        streamUrl: 'https://rr1---sn.googlevideo.com/videoplayback?id=123',
        viewCount: 1450000000,
        viewCountFormatted: '1.4B views',
        uploadDateFormatted: '14 years ago',
        videoQuality: '1080p',
      );

      expect(song.id, 'dQw4w9WgXcQ');
      expect(song.formattedDuration, '3:33');
      expect(song.formattedViews, '1.4B views');

      final restored = Song.fromMap(song.toMap());
      expect(restored.id, song.id);
      expect(restored.title, song.title);
      expect(restored.duration.inSeconds, 213);
    });

    test('Playlist model creation and copyWith', () {
      final song = Song(
        id: 'test_1',
        title: 'Track One',
        artist: 'Artist One',
        duration: const Duration(seconds: 180),
        artworkUrl: '',
        streamUrl: 'https://example.com/audio.mp3',
      );

      final pl = Playlist(
        id: 'pl_1',
        title: 'My Rock Playlist',
        songs: [song],
        createdAt: DateTime.now(),
      );

      expect(pl.title, 'My Rock Playlist');
      expect(pl.name, 'My Rock Playlist');
      expect(Playlist.fromMap(pl.toMap()).songs.length, 1);
    });

    test('LocalSubscription and AuraComment models', () {
      final sub = LocalSubscription(
        channelId: 'UCuAXFkgsw1L7xaCfnd5JJOw',
        name: 'Rick Astley',
        avatarUrl: 'https://yt3.ggpht.com/avatar.jpg',
        subscriberCount: '3.5M',
        subscribedAt: DateTime.now(),
      );
      expect(LocalSubscription.fromJson(sub.toJson()).subscriberCount, '3.5M');

      const comment = AuraComment(
        author: 'MusicLover',
        authorThumbnail: '',
        text: 'Absolute classic!',
        publishedTime: '2 days ago',
        likeCount: 450,
      );
      expect(comment.formattedLikes, '450');
    });
  });

  group('Sine & just_audio Priority-1000 DSP Equalizer', () {
    test('6-band log-frequency hardware interpolation', () {
      const curve = [6.0, 4.0, 0.0, -2.0, 2.0, 5.0];
      expect(SineAudioHandler.interpolateSixBandGain(60.0, curve), closeTo(6.0, 0.01));
      expect(SineAudioHandler.interpolateSixBandGain(1000.0, curve), closeTo(-2.0, 0.01));
      expect(SineAudioHandler.interpolateSixBandGain(15000.0, curve), closeTo(5.0, 0.01));
      // 230 Hz hardware band lies logarithmically between 150 Hz (+4.0) and 400 Hz (0.0)
      final mid = SineAudioHandler.interpolateSixBandGain(230.0, curve);
      expect(mid, greaterThan(0.0));
      expect(mid, lessThan(4.0));
    });

    test('EqualizerBandInfo decibel bounds', () {
      const band = EqualizerBandInfo(
        index: 0,
        centerFrequency: 60,
        label: '60 Hz',
        gain: 3.5,
      );
      expect(band.minDecibels, -12.0);
      expect(band.maxDecibels, 12.0);
    });
  });

  group('Zemer-Cipher Pure-Dart Transformations', () {
    test('Reverse, slice, and swap cipher ops', () {
      expect(const CipherOp(CipherOpType.reverse).apply('abcdef'), 'fedcba');
      expect(const CipherOp(CipherOpType.slice, 2).apply('abcdef'), 'cdef');
      expect(const CipherOp(CipherOpType.swap, 3).apply('abcdef'), 'dbcaef');
    });
  });

  group('SponsorBlock 8-Category Engine', () {
    test('Merges overlapping segments and exposes all 8 categories', () {
      expect(SponsorBlockService.allCategories.length, 8);
      final merged = SponsorBlockService.mergeSegments(const [
        SponsorSegment(start: 10.0, end: 25.0, category: 'sponsor'),
        SponsorSegment(start: 25.2, end: 35.0, category: 'selfpromo'),
        SponsorSegment(start: 60.0, end: 72.0, category: 'outro'),
      ]);
      expect(merged.length, 2);
      expect(merged.first.start, 10.0);
      expect(merged.first.end, 35.0);
      expect(merged.last.displayLabel, 'Endcards / Outro');
    });
  });

  group('BetterLyrics Cleaning & Tempo Guard', () {
    test('Strips YouTube video noise tags and detects slowed/reverb', () {
      expect(LyricsService.cleanTitle('Blinding Lights (Official Music Video) [4K]'), 'Blinding Lights');
      expect(LyricsService.cleanArtist('The Weeknd - Topic'), 'The Weeknd');
      expect(LyricsService.isTempoModified('After Hours (Slowed + Reverb)'), true);
      expect(LyricsService.isTempoModified('After Hours'), false);
    });
  });

  group('Audile Shazam Fingerprinting & Local Music Parser', () {
    test('CRC32 checksum & PCM16 resampler produce valid output', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      final crc = ShazamCrc32.compute(bytes, 0, bytes.length);
      expect(crc, isNonZero);

      final pcmIn = Uint8List(4410 * 2); // 100ms @ 44.1kHz mono 16-bit
      final pcmOut = AudioResampler.resamplePcm16(pcmIn, 44100, 16000);
      expect(pcmOut.length, closeTo(1600 * 2, 16));
    });

    test('LocalMusicService parses Artist - Title filenames', () {
      final parsed = LocalMusicService.parseArtistAndTitle('Daft Punk - Instant Crush.flac');
      expect(parsed.$1, 'Daft Punk');
      expect(parsed.$2, 'Instant Crush');
    });
  });

  group('StorageService Persistence, Insights & Full JSON Backup', () {
    late StorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = await StorageService.init();
    });

    test('Subscriptions, Favorites, History, EQ, SponsorBlock & Backup roundtrip', () async {
      final sub = LocalSubscription(
        channelId: 'chan_123',
        name: 'Tech Channel',
        avatarUrl: '',
        subscribedAt: DateTime.now(),
      );
      expect(await storage.toggleSubscription(sub), true);

      final song = Song(
        id: 'fav_1',
        title: 'Favorite Song',
        artist: 'Favorite Artist',
        duration: const Duration(seconds: 200),
        artworkUrl: '',
        streamUrl: 'https://example.com/audio.mp3',
      );
      await storage.saveFavorites([song]);
      await storage.savePitch(1.15);
      await storage.saveSkipSilence(true);
      await storage.saveSponsorBlockCategories({'sponsor', 'intro', 'music_offtopic'});

      final exported = storage.exportFullBackupJson();
      expect(exported.contains('Tech Channel'), true);
      expect(exported.contains('Favorite Song'), true);

      // Reset storage and restore from JSON backup
      SharedPreferences.setMockInitialValues({});
      final freshStorage = await StorageService.init();
      expect(freshStorage.loadFavorites().isEmpty, true);

      final restoredOk = await freshStorage.importFullBackupJson(exported);
      expect(restoredOk, true);
      expect(freshStorage.loadFavorites().length, 1);
      expect(freshStorage.loadSubscriptions().length, 1);
      expect(freshStorage.loadPitch(), closeTo(1.15, 0.001));
      expect(freshStorage.loadSkipSilence(), true);
      expect(freshStorage.loadSponsorBlockCategories().contains('music_offtopic'), true);
    });
  });

  group('YouTube Feed Service Categories', () {
    test('Categories catalog & ID sanitizer', () {
      final categories = YouTubeFeedService.categories;
      expect(categories.any((c) => c['id'] == 'all'), true);
      expect(categories.any((c) => c['id'] == 'music'), true);
      expect(categories.any((c) => c['id'] == 'tech'), true);
      expect(YouTubeFeedService.cleanVideoId('yt_dQw4w9WgXcQ'), 'dQw4w9WgXcQ');
    });
  });
}
