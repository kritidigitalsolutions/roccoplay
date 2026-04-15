import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:share_plus/share_plus.dart';

class AdvancedVideoPlayer extends StatefulWidget {
  final String url;
  final String title;

  const AdvancedVideoPlayer({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<AdvancedVideoPlayer> createState() =>
      _AdvancedVideoPlayerState();
}

class _AdvancedVideoPlayerState
    extends State<AdvancedVideoPlayer> {
  late VideoPlayerController controller;

  double volume = 0.5;
  double brightness = 0.5;

  bool showControls = true;
  bool isPlaying = true;
  bool isLocked = false;
  bool isExiting = false; // ✅ Added to track exit state

  double speed = 1.0;
  String quality = "Auto";

  @override
  void initState() {
    super.initState();

    controller =
    VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() {});
        controller.play();
      });

    /// 🔥 FULLSCREEN LANDSCAPE
    SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    VolumeController().getVolume().then((v) => volume = v);
    ScreenBrightness().current.then((b) => brightness = b);
  }

  /// 🔥 EXIT PLAYER (CLEAN TRANSITION)
  Future<void> _exitPlayer() async {
    if (isExiting) return;

    setState(() {
      isExiting = true; // ✅ Immediately hide UI with a black screen
      showControls = false;
    });

    // 1. Restore UI to edge-to-edge
    await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge);

    // 2. Force orientation back to Portrait
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // 3. ⏳ WAIT: Give the device 1.5 seconds to finish the physical rotation
    // While waiting, the user only sees a black screen (Scaffold background)
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    
    // Safety fallback
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    super.dispose();
  }

  /// 🎮 Gesture Control
  void _onVerticalDrag(DragUpdateDetails details) async {
    if (isLocked || isExiting) return;

    double delta = details.primaryDelta! / 300;

    if (details.globalPosition.dx <
        MediaQuery.of(context).size.width / 2) {
      brightness -= delta;
      brightness = brightness.clamp(0.0, 1.0);
      await ScreenBrightness().setScreenBrightness(brightness);
    } else {
      volume -= delta;
      volume = volume.clamp(0.0, 1.0);
    }
  }

  /// ⏩ Seek
  void _onHorizontalDrag(DragUpdateDetails details) {
    if (isLocked || isExiting) return;

    final position = controller.value.position;
    final duration = controller.value.duration;

    Duration seekTo =
        position + Duration(seconds: (details.primaryDelta! ~/ 5));

    if (seekTo < Duration.zero) seekTo = Duration.zero;
    if (seekTo > duration) seekTo = duration;

    controller.seekTo(seekTo);
  }

  /// ▶️ Play/Pause
  void _togglePlay() {
    if (isLocked || isExiting) return;

    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
        isPlaying = false;
      } else {
        controller.play();
        isPlaying = true;
      }
    });
  }

  /// ⏱ Format Time
  String format(Duration d) {
    String two(int n) => n.toString().padLeft(2, "0");
    return "${two(d.inMinutes)}:${two(d.inSeconds % 60)}";
  }

  /// ⚡ Speed Dialog
  void _showSpeedDialog() {
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text("Speed"),
        children: [0.5, 1, 1.5, 2].map((e) {
          return SimpleDialogOption(
            onPressed: () {
              setState(() => speed = e.toDouble());
              controller.setPlaybackSpeed(speed);
              Navigator.pop(context);
            },
            child: Text("${e}x"),
          );
        }).toList(),
      ),
    );
  }

  /// ⚙ Quality Dialog
  void _showQualityDialog() {
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text("Quality"),
        children: ["Auto", "1080p", "720p", "480p"].map((q) {
          return SimpleDialogOption(
            onPressed: () {
              setState(() => quality = q);
              Navigator.pop(context);
            },
            child: Text(q),
          );
        }).toList(),
      ),
    );
  }

  /// 🔒 Lock toggle
  void _toggleLock() {
    setState(() {
      isLocked = !isLocked;
      showControls = !isLocked;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        _exitPlayer();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: isExiting 
          ? const Center(child: CircularProgressIndicator(color: Colors.white)) // ✅ Show loader on black background while rotating
          : GestureDetector(
          onTap: () {
            if (!isLocked) {
              setState(() => showControls = !showControls);
            }
          },
          onVerticalDragUpdate: _onVerticalDrag,
          onHorizontalDragUpdate: _onHorizontalDrag,
          child: Stack(
            children: [
              /// 🎬 VIDEO
              Center(
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
              ),

              /// 🔒 LOCK BUTTON
              Positioned(
                left: 10,
                top: MediaQuery.of(context).size.height / 2,
                child: IconButton(
                  icon: Icon(
                    isLocked ? Icons.lock : Icons.lock_open,
                    color: Colors.white,
                  ),
                  onPressed: _toggleLock,
                ),
              ),

              /// 🎮 CONTROLS
              if (showControls && !isLocked)
                Column(
                  children: [
                    /// 🔝 TOP BAR
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white),
                          onPressed: _exitPlayer,
                        ),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                                color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share,
                              color: Colors.white),
                          onPressed: () {
                            Share.share(widget.url);
                          },
                        ),
                      ],
                    ),

                    /// ▶️ CENTER PLAY
                    Expanded(
                      child: Center(
                        child: IconButton(
                          iconSize: 70,
                          icon: Icon(
                            isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                          ),
                          onPressed: _togglePlay,
                        ),
                      ),
                    ),

                    /// ⬇ BOTTOM
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          /// SEEK BAR
                          VideoProgressIndicator(
                            controller,
                            allowScrubbing: true,
                            colors: const VideoProgressColors(
                              playedColor: Colors.red,
                            ),
                          ),

                          const SizedBox(height: 5),

                          /// TIME + OPTIONS
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${format(controller.value.position)} / ${format(controller.value.duration)}",
                                style: const TextStyle(
                                    color: Colors.white),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.subtitles,
                                        color: Colors.white),
                                    onPressed: () {},
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.speed,
                                        color: Colors.white),
                                    onPressed: _showSpeedDialog,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.hd,
                                        color: Colors.white),
                                    onPressed:
                                    _showQualityDialog,
                                  ),
                                ],
                              )
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
