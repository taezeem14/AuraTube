import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/youtube_video.dart';
import 'youtube_service.dart';

class DownloadTask {
  final String id;
  final String title;
  final bool isAudioOnly;
  double progress;
  bool isCompleted;
  String? filePath;
  String? error;

  DownloadTask({
    required this.id,
    required this.title,
    required this.isAudioOnly,
    this.progress = 0.0,
    this.isCompleted = false,
    this.filePath,
    this.error,
  });
}

class DownloadService extends ChangeNotifier {
  final Map<String, DownloadTask> _tasks = {};

  Map<String, DownloadTask> get tasks => Map.unmodifiable(_tasks);

  DownloadTask? getTask(String videoId) => _tasks[videoId];

  Future<void> downloadVideo(YouTubeVideo video, {bool audioOnly = false}) async {
    if (_tasks.containsKey(video.id) && !_tasks[video.id]!.isCompleted) {
      return; // Already in progress
    }

    final task = DownloadTask(
      id: video.id,
      title: video.title,
      isAudioOnly: audioOnly,
      progress: 0.05,
    );
    _tasks[video.id] = task;
    notifyListeners();

    try {
      final streams = await YouTubeService.resolveStreams(video.id);
      if (streams == null) {
        throw Exception('Could not fetch stream URL for download');
      }

      final url = audioOnly ? streams.audioUrl : streams.videoUrl;
      final ext = audioOnly ? 'm4a' : 'mp4';

      final dir = await getApplicationDocumentsDirectory();
      final sanitizedTitle = video.title.replaceAll(RegExp(r'[^\w\s\.-]'), '').trim();
      final fileName = '${sanitizedTitle.isNotEmpty ? sanitizedTitle : video.id}.$ext';
      final file = File('${dir.path}/$fileName');

      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);
      final total = response.contentLength ?? 0;
      int received = 0;

      final sink = file.openWrite();
      await response.stream.listen(
        (chunk) {
          received += chunk.length;
          sink.add(chunk);
          if (total > 0) {
            task.progress = (received / total).clamp(0.0, 1.0);
            notifyListeners();
          }
        },
        onDone: () async {
          await sink.close();
          task.isCompleted = true;
          task.filePath = file.path;
          task.progress = 1.0;
          notifyListeners();
        },
        onError: (e) {
          task.error = e.toString();
          notifyListeners();
        },
        cancelOnError: true,
      ).asFuture();
    } catch (e) {
      debugPrint('[DownloadService] Download error: $e');
      task.error = e.toString();
      notifyListeners();
    }
  }
}
