import 'dart:async';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class VideoController extends GetxController {
  VideoPlayerController? videoPlayerController;

  var isInitialized = false.obs;
  var isPlaying = false.obs;
  var showControls = true.obs;

  var currentPosition = Duration.zero.obs;
  var totalDuration = Duration.zero.obs;

  var playbackSpeed = 1.0.obs;
  var isLandscape = false.obs;

  Timer? _hideTimer;

  /// 🔥 INIT
  Future<void> initializeVideo(String url) async {
    isInitialized.value = false;

    // Allow all orientations when video starts
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    videoPlayerController =
        VideoPlayerController.networkUrl(Uri.parse(url));

    await videoPlayerController!.initialize();

    isInitialized.value = true;
    totalDuration.value =
        videoPlayerController!.value.duration;

    videoPlayerController!.play();

    /// 🔥 LISTENER (REAL-TIME UPDATE)
    videoPlayerController!.addListener(() {
      final value = videoPlayerController!.value;

      currentPosition.value = value.position;
      isPlaying.value = value.isPlaying;

      if (value.duration != null) {
        totalDuration.value = value.duration;
      }
    });

    _startHideTimer();
  }

  /// ▶️ PLAY / PAUSE
  void togglePlay() {
    final c = videoPlayerController;
    if (c == null) return;

    if (c.value.isPlaying) {
      c.pause();
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

    final newPos = Duration(
      seconds: (duration.inSeconds * value).toInt(),
    );

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

  void toggleRotation() {
    if (isLandscape.value) {
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
    _hideTimer?.cancel();
    videoPlayerController?.dispose();
    // Reset to portrait when leaving
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.onClose();
  }
}
