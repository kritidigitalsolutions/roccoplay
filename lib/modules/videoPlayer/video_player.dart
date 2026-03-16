/// video plyer working with back button but first show in landscape


import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/theme/app_colors.dart';

class PremiumVideoPlayerPage extends StatefulWidget {
  final String videoUrl;
  final String title;

  const PremiumVideoPlayerPage({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  @override
  State<PremiumVideoPlayerPage> createState() =>
      _PremiumVideoPlayerPageState();
}

class _PremiumVideoPlayerPageState extends State<PremiumVideoPlayerPage> {
  late VideoPlayerController _controller;

  bool _showControls = true;
  bool _isLocked = false;
  Timer? _hideTimer;

  double _brightness = 0.5;
  double _volume = 0.5;

  double _playbackSpeed = 1.0;
  String _selectedSubtitle = "Off";
  String _selectedQuality = "720p";

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _controller = VideoPlayerController.asset(widget.videoUrl);
    _controller.initialize().then((_) {
      setState(() {});
      _controller.play();
      _startHideTimer();
    });

    VolumeController().showSystemUI = false;
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (!_isLocked) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    if (_isLocked) return;
    setState(() => _showControls = !_showControls);
    if (_showControls) _startHideTimer();
  }

  void _handleVerticalDrag(DragUpdateDetails details) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final dx = details.globalPosition.dx;

    if (dx < screenWidth / 2) {
      _brightness -= details.delta.dy * 0.005;
      _brightness = _brightness.clamp(0.0, 1.0);
      await ScreenBrightness().setScreenBrightness(_brightness);
    } else {
      _volume -= details.delta.dy * 0.005;
      _volume = _volume.clamp(0.0, 1.0);
      VolumeController().setVolume(_volume);
    }
  }

  void _shareVideo() {
    Share.share(widget.videoUrl);
  }

  void _changeSpeed() async {
    final result = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: Colors.black,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [0.5, 1.0, 1.5, 2.0]
            .map((speed) => ListTile(
          title: Text("${speed}x",
              style: const TextStyle(color: Colors.white)),
          onTap: () => Navigator.pop(context, speed),
        ))
            .toList(),
      ),
    );

    if (result != null) {
      setState(() => _playbackSpeed = result);
      _controller.setPlaybackSpeed(result);
    }
  }

  void _changeSubtitle() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.black,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: ["Off", "English"]
            .map((lang) => ListTile(
          title: Text(lang,
              style: const TextStyle(color: Colors.white)),
          onTap: () => Navigator.pop(context, lang),
        ))
            .toList(),
      ),
    );

    if (result != null) {
      setState(() => _selectedSubtitle = result);
    }
  }

  void _changeQuality() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.black,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: ["360p", "720p", "1080p"]
            .map((q) => ListTile(
          title: Text(q,
              style: const TextStyle(color: Colors.white)),
          onTap: () => Navigator.pop(context, q),
        ))
            .toList(),
      ),
    );

    if (result != null) {
      setState(() => _selectedQuality = result);
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    super.dispose();
  }

  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: true,
        onPopInvoked: (didPop) async {

          if (didPop) return;

          await SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
          ]);

          await Future.delayed(const Duration(milliseconds: 200));

          if (mounted) {
            Navigator.pop(context);
          }
        },
        child:  Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [

          /// VIDEO
          Center(
            child: _controller.value.isInitialized
                ? AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            )
                : const Center(
              child: CircularProgressIndicator(
                color: AppColors.buttonColor,
              ),
            ),
          ),

          /// TAP + GESTURE LAYER
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _toggleControls,
              onVerticalDragUpdate: _handleVerticalDrag,
            ),
          ),

          if (_showControls) ...[

            /// TOP BAR
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () async {

                      /// first change orientation
                      await SystemChrome.setPreferredOrientations([
                        DeviceOrientation.portraitUp,
                      ]);

                      /// small delay so UI rebuilds correctly
                      await Future.delayed(const Duration(milliseconds: 200));

                      /// then go back
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                  ),

                  Text(widget.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18)),
                  Row(
                    children: [
                      IconButton(
                          onPressed: () {
                            setState(() {
                              _isLocked = !_isLocked;
                            });
                          },
                          icon: Icon(
                              _isLocked
                                  ? Icons.lock
                                  : Icons.lock_open,
                              color: Colors.white)),
                      IconButton(
                          onPressed: _shareVideo,
                          icon: const Icon(Icons.share,
                              color: Colors.white)),
                    ],
                  )
                ],
              ),
            ),

            /// CENTER CONTROLS
            if (!_isLocked)
              Center(
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    IconButton(
                      iconSize: 40,
                      onPressed: () {
                        _controller.seekTo(
                            _controller.value.position -
                                const Duration(seconds: 10));
                      },
                      icon: const Icon(Icons.replay_10,
                          color: Colors.white),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      iconSize: 60,
                      onPressed: () {
                        setState(() {
                          _controller.value.isPlaying
                              ? _controller.pause()
                              : _controller.play();
                        });
                        _startHideTimer();
                      },
                      icon: Icon(
                        _controller.value.isPlaying
                            ? Icons.pause_circle
                            : Icons.play_circle,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      iconSize: 40,
                      onPressed: () {
                        _controller.seekTo(
                            _controller.value.position +
                                const Duration(seconds: 10));
                      },
                      icon: const Icon(Icons.forward_10,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),

            /// BOTTOM CONTROLS
            if (!_isLocked)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  children: [
                    VideoProgressIndicator(
                      _controller,
                      allowScrubbing: true,
                      colors:
                      const VideoProgressColors(
                        playedColor: Colors.red,
                        bufferedColor: Colors.grey,
                        backgroundColor:
                        Colors.white24,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        ValueListenableBuilder(
                          valueListenable: _controller,
                          builder: (context,
                              VideoPlayerValue value,
                              child) {
                            return Text(
                              "${_format(value.position)} / ${_format(value.duration)}",
                              style: const TextStyle(
                                  color:
                                  Colors.white),
                            );
                          },
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                  Icons.closed_caption,
                                  color: Colors.white),
                              onPressed: _changeSubtitle,
                            ),
                            IconButton(
                              icon: const Icon(Icons.speed,
                                  color: Colors.white),
                              onPressed: _changeSpeed,
                            ),
                            IconButton(
                              icon: const Icon(
                                  Icons.high_quality,
                                  color: Colors.white),
                              onPressed: _changeQuality,
                            ),
                          ],
                        )
                      ],
                    )
                  ],
                ),
              ),
          ],
        ],
      ),
        ),
    );
  }
}


