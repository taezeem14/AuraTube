import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../models/subscription.dart';

class StorageService {
  static const String _favsKey = 'sine_favorites_v1';
  static const String _favsLegacyKey = 'ember_favorites_v1';
  static const String _histKey = 'sine_history_v1';
  static const String _histLegacyKey = 'ember_history_v1';
  static const String _speedKey = 'sine_playback_speed';
  static const String _speedLegacyKey = 'ember_playback_speed';
  static const String _playlistsKey = 'sine_playlists_v1';
  static const String _playlistsLegacyKey = 'ember_playlists_v1';
  static const String _downloadsKey = 'sine_downloads_v1';
  static const String _downloadsLegacyKey = 'ember_downloads_v1';
  static const String _eqPresetKey = 'sine_eq_preset';
  static const String _eqPresetLegacyKey = 'ember_eq_preset';
  static const String _eqEnabledKey = 'sine_eq_enabled';
  static const String _eqEnabledLegacyKey = 'ember_eq_enabled';
  static const String _eqBassBoostKey = 'sine_eq_bass_boost';
  static const String _eqBassBoostLegacyKey = 'ember_eq_bass_boost';
  static const String _eqBandGainsKey = 'sine_eq_band_gains';
  static const String _eqBandGainsLegacyKey = 'ember_eq_band_gains';
  static const String _repeatModeKey = 'sine_repeat_mode';
  static const String _repeatModeLegacyKey = 'pulsepipe_repeat_mode';
  static const String _shuffleKey = 'sine_shuffle';
  static const String _shuffleLegacyKey = 'pulsepipe_shuffle';

  static const String _autoplayKey = 'sine_autoplay_smart_radio';
  static const String _autoplayLegacyKey = 'pulsepipe_autoplay_smart_radio';

  static const String _searchesKey = 'sine_recent_searches_v1';
  static const String _searchesLegacyKey = 'ember_recent_searches_v1';
  static const String _subsKey = 'auratube_subscriptions_v1';

  final SharedPreferences? _prefs;
  final List<Song> _memFavorites = [];
  final List<Song> _memHistory = [];
  final List<Playlist> _memPlaylists = [];
  final List<Song> _memDownloads = [];
  final List<String> _memSearches = [];
  final List<LocalSubscription> _memSubscriptions = [];
  double _memSpeed = 1.0;

  static String? _safeJsonEncode(Map<String, dynamic> map) {
    try {
      return jsonEncode(map);
    } catch (e) {
      return null;
    }
  }

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('[StorageService] SharedPreferences.getInstance failed: $e');
    }

    final service = StorageService(prefs);
    try {
      await service.purgeAllPlaceholders();
    } catch (e) {
      debugPrint('[StorageService] Error purging placeholders (non-fatal): $e');
    }
    return service;
  }

  /// Purges all legacy mock / placeholder songs from all storage keys permanently
  Future<void> purgeAllPlaceholders() async {
    final favs = loadFavorites();
    await saveFavorites(favs);

    final hist = loadHistory();
    await saveHistory(hist);

    final pl = loadPlaylists();
    await savePlaylists(pl);

    final dl = loadDownloads();
    await saveDownloads(dl);
  }

  List<Song> loadFavorites() {
    if (_prefs == null) {
      return List<Song>.from(_memFavorites.where((s) => !Song.isPlaceholder(s)));
    }
    final raw = _prefs.getStringList(_favsKey) ?? _prefs.getStringList(_favsLegacyKey) ?? [];
    final cleaned = <Song>[];
    bool hadPlaceholders = false;

    for (final s in raw) {
      try {
        final decoded = jsonDecode(s);
        if (decoded is! Map) continue;
        final song = Song.fromMap(Map<String, dynamic>.from(decoded));
        if (Song.isPlaceholder(song)) {
          hadPlaceholders = true;
        } else {
          cleaned.add(song);
        }
      } catch (e) {
        debugPrint('[StorageService] Skipped corrupt favorite entry: $e');
      }
    }

    _memFavorites.clear();
    _memFavorites.addAll(cleaned);

    if (hadPlaceholders) {
      final encoded = cleaned.map((s) => _safeJsonEncode(s.toMap())).whereType<String>().toList();
      _prefs.setStringList(_favsKey, encoded);
    }

    return cleaned;
  }

  Future<void> saveFavorites(List<Song> songs) async {
    final cleaned = songs.where((s) => !Song.isPlaceholder(s)).toList();
    _memFavorites.clear();
    _memFavorites.addAll(cleaned);
    if (_prefs != null) {
      final encoded = cleaned.map((s) => _safeJsonEncode(s.toMap())).whereType<String>().toList();
      await _prefs.setStringList(_favsKey, encoded);
    }
  }

  List<Song> loadHistory() {
    if (_prefs == null) {
      return List<Song>.from(_memHistory.where((s) => !Song.isPlaceholder(s)));
    }
    final raw = _prefs.getStringList(_histKey) ?? _prefs.getStringList(_histLegacyKey) ?? [];
    final cleaned = <Song>[];
    bool hadPlaceholders = false;

    for (final s in raw) {
      try {
        final decoded = jsonDecode(s);
        if (decoded is! Map) continue;
        final song = Song.fromMap(Map<String, dynamic>.from(decoded));
        if (Song.isPlaceholder(song)) {
          hadPlaceholders = true;
        } else {
          cleaned.add(song);
        }
      } catch (e) {
        debugPrint('[StorageService] Skipped corrupt history entry: $e');
      }
    }

    _memHistory.clear();
    _memHistory.addAll(cleaned);

    if (hadPlaceholders) {
      final encoded = cleaned.map((s) => _safeJsonEncode(s.toMap())).whereType<String>().toList();
      _prefs.setStringList(_histKey, encoded);
    }

    return cleaned;
  }

  Future<void> saveHistory(List<Song> songs) async {
    final cleaned = songs.where((s) => !Song.isPlaceholder(s)).take(200).toList();
    _memHistory.clear();
    _memHistory.addAll(cleaned);
    if (_prefs != null) {
      final encoded = cleaned.map((s) => _safeJsonEncode(s.toMap())).whereType<String>().toList();
      await _prefs.setStringList(_histKey, encoded);
    }
  }

  Future<void> clearHistory() async {
    _memHistory.clear();
    if (_prefs != null) {
      await _prefs.remove(_histKey);
    }
  }

  List<Playlist> loadPlaylists() {
    if (_prefs == null) {
      return List<Playlist>.from(_memPlaylists);
    }
    final raw = _prefs.getStringList(_playlistsKey) ?? _prefs.getStringList(_playlistsLegacyKey) ?? [];
    final list = <Playlist>[];
    for (final s in raw) {
      try {
        final decoded = jsonDecode(s);
        if (decoded is! Map) continue;
        final pl = Playlist.fromMap(Map<String, dynamic>.from(decoded));
        final sanitizedSongs = pl.songs.where((song) => !Song.isPlaceholder(song)).toList();
        list.add(pl.copyWith(songs: sanitizedSongs));
      } catch (_) {}
    }

    _memPlaylists.clear();
    _memPlaylists.addAll(list);

    return list;
  }

  Future<void> savePlaylists(List<Playlist> playlists) async {
    _memPlaylists.clear();
    _memPlaylists.addAll(playlists);
    if (_prefs != null) {
      final encoded = playlists.map((p) => _safeJsonEncode(p.toMap())).whereType<String>().toList();
      await _prefs.setStringList(_playlistsKey, encoded);
    }
  }

  Future<void> savePlaylist(Playlist playlist) async {
    final list = List<Playlist>.from(loadPlaylists());
    final idx = list.indexWhere((p) => p.id == playlist.id);
    if (idx != -1) {
      list[idx] = playlist;
    } else {
      list.insert(0, playlist);
    }
    await savePlaylists(list);
  }

  Future<void> deletePlaylist(String playlistId) async {
    final list = List<Playlist>.from(loadPlaylists());
    list.removeWhere((p) => p.id == playlistId);
    await savePlaylists(list);
  }

  Future<void> addSongToPlaylist(String playlistId, Song song) async {
    if (Song.isPlaceholder(song)) return;
    final list = List<Playlist>.from(loadPlaylists());
    final idx = list.indexWhere((p) => p.id == playlistId);
    if (idx != -1) {
      final existing = list[idx];
      if (!existing.songs.any((s) => s.id == song.id)) {
        final updatedSongs = List<Song>.from(existing.songs)..add(song);
        final updated = existing.copyWith(
          songs: updatedSongs,
          coverUrl: existing.coverUrl?.isNotEmpty == true
              ? existing.coverUrl
              : (song.artworkUrl.isNotEmpty ? song.artworkUrl : null),
        );
        list[idx] = updated;
        await savePlaylists(list);
      }
    }
  }

  List<Song> loadDownloads() {
    if (_prefs == null) {
      return List<Song>.from(_memDownloads.where((s) => !Song.isPlaceholder(s)));
    }
    final raw = _prefs.getStringList(_downloadsKey) ?? _prefs.getStringList(_downloadsLegacyKey) ?? [];
    final cleaned = <Song>[];
    bool hadPlaceholders = false;

    for (final s in raw) {
      try {
        final decoded = jsonDecode(s);
        if (decoded is! Map) continue;
        final song = Song.fromMap(Map<String, dynamic>.from(decoded));
        if (Song.isPlaceholder(song)) {
          hadPlaceholders = true;
        } else {
          cleaned.add(song);
        }
      } catch (e) {
        debugPrint('[StorageService] Skipped corrupt download entry: $e');
      }
    }

    _memDownloads.clear();
    _memDownloads.addAll(cleaned);

    if (hadPlaceholders) {
      final encoded = cleaned.map((s) => _safeJsonEncode(s.toMap())).whereType<String>().toList();
      _prefs.setStringList(_downloadsKey, encoded);
    }

    return cleaned;
  }

  Future<void> saveDownloads(List<Song> songs) async {
    final cleaned = songs.where((s) => !Song.isPlaceholder(s)).toList();
    _memDownloads.clear();
    _memDownloads.addAll(cleaned);
    if (_prefs != null) {
      final encoded = cleaned.map((s) => _safeJsonEncode(s.toMap())).whereType<String>().toList();
      await _prefs.setStringList(_downloadsKey, encoded);
    }
  }

  String loadRepeatMode() {
    return _prefs?.getString(_repeatModeKey) ?? _prefs?.getString(_repeatModeLegacyKey) ?? 'off';
  }

  Future<void> saveRepeatMode(String mode) async {
    await _prefs?.setString(_repeatModeKey, mode);
  }

  bool loadShuffle() {
    return _prefs?.getBool(_shuffleKey) ?? _prefs?.getBool(_shuffleLegacyKey) ?? false;
  }

  Future<void> saveShuffle(bool shuffle) async {
    await _prefs?.setBool(_shuffleKey, shuffle);
  }

  double loadPlaybackSpeed() {
    return _prefs?.getDouble(_speedKey) ?? _prefs?.getDouble(_speedLegacyKey) ?? _memSpeed;
  }

  Future<void> savePlaybackSpeed(double speed) async {
    _memSpeed = speed;
    await _prefs?.setDouble(_speedKey, speed);
  }

  String loadEqualizerPreset() {
    return _prefs?.getString(_eqPresetKey) ?? _prefs?.getString(_eqPresetLegacyKey) ?? 'Flat';
  }

  Future<void> saveEqualizerPreset(String preset) async {
    await _prefs?.setString(_eqPresetKey, preset);
  }

  bool loadEqualizerEnabled() {
    return _prefs?.getBool(_eqEnabledKey) ?? _prefs?.getBool(_eqEnabledLegacyKey) ?? false;
  }

  Future<void> saveEqualizerEnabled(bool enabled) async {
    await _prefs?.setBool(_eqEnabledKey, enabled);
  }

  double loadBassBoost() {
    return _prefs?.getDouble(_eqBassBoostKey) ?? _prefs?.getDouble(_eqBassBoostLegacyKey) ?? 0.0;
  }

  Future<void> saveBassBoost(double gain) async {
    await _prefs?.setDouble(_eqBassBoostKey, gain);
  }

  bool loadAutoplayEnabled() {
    return _prefs?.getBool(_autoplayKey) ?? _prefs?.getBool(_autoplayLegacyKey) ?? true;
  }

  Future<void> saveAutoplayEnabled(bool enabled) async {
    await _prefs?.setBool(_autoplayKey, enabled);
  }

    Map<int, double> loadBandGains() {
    final raw = _prefs?.getString(_eqBandGainsKey) ?? _prefs?.getString(_eqBandGainsLegacyKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final result = <int, double>{};
        for (final entry in decoded.entries) {
          final k = int.tryParse(entry.key.toString());
          final v = (entry.value as num?)?.toDouble();
          if (k != null && v != null) {
            result[k] = v;
          }
        }
        return result;
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  Future<void> saveBandGains(Map<int, double> gains) async {
    final stringMap = gains.map((k, v) => MapEntry(k.toString(), v));
    await _prefs?.setString(_eqBandGainsKey, jsonEncode(stringMap));
  }

  List<String> loadRecentSearches() {
    if (_prefs == null) {
      return List<String>.from(_memSearches);
    }
    final raw = _prefs.getStringList(_searchesKey) ?? _prefs.getStringList(_searchesLegacyKey) ?? [];
    final cleaned = raw
        .where((s) => s.trim().isNotEmpty && s != 'null')
        .map((s) => s.trim())
        .toSet()
        .toList();
    _memSearches.clear();
    _memSearches.addAll(cleaned);
    return cleaned;
  }

  Future<void> saveRecentSearches(List<String> searches) async {
    final cleaned = searches
        .where((s) => s.trim().isNotEmpty && s != 'null')
        .map((s) => s.trim())
        .take(40)
        .toList();
    _memSearches.clear();
    _memSearches.addAll(cleaned);
    await _prefs?.setStringList(_searchesKey, cleaned);
  }

  Future<void> addRecentSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;
    final current = loadRecentSearches();
    current.removeWhere((q) => q.toLowerCase() == clean.toLowerCase());
    current.insert(0, clean);
    await saveRecentSearches(current);
  }

  Future<void> clearRecentSearches() async {
    _memSearches.clear();
    await _prefs?.remove(_searchesKey);
  }

  // Local YouTube Channel Subscriptions (NewPipe Architecture)
  List<LocalSubscription> loadSubscriptions() {
    if (_prefs == null) {
      return List<LocalSubscription>.from(_memSubscriptions);
    }
    final raw = _prefs.getStringList(_subsKey) ?? [];
    final list = <LocalSubscription>[];
    for (final s in raw) {
      try {
        final decoded = jsonDecode(s);
        if (decoded is Map<String, dynamic>) {
          list.add(LocalSubscription.fromJson(decoded));
        }
      } catch (_) {}
    }
    _memSubscriptions.clear();
    _memSubscriptions.addAll(list);
    return list;
  }

  Future<void> saveSubscriptions(List<LocalSubscription> subs) async {
    _memSubscriptions.clear();
    _memSubscriptions.addAll(subs);
    if (_prefs == null) return;
    final encoded = subs.map((s) => jsonEncode(s.toJson())).toList();
    await _prefs.setStringList(_subsKey, encoded);
  }

  bool isSubscribed(String channelId) {
    if (channelId.trim().isEmpty) return false;
    final list = loadSubscriptions();
    return list.any((s) => s.channelId == channelId.trim());
  }

  Future<bool> toggleSubscription(LocalSubscription sub) async {
    final list = loadSubscriptions();
    final idx = list.indexWhere((s) => s.channelId == sub.channelId);
    bool isNowSubscribed = false;
    if (idx >= 0) {
      list.removeAt(idx);
      isNowSubscribed = false;
    } else {
      list.insert(0, sub);
      isNowSubscribed = true;
    }
    await saveSubscriptions(list);
    return isNowSubscribed;
  }

  // =========================================================================
  // Audio DSP, Metrolist Playback & Hardware Gestures Preferences
  // =========================================================================
  static const String _pitchKey = 'auratube_pitch_v1';
  static const String _skipSilenceKey = 'auratube_skip_silence_v1';
  static const String _loudnessNormKey = 'auratube_loudness_norm_v1';
  static const String _clippingProtKey = 'auratube_clipping_prot_v1';
  static const String _lyricsOffsetKey = 'auratube_lyrics_offset_v1';
  static const String _shakeSkipKey = 'auratube_shake_skip_v1';
  static const String _flipPauseKey = 'auratube_flip_pause_v1';

  double loadPitch() => _prefs?.getDouble(_pitchKey) ?? 1.0;
  Future<void> savePitch(double v) async => await _prefs?.setDouble(_pitchKey, v);

  bool loadSkipSilence() => _prefs?.getBool(_skipSilenceKey) ?? false;
  Future<void> saveSkipSilence(bool v) async => await _prefs?.setBool(_skipSilenceKey, v);

  bool loadLoudnessNormalization() => _prefs?.getBool(_loudnessNormKey) ?? false;
  Future<void> saveLoudnessNormalization(bool v) async => await _prefs?.setBool(_loudnessNormKey, v);

  bool loadClippingProtection() => _prefs?.getBool(_clippingProtKey) ?? true;
  Future<void> saveClippingProtection(bool v) async => await _prefs?.setBool(_clippingProtKey, v);

  double loadLyricsOffset() => _prefs?.getDouble(_lyricsOffsetKey) ?? 0.0;
  Future<void> saveLyricsOffset(double v) async => await _prefs?.setDouble(_lyricsOffsetKey, v);

  bool loadShakeToSkip() => _prefs?.getBool(_shakeSkipKey) ?? false;
  Future<void> saveShakeToSkip(bool v) async => await _prefs?.setBool(_shakeSkipKey, v);

  bool loadFlipToPause() => _prefs?.getBool(_flipPauseKey) ?? false;
  Future<void> saveFlipToPause(bool v) async => await _prefs?.setBool(_flipPauseKey, v);

  // =========================================================================
  // SponsorBlock Preferences & Skip Statistics
  // =========================================================================
  static const String _sbEnabledKey = 'auratube_sb_enabled_v1';
  static const String _sbCatsKey = 'auratube_sb_categories_v1';
  static const String _sbSkippedCountKey = 'auratube_sb_skipped_count_v1';
  static const String _sbSecondsSavedKey = 'auratube_sb_seconds_saved_v1';

  bool loadSponsorBlockEnabled() => _prefs?.getBool(_sbEnabledKey) ?? true;
  Future<void> saveSponsorBlockEnabled(bool v) async => await _prefs?.setBool(_sbEnabledKey, v);

  Set<String> loadSponsorBlockCategories() {
    final list = _prefs?.getStringList(_sbCatsKey);
    if (list == null) {
      return {'sponsor', 'selfpromo', 'intro', 'outro', 'interaction', 'music_offtopic'};
    }
    return list.toSet();
  }

  Future<void> saveSponsorBlockCategories(Set<String> cats) async {
    await _prefs?.setStringList(_sbCatsKey, cats.toList());
  }

  int loadSponsorSegmentsSkipped() => _prefs?.getInt(_sbSkippedCountKey) ?? 0;
  Future<void> saveSponsorSegmentsSkipped(int v) async => await _prefs?.setInt(_sbSkippedCountKey, v);

  double loadSponsorSecondsSaved() => _prefs?.getDouble(_sbSecondsSavedKey) ?? 0.0;
  Future<void> saveSponsorSecondsSaved(double v) async => await _prefs?.setDouble(_sbSecondsSavedKey, v);

  // =========================================================================
  // Audile Recognition History
  // =========================================================================
  static const String _recogHistoryKey = 'auratube_recognition_history_v1';

  List<Map<String, dynamic>> loadRecognitionHistory() {
    final raw = _prefs?.getStringList(_recogHistoryKey) ?? [];
    final out = <Map<String, dynamic>>[];
    for (final s in raw) {
      try {
        final m = jsonDecode(s);
        if (m is Map<String, dynamic>) out.add(m);
      } catch (_) {}
    }
    return out;
  }

  Future<void> saveRecognitionHistory(List<Map<String, dynamic>> records) async {
    final encoded = records.take(100).map((m) => jsonEncode(m)).toList();
    await _prefs?.setStringList(_recogHistoryKey, encoded);
  }

  // =========================================================================
  // Metrolist Listening Insights & Play Telemetry
  // =========================================================================
  static const String _listenSecsKey = 'auratube_listen_secs_v1';
  static const String _playCountsKey = 'auratube_play_counts_v1';
  static const String _artistCountsKey = 'auratube_artist_counts_v1';

  int loadTotalListeningSeconds() => _prefs?.getInt(_listenSecsKey) ?? 0;
  Future<void> saveTotalListeningSeconds(int secs) async => await _prefs?.setInt(_listenSecsKey, secs);

  Map<String, int> loadPlayCounts() {
    final raw = _prefs?.getString(_playCountsKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0));
      }
    } catch (_) {}
    return {};
  }

  Future<void> savePlayCounts(Map<String, int> counts) async {
    await _prefs?.setString(_playCountsKey, jsonEncode(counts));
  }

  Map<String, int> loadArtistPlayCounts() {
    final raw = _prefs?.getString(_artistCountsKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0));
      }
    } catch (_) {}
    return {};
  }

  Future<void> saveArtistPlayCounts(Map<String, int> counts) async {
    await _prefs?.setString(_artistCountsKey, jsonEncode(counts));
  }

  // =========================================================================
  // Full JSON Backup & Restore (Audile / Metrolist / NewPipe Standard)
  // =========================================================================
  String exportFullBackupJson() {
    final payload = {
      'app': 'AuraTube',
      'schemaVersion': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'favorites': loadFavorites().map((s) => s.toMap()).toList(),
      'history': loadHistory().map((s) => s.toMap()).toList(),
      'playlists': loadPlaylists().map((p) => p.toMap()).toList(),
      'subscriptions': loadSubscriptions().map((s) => s.toJson()).toList(),
      'recognitionHistory': loadRecognitionHistory(),
      'settings': {
        'eqEnabled': loadEqualizerEnabled(),
        'eqPreset': loadEqualizerPreset(),
        'bassBoost': loadBassBoost(),
        'pitch': loadPitch(),
        'skipSilence': loadSkipSilence(),
        'loudnessNormalization': loadLoudnessNormalization(),
        'clippingProtection': loadClippingProtection(),
        'lyricsOffset': loadLyricsOffset(),
        'sponsorBlockEnabled': loadSponsorBlockEnabled(),
        'sponsorBlockCategories': loadSponsorBlockCategories().toList(),
      },
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<bool> importFullBackupJson(String rawJson) async {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) return false;

      if (decoded['favorites'] is List) {
        final favs = (decoded['favorites'] as List)
            .whereType<Map>()
            .map((m) => Song.fromMap(Map<String, dynamic>.from(m)))
            .toList();
        await saveFavorites(favs);
      }
      if (decoded['history'] is List) {
        final hist = (decoded['history'] as List)
            .whereType<Map>()
            .map((m) => Song.fromMap(Map<String, dynamic>.from(m)))
            .toList();
        await saveHistory(hist);
      }
      if (decoded['playlists'] is List) {
        final pls = (decoded['playlists'] as List)
            .whereType<Map>()
            .map((m) => Playlist.fromMap(Map<String, dynamic>.from(m)))
            .toList();
        await savePlaylists(pls);
      }
      if (decoded['subscriptions'] is List) {
        final subs = (decoded['subscriptions'] as List)
            .whereType<Map>()
            .map((m) => LocalSubscription.fromJson(Map<String, dynamic>.from(m)))
            .toList();
        await saveSubscriptions(subs);
      }
      if (decoded['recognitionHistory'] is List) {
        final recs = (decoded['recognitionHistory'] as List)
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
        await saveRecognitionHistory(recs);
      }
      if (decoded['settings'] is Map) {
        final s = Map<String, dynamic>.from(decoded['settings'] as Map);
        if (s['eqEnabled'] is bool) await saveEqualizerEnabled(s['eqEnabled'] as bool);
        if (s['eqPreset'] is String) await saveEqualizerPreset(s['eqPreset'] as String);
        if (s['bassBoost'] is num) await saveBassBoost((s['bassBoost'] as num).toDouble());
        if (s['pitch'] is num) await savePitch((s['pitch'] as num).toDouble());
        if (s['skipSilence'] is bool) await saveSkipSilence(s['skipSilence'] as bool);
        if (s['loudnessNormalization'] is bool) {
          await saveLoudnessNormalization(s['loudnessNormalization'] as bool);
        }
        if (s['clippingProtection'] is bool) await saveClippingProtection(s['clippingProtection'] as bool);
        if (s['lyricsOffset'] is num) await saveLyricsOffset((s['lyricsOffset'] as num).toDouble());
        if (s['sponsorBlockEnabled'] is bool) {
          await saveSponsorBlockEnabled(s['sponsorBlockEnabled'] as bool);
        }
        if (s['sponsorBlockCategories'] is List) {
          await saveSponsorBlockCategories(
            (s['sponsorBlockCategories'] as List).map((e) => e.toString()).toSet(),
          );
        }
      }
      return true;
    } catch (e) {
      debugPrint('[StorageService] importFullBackupJson error: $e');
      return false;
    }
  }
}
