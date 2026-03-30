import 'dart:async';
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
  var selectedQuality = "Auto".obs;

  Timer? _hideTimer;

  /// 🔥 Initialize Video
  void initializeVideo(String url) async {
    isInitialized.value = false;

    videoPlayerController =
        VideoPlayerController.networkUrl(Uri.parse(url));

    await videoPlayerController!.initialize();

    isInitialized.value = true;
    totalDuration.value = videoPlayerController!.value.duration;

    videoPlayerController!.play();
    isPlaying.value = true;

    /// Listen position updates
    videoPlayerController!.addListener(() {
      currentPosition.value =
          videoPlayerController!.value.position;
    });

    _startHideTimer();
  }

  /// ▶️ Play / Pause
  void togglePlay() {
    if (videoPlayerController!.value.isPlaying) {
      videoPlayerController!.pause();
      isPlaying.value = false;
    } else {
      videoPlayerController!.play();
      isPlaying.value = true;
      _startHideTimer();
    }
  }

  /// 👆 Show / Hide controls
  void toggleControls() {
    showControls.value = !showControls.value;

    if (showControls.value) {
      _startHideTimer();
    }
  }

  /// ⏱ Auto hide
  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      showControls.value = false;
    });
  }

  /// ⏩ Seek
  void seekTo(Duration position) {
    videoPlayerController?.seekTo(position);
    _startHideTimer();
  }

  /// ⚡ Speed
  void setPlaybackSpeed(double speed) {
    playbackSpeed.value = speed;
    videoPlayerController?.setPlaybackSpeed(speed);
  }

  /// ❌ Dispose
  void disposeVideo() {
    _hideTimer?.cancel();
    videoPlayerController?.dispose();
  }

  @override
  void onClose() {
    disposeVideo();
    super.onClose();
  }
}
