import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:video_player/video_player.dart';

class VideoController extends GetxController {
  VideoPlayerController? videoPlayerController;
  final storage = GetStorage();

  var isInitialized = false.obs;
  var isPlaying = false.obs;
  var showControls = true.obs;

  var currentPosition = Duration.zero.obs;
  var totalDuration = Duration.zero.obs;

  var playbackSpeed = 1.0.obs;
  var isLandscape = false.obs;
  String? _contentId;
  String? _currentUrl;

  Timer? _hideTimer;
  Timer? _saveTimer;

  /// 🔥 INIT
  Future<void> initializeVideo(String url, {String? contentId}) async {
    if (_currentUrl == url && isInitialized.value) return;
    _currentUrl = url;

    isInitialized.value = false;
    _contentId = contentId;

    // Allow all orientations when video starts
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url));

    await videoPlayerController!.initialize();

    isInitialized.value = true;
    totalDuration.value = videoPlayerController!.value.duration;

    // Resume logic
    if (_contentId != null) {
      int? savedSeconds = storage.read<int>('resume_pos_$_contentId');
      if (savedSeconds != null && savedSeconds > 0) {
        // Don't resume if it's at the very end (e.g., last 5 seconds)
        if (savedSeconds < totalDuration.value.inSeconds - 5) {
          await videoPlayerController!.seekTo(Duration(seconds: savedSeconds));
        }
      }
    }

    videoPlayerController!.play();

    /// 🔥 LISTENER (REAL-TIME UPDATE)
    videoPlayerController!.addListener(() {
      final value = videoPlayerController!.value;

      currentPosition.value = value.position;
      isPlaying.value = value.isPlaying;

      totalDuration.value = value.duration;
    });

    _startHideTimer();
    _startSaveTimer();
  }

  /// 💾 SAVE POSITION
  void _savePosition() {
    if (_contentId != null && videoPlayerController != null) {
      final pos = videoPlayerController!.value.position.inSeconds;
      storage.write('resume_pos_$_contentId', pos);
    }
  }

  void _startSaveTimer() {
    _saveTimer?.cancel();
    _saveTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _savePosition();
    });
  }

  /// ▶️ PLAY / PAUSE
  void togglePlay() {
    final c = videoPlayerController;
    if (c == null) return;

    if (c.value.isPlaying) {
      c.pause();
      _savePosition();
    } else {
      c.play();
      _startHideTimer();
    }
  }

  /// 👆 CONTROLS
  void toggleControls() {
    showControls.value = !showControls.value;

    if (showControls.value) {
      _startHideTimer();
    }
  }

  /// ⏱ AUTO HIDE
  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      showControls.value = false;
    });
  }

  /// ⏩ SEEK
  void seekTo(double value) {
    final c = videoPlayerController;
    if (c == null) return;

    final duration = c.value.duration;
    if (duration.inSeconds == 0) return;

    final newPos = Duration(seconds: (duration.inSeconds * value).toInt());

    c.seekTo(newPos);
    _startHideTimer();
  }

  void seekForward() {
    final c = videoPlayerController;
    if (c == null) return;
    final newPos = c.value.position + const Duration(seconds: 10);
    if (newPos > c.value.duration) {
      c.seekTo(c.value.duration);
    } else {
      c.seekTo(newPos);
    }
    _startHideTimer();
  }

  void seekBackward() {
    final c = videoPlayerController;
    if (c == null) return;
    final newPos = c.value.position - const Duration(seconds: 10);
    if (newPos < Duration.zero) {
      c.seekTo(Duration.zero);
    } else {
      c.seekTo(newPos);
    }
    _startHideTimer();
  }

  void toggleRotation(Orientation currentOrientation) {
    if (currentOrientation == Orientation.landscape) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      isLandscape.value = false;
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      isLandscape.value = true;
    }
  }

  /// ⚡ SPEED
  void setPlaybackSpeed(double speed) {
    playbackSpeed.value = speed;
    videoPlayerController?.setPlaybackSpeed(speed);
  }

  /// ❌ DISPOSE
  @override
  void onClose() {
    _savePosition();
    _hideTimer?.cancel();
    _saveTimer?.cancel();
    videoPlayerController?.dispose();
    // Reset to portrait when leaving
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.onClose();
  }
}
