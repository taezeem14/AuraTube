import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:new_youtube/models/song.dart';
import 'package:new_youtube/models/comment.dart';
import 'package:new_youtube/models/playlist.dart';
import 'package:new_youtube/models/subscription.dart';
import 'package:new_youtube/services/storage_service.dart';
import 'package:new_youtube/services/youtube_feed_service.dart';
import 'package:new_youtube/services/audio_handler.dart';

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
      expect(song.title, 'Never Gonna Give You Up');
      expect(song.formattedDuration, '3:33');
      expect(song.formattedViews, '1.4B views');

      final map = song.toMap();
      final restored = Song.fromMap(map);
      expect(restored.id, song.id);
      expect(restored.title, song.title);
      expect(restored.artist, song.artist);
      expect(restored.duration.inSeconds, 213);
      expect(restored.viewCount, 1450000000);
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
      expect(pl.songs.length, 1);

      final map = pl.toMap();
      final restored = Playlist.fromMap(map);
      expect(restored.id, pl.id);
      expect(restored.title, pl.title);
      expect(restored.songs.length, 1);
    });

    test('LocalSubscription model serialization', () {
      final sub = LocalSubscription(
        channelId: 'UCuAXFkgsw1L7xaCfnd5JJOw',
        name: 'Rick Astley',
        avatarUrl: 'https://yt3.ggpht.com/avatar.jpg',
        subscriberCount: '3.5M',
        subscribedAt: DateTime.now(),
      );

      expect(sub.name, 'Rick Astley');
      final json = sub.toJson();
      final restored = LocalSubscription.fromJson(json);
      expect(restored.channelId, sub.channelId);
      expect(restored.name, sub.name);
      expect(restored.subscriberCount, '3.5M');
    });

    test('AuraComment model structure', () {
      const comment = AuraComment(
        author: 'MusicLover',
        authorThumbnail: '',
        text: 'Absolute classic!',
        publishedTime: '2 days ago',
        likeCount: 450,
      );

      expect(comment.author, 'MusicLover');
      expect(comment.likeCount, 450);
      expect(comment.text, 'Absolute classic!');
      expect(comment.formattedLikes, '450');
    });
  });

  group('Equalizer Band Info & DSP Audio Shaper', () {
    test('EqualizerBandInfo frequency labels and decibel limits', () {
      const band = EqualizerBandInfo(
        index: 0,
        centerFrequency: 60,
        label: '60 Hz',
        gain: 3.5,
        minDecibels: -12.0,
        maxDecibels: 12.0,
      );

      expect(band.index, 0);
      expect(band.centerFrequency, 60);
      expect(band.label, '60 Hz');
      expect(band.gain, 3.5);
      expect(band.minDecibels, -12.0);
      expect(band.maxDecibels, 12.0);
    });
  });

  group('StorageService Persistence & Local Data', () {
    late StorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = await StorageService.init();
    });

    test('Subscriptions toggle and query', () async {
      final sub = LocalSubscription(
        channelId: 'chan_123',
        name: 'Tech Channel',
        avatarUrl: '',
        subscribedAt: DateTime.now(),
      );

      expect(storage.isSubscribed('chan_123'), false);

      final added = await storage.toggleSubscription(sub);
      expect(added, true);
      expect(storage.isSubscribed('chan_123'), true);
      expect(storage.loadSubscriptions().length, 1);

      final removed = await storage.toggleSubscription(sub);
      expect(removed, false);
      expect(storage.isSubscribed('chan_123'), false);
      expect(storage.loadSubscriptions().length, 0);
    });

    test('Favorites and History persistence', () async {
      final song = Song(
        id: 'fav_1',
        title: 'Favorite Song',
        artist: 'Favorite Artist',
        duration: const Duration(seconds: 200),
        artworkUrl: '',
        streamUrl: 'https://example.com/audio.mp3',
      );

      await storage.saveFavorites([song]);
      final favs = storage.loadFavorites();
      expect(favs.length, 1);
      expect(favs.first.title, 'Favorite Song');

      await storage.saveHistory([song]);
      final hist = storage.loadHistory();
      expect(hist.length, 1);
      expect(hist.first.id, 'fav_1');

      await storage.clearHistory();
      expect(storage.loadHistory().isEmpty, true);
    });

    test('Equalizer preset and bass boost persistence', () async {
      await storage.saveEqualizerEnabled(true);
      expect(storage.loadEqualizerEnabled(), true);

      await storage.saveEqualizerPreset('Bass Boost');
      expect(storage.loadEqualizerPreset(), 'Bass Boost');

      await storage.saveBassBoost(0.85);
      expect(storage.loadBassBoost(), 0.85);
    });
  });

  group('YouTube Feed Service Categories', () {
    test('Categories catalog definition', () {
      final categories = YouTubeFeedService.categories;
      expect(categories.isNotEmpty, true);
      expect(categories.any((c) => c['id'] == 'all'), true);
      expect(categories.any((c) => c['id'] == 'trending'), true);
      expect(categories.any((c) => c['id'] == 'music'), true);
      expect(categories.any((c) => c['id'] == 'gaming'), true);
      expect(categories.any((c) => c['id'] == 'news'), true);
      expect(categories.any((c) => c['id'] == 'tech'), true);
      expect(categories.any((c) => c['id'] == 'entertainment'), true);
    });
  });
}
