import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../app/routes/app_routes.dart';
import '../../utils/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isNavigated = false;

  @override
  void initState() {
    super.initState();

    // 🚀 If app was launched via notification tap, navigate immediately without waiting for splash video
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (NotificationService.pendingContentNavigation != null) {
        _finishAndNavigate(NotificationService.pendingContentNavigation);
        return;
      }
    });

    _controller = VideoPlayerController.asset("assets/videos/Roccoplay_.mp4")
      ..initialize().then((_) {
        if (mounted && !_isNavigated) {
          setState(() {});
          _controller.play();
        }
      });

    /// Navigate when video finishes
    _controller.addListener(() {
      if (_controller.value.position >= _controller.value.duration &&
          !_controller.value.isPlaying &&
          !_isNavigated) {
        if (Get.currentRoute == AppRoutes.splash) {
          _finishAndNavigate();
        }
      }
    });
  }

  void _finishAndNavigate([dynamic content]) {
    if (_isNavigated) return;
    _isNavigated = true;

    try {
      _controller.pause();
    } catch (_) {}

    final pending = content ?? NotificationService.pendingContentNavigation;
    NotificationService.pendingContentNavigation = null;

    Get.offAllNamed(AppRoutes.home);

    if (pending != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        Get.toNamed(
          AppRoutes.dramaDetails,
          arguments: pending,
          preventDuplicates: false,
        );
      });
    }
  }

  @override
  void dispose() {
    _isNavigated = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _controller.value.isInitialized
            ? FractionallySizedBox(
                widthFactor: 1.0,
                heightFactor: 1.0,
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
