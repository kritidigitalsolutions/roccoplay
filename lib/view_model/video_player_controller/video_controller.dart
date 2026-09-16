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

  // Track last emitted values to throttle reactive updates
  Duration _lastEmittedPosition = Duration.zero;
  bool _lastEmittedPlaying = false;
  Duration _lastEmittedDuration = Duration.zero;

  // Listener callback reference for cleanup
  VoidCallback? _videoListener;

  /// 🔥 INIT
  Future<void> initializeVideo(String url, {String? contentId}) async {
    if (_currentUrl == url && isInitialized.value) return;
    _currentUrl = url;

    isInitialized.value = false;
    _contentId = contentId;

    // Dispose previous controller if exists
    _cleanupOldController();

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
    _lastEmittedDuration = videoPlayerController!.value.duration;

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

    // Reset throttle tracking
    _lastEmittedPosition = videoPlayerController!.value.position;
    _lastEmittedPlaying = true;

    /// 🔥 LISTENER (THROTTLED — only update Rx when values actually change)
    _videoListener = () {
      final c = videoPlayerController;
      if (c == null) return;
      final value = c.value;

      // Only update position if changed by >= 250ms (cuts 60fps → ~4 updates/sec)
      final posDiff = (value.position - _lastEmittedPosition).abs();
      if (posDiff >= const Duration(milliseconds: 250) ||
          value.position == Duration.zero ||
          value.position >= value.duration) {
        _lastEmittedPosition = value.position;
        currentPosition.value = value.position;
      }

      // Only update isPlaying when it actually changes
      if (value.isPlaying != _lastEmittedPlaying) {
        _lastEmittedPlaying = value.isPlaying;
        isPlaying.value = value.isPlaying;
      }

      // Only update duration when it actually changes
      if (value.duration != _lastEmittedDuration) {
        _lastEmittedDuration = value.duration;
        totalDuration.value = value.duration;
      }
    };
    videoPlayerController!.addListener(_videoListener!);

    _startHideTimer();
    _startSaveTimer();
  }

  /// 🧹 Cleanup old controller before re-init
  void _cleanupOldController() {
    _hideTimer?.cancel();
    _saveTimer?.cancel();
    final old = videoPlayerController;
    if (old != null) {
      if (_videoListener != null) {
        old.removeListener(_videoListener!);
      }
      old.dispose();
      videoPlayerController = null;
    }
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

    // Force immediate position update on seek for responsive UI
    currentPosition.value = newPos;
    _lastEmittedPosition = newPos;

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
    final old = videoPlayerController;
    if (old != null) {
      if (_videoListener != null) {
        old.removeListener(_videoListener!);
        _videoListener = null;
      }
      old.dispose();
      videoPlayerController = null;
    }
    // Reset to portrait when leaving
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.onClose();
  }
}
