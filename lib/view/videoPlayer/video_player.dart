import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import '../../view_model/video_player_controller/video_controller.dart';
import '../../widgets/ad_widget/app_open_ad_helper.dart';
import '../../widgets/ad_widget/interstitial_ad_helper.dart';

class AdvancedVideoPlayer extends StatefulWidget {
  final String url;
  final String title;
  final String? contentId;

  const AdvancedVideoPlayer({
    super.key,
    required this.url,
    required this.title,
    this.contentId,
  });

  @override
  State<AdvancedVideoPlayer> createState() => _AdvancedVideoPlayerState();
}

class _AdvancedVideoPlayerState extends State<AdvancedVideoPlayer> {
  late final VideoController controller;
  final RxBool isLocked = false.obs;
  final RxString quality = "Auto".obs;

  // 🔥 Har kitne seconds pe mid-roll ad aana chahiye (5 min)
  static const int _adIntervalSeconds = 5 * 60;

  // Kaunse marks pe ad already dikha diya hai (dobara na dikhe)
  final Set<int> _shownAdMarks = {};

  // Seekbar pe marker dikhane ke liye ad marks (video length pata chalte hi set hote hai)
  final RxList<int> _adMarkSeconds = <int>[].obs;

  // 🔥 Seekbar geometry fixed rakhi hai taki marker position exact calculate ho sake
  static const double _thumbRadius = 6;
  static const double _dotSize = 6;
  static const double _seekBarHeight = 30;

  // 🔥 Ek time pe sirf ek hi ad-flow chale (overlap na ho)
  bool _isAdPlaying = false;

  Worker? _positionWorker;
  Worker? _durationWorker;

  @override
  void initState() {
    super.initState();
    controller = Get.put(VideoController());
    controller.initializeVideo(widget.url, contentId: widget.contentId);

    // 🔥 Is screen par App Open Ad kabhi show na ho (sirf Interstitial chalega)
    AppOpenAdHelper.suppressed = true;

    // 🔥 Ad jitni jaldi ho sake preload karo (start ad ke liye ready rahe)
    InterstitialAdHelper.loadAd();

    // 🔥 Video open hote hi Interstitial Ad
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showStartAd();
    });

    // 🔥 Total duration pata chalte hi seekbar ke liye ad marks calculate karo
    _durationWorker = ever(controller.totalDuration, (Duration total) {
      if (total.inSeconds > 0 && _adMarkSeconds.isEmpty) {
        _adMarkSeconds.value = _calculateAdMarks(total.inSeconds);
      }
    });

    // 🔥 Video ki actual position track karke 5-5 min pe ad trigger karo
    _positionWorker = ever(controller.currentPosition, _checkMidRollAd);
  }

  @override
  void dispose() {
    // 🔥 Video player se bahar jaate hi App Open Ad wapas allow karo
    AppOpenAdHelper.suppressed = false;
    _positionWorker?.dispose();
    _durationWorker?.dispose();
    super.dispose();
  }

  /// 🔥 5-5 min ke ad marks nikalo (end ke 10 sec ke andar mark skip karo)
  List<int> _calculateAdMarks(int totalSeconds) {
    final List<int> marks = [];
    int t = _adIntervalSeconds;
    while (t < totalSeconds - 10) {
      marks.add(t);
      t += _adIntervalSeconds;
    }
    return marks;
  }

  /// 🔥 Real video_player plugin ki state se pause karo (wrapper ke Rx flag pe depend nahi)
  void _pauseVideoForAd() {
    final vc = controller.videoPlayerController;
    if (vc != null && vc.value.isInitialized && vc.value.isPlaying) {
      vc.pause();
    }
  }

  /// 🔥 Real video_player plugin ki state se resume karo — sirf tab jab video khatam na hua ho
  void _resumeVideoAfterAd() {
    if (!mounted) return;
    final vc = controller.videoPlayerController;
    if (vc == null || !vc.value.isInitialized) return;

    final bool hasRemainingVideo = vc.value.position < vc.value.duration;

    if (!vc.value.isPlaying && hasRemainingVideo) {
      vc.play();
    }
    // Agar video already khatam ho chuka hai to jabardasti play() call nahi karenge —
    // isi wajah se end ke paas wale ad ke baad video "stuck" dikhta tha.
  }

  /// 🔥 START AD (video khulte hi ek baar)
  void _showStartAd() {
    if (_isAdPlaying) return;
    _isAdPlaying = true;
    _pauseVideoForAd();

    InterstitialAdHelper.showAd(
      onAdClosed: () {
        _isAdPlaying = false;
        _resumeVideoAfterAd();
        // 🔥 Agla ad (back/mid-roll ke liye) turant preload karo
        InterstitialAdHelper.loadAd();
      },
    );
  }

  /// 🔥 Video position 5-min mark cross kare to mid-roll ad
  void _checkMidRollAd(Duration pos) {
    if (_adMarkSeconds.isEmpty || _isAdPlaying) return;
    for (final mark in _adMarkSeconds) {
      if (!_shownAdMarks.contains(mark) && pos.inSeconds >= mark) {
        _shownAdMarks.add(mark);
        _showMidVideoAd();
        break;
      }
    }
  }

  void _showMidVideoAd() {
    if (_isAdPlaying) return;
    _isAdPlaying = true;
    _pauseVideoForAd();

    InterstitialAdHelper.showAd(
      onAdClosed: () {
        _isAdPlaying = false;
        _resumeVideoAfterAd();
        // 🔥 Agla ad turant preload karo
        InterstitialAdHelper.loadAd();
      },
    );
  }

  /// 🔥 Back / manual pause pe bhi ad dikhane ke baad turant reload karo
  void _showAdThen(VoidCallback onAdClosedAction) {
    if (_isAdPlaying) return;
    _isAdPlaying = true;

    InterstitialAdHelper.showAd(
      onAdClosed: () {
        _isAdPlaying = false;
        onAdClosedAction();
        InterstitialAdHelper.loadAd();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        if (!controller.isInitialized.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return GestureDetector(
          onTap: () {
            if (!isLocked.value) {
              controller.toggleControls();
            }
          },
          child: Stack(
            children: [
              /// 🎬 VIDEO
              Center(
                child: AspectRatio(
                  aspectRatio:
                      controller.videoPlayerController!.value.aspectRatio,
                  child: VideoPlayer(controller.videoPlayerController!),
                ),
              ),

              /// 🔒 LOCK BUTTON
              Positioned(
                left: 10,
                top: MediaQuery.of(context).size.height / 2,
                child: Obx(
                  () => IconButton(
                    icon: Icon(
                      isLocked.value ? Icons.lock : Icons.lock_open,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      isLocked.value = !isLocked.value;
                      controller.showControls.value = !isLocked.value;
                    },
                  ),
                ),
              ),

              /// 🎮 CONTROLS
              Obx(
                () => controller.showControls.value && !isLocked.value
                    ? _controls(context)
                    : const SizedBox(),
              ),
            ],
          ),
        );
      }),
    );
  }

  /// 🎮 CONTROLS
  Widget _controls(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          /// 🔝 TOP BAR
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  // 🔥 Back/Close pe Interstitial Ad show karo, phir reload
                  _showAdThen(() => Get.back());
                },
              ),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {
                  final String shareText =
                      "Watching ${widget.title} on RoccoPlay App 🎬🔥\n\n"
                      "Watch here: ${widget.url}";
                  Share.share(shareText);
                },
              ),
            ],
          ),

          /// ▶️ CENTER PLAY
          Expanded(
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    iconSize: 40,
                    icon: const Icon(Icons.replay_10, color: Colors.white),
                    onPressed: controller.seekBackward,
                  ),
                  Obx(
                    () => IconButton(
                      iconSize: 70,
                      icon: Icon(
                        controller.isPlaying.value
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        // 🔥 Pause karne par: pehle video pause, phir ad, phir reload
                        if (controller.isPlaying.value && !_isAdPlaying) {
                          _isAdPlaying = true;
                          controller.togglePlay(); // user ka manual pause
                          InterstitialAdHelper.showAd(
                            onAdClosed: () {
                              _isAdPlaying = false;
                              // ad ke baad video paused hi rahega, user khud play karega
                              InterstitialAdHelper.loadAd();
                            },
                          );
                        } else if (!controller.isPlaying.value) {
                          controller.togglePlay(); // resume/play
                        }
                      },
                    ),
                  ),
                  IconButton(
                    iconSize: 40,
                    icon: const Icon(Icons.forward_10, color: Colors.white),
                    onPressed: controller.seekForward,
                  ),
                ],
              ),
            ),
          ),

          /// ⬇ BOTTOM CONTROLS
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                /// 🔥 SEEK BAR + AD MARKERS (fixed geometry, exact center alignment)
                Obx(() {
                  final total = controller.totalDuration.value.inSeconds;
                  final current = controller.currentPosition.value.inSeconds;
                  final progress = total == 0 ? 0.0 : current / total;

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      // SliderTheme me thumb radius fix kiya hai (6) aur overlay hata di hai,
                      // isliye Slider ka actual usable track width = totalWidth - 2*thumbRadius
                      final double trackWidth =
                          constraints.maxWidth - (_thumbRadius * 2);

                      return SizedBox(
                        height: _seekBarHeight,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: _thumbRadius,
                                ),
                                overlayShape: SliderComponentShape.noOverlay,
                              ),
                              child: Slider(
                                value: progress.clamp(0.0, 1.0),
                                onChanged: controller.seekTo,
                                activeColor: Colors.red,
                                inactiveColor: Colors.white30,
                              ),
                            ),

                            // 🔥 Ad marker dots — seekbar line ke exact center pe
                            if (total > 0 && _adMarkSeconds.isNotEmpty)
                              IgnorePointer(
                                child: Stack(
                                  children: _adMarkSeconds.map((markSec) {
                                    final double relative = markSec / total;
                                    final double left =
                                        _thumbRadius +
                                        (relative * trackWidth) -
                                        (_dotSize / 2);
                                    return Positioned(
                                      left: left,
                                      top: (_seekBarHeight - _dotSize) / 2,
                                      child: Container(
                                        width: _dotSize,
                                        height: _dotSize,
                                        decoration: const BoxDecoration(
                                          color: Colors.amber,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                }),

                /// ⏱ TIME + OPTIONS
                Obx(
                  () => Row(
                    children: [
                      Text(
                        "${_format(controller.currentPosition.value)} / ${_format(controller.totalDuration.value)}",
                        style: const TextStyle(color: Colors.white),
                      ),
                      const Spacer(),

                      /// ⚡ SPEED
                      IconButton(
                        icon: const Icon(Icons.speed, color: Colors.white),
                        onPressed: () => _showSpeedDialog(context),
                      ),

                      /// 🎬 QUALITY
                      IconButton(
                        icon: const Icon(Icons.hd, color: Colors.white),
                        onPressed: () => _showQualityDialog(context),
                      ),

                      /// 🔄 ROTATION
                      IconButton(
                        icon: const Icon(
                          Icons.screen_rotation,
                          color: Colors.white,
                        ),
                        onPressed: () => controller.toggleRotation(
                          MediaQuery.of(context).orientation,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ⏱ FORMAT
  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, "0");
    return "${two(d.inMinutes)}:${two(d.inSeconds % 60)}";
  }

  /// ⚡ SPEED DIALOG
  void _showSpeedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text("Speed"),
        children: [0.5, 1, 1.5, 2].map((e) {
          return SimpleDialogOption(
            onPressed: () {
              controller.setPlaybackSpeed(e.toDouble());
              Navigator.pop(context);
            },
            child: Text("${e}x"),
          );
        }).toList(),
      ),
    );
  }

  /// 🎬 QUALITY DIALOG (UI only)
  void _showQualityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text("Quality"),
        children: ["Auto", "1080p", "720p", "480p", "360", "240"].map((q) {
          return SimpleDialogOption(
            onPressed: () {
              quality.value = q;
              Navigator.pop(context);
            },
            child: Text(q),
          );
        }).toList(),
      ),
    );
  }
}
