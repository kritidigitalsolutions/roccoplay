import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../app/theme/app_colors.dart';

class VoiceListeningPage extends StatefulWidget {
  const VoiceListeningPage({super.key});

  @override
  State<VoiceListeningPage> createState() => _VoiceListeningPageState();
}

class _VoiceListeningPageState extends State<VoiceListeningPage>
    with SingleTickerProviderStateMixin {
  late final stt.SpeechToText _speech;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  String _spokenText = "";
  String _statusMessage = "Listening...";
  bool _isListening = false;
  bool _isInitializing = false;
  bool _hasPopped = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initAndStartListening();
  }

  Future<void> _initAndStartListening() async {
    if (_isInitializing || _hasPopped) return;
    _isInitializing = true;

    try {
      final available = await _speech.initialize(
        onError: (errorNotification) {
          debugPrint("Speech recognition error: ${errorNotification.errorMsg}");
          if (!mounted || _hasPopped) return;
          setState(() {
            _isListening = false;
            if (_spokenText.isEmpty) {
              _statusMessage = "Could not hear clearly. Tap mic to retry.";
            }
          });
        },
        onStatus: (status) {
          debugPrint("Speech recognition status: $status");
          if (!mounted || _hasPopped) return;
          if (status == 'listening') {
            setState(() {
              _isListening = true;
              _statusMessage = "Listening...";
            });
          } else if (status == 'notListening' || status == 'done') {
            setState(() {
              _isListening = false;
              if (_spokenText.isNotEmpty) {
                _statusMessage = "Tap search or mic to retry";
              } else {
                _statusMessage = "Tap microphone to speak";
              }
            });
          }
        },
      );

      if (!mounted || _hasPopped) return;

      if (available) {
        _startListeningSession();
      } else {
        setState(() {
          _isListening = false;
          _statusMessage = "Voice search unavailable or permission denied";
        });
      }
    } catch (e) {
      debugPrint("Voice search initialize exception: $e");
      if (mounted && !_hasPopped) {
        setState(() {
          _isListening = false;
          _statusMessage = "Voice search service unavailable";
        });
      }
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _startListeningSession() async {
    if (_hasPopped || !mounted) return;

    try {
      setState(() {
        _isListening = true;
        _statusMessage = "Listening...";
      });

      await _speech.listen(
        onResult: (result) {
          if (!mounted || _hasPopped) return;

          setState(() {
            _spokenText = result.recognizedWords;
          });

          if (result.finalResult && _spokenText.trim().isNotEmpty) {
            // Give user a brief moment to see their recognized query before closing
            Future.delayed(const Duration(milliseconds: 350), () {
              _finishAndPop(_spokenText);
            });
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint("Voice search listen exception: $e");
      if (mounted && !_hasPopped) {
        setState(() {
          _isListening = false;
          _statusMessage = "Tap microphone to speak";
        });
      }
    }
  }

  void _onMicTap() {
    if (_isListening) {
      if (_spokenText.trim().isNotEmpty) {
        _finishAndPop(_spokenText);
      } else {
        _stopListeningSession();
      }
    } else {
      if (!_speech.isAvailable) {
        _initAndStartListening();
      } else {
        _startListeningSession();
      }
    }
  }

  void _stopListeningSession() {
    try {
      if (_speech.isListening) {
        _speech.stop();
      }
    } catch (_) {}
    if (mounted && !_hasPopped) {
      setState(() {
        _isListening = false;
        _statusMessage = "Tap microphone to speak";
      });
    }
  }

  void _finishAndPop([String? text]) {
    if (_hasPopped || !mounted) return;
    _hasPopped = true;

    try {
      if (_speech.isListening) {
        _speech.stop();
      }
      _speech.cancel();
    } catch (_) {}

    Navigator.of(context).pop(text ?? _spokenText);
  }

  @override
  void dispose() {
    _hasPopped = true;
    _pulseController.dispose();
    try {
      if (_speech.isListening) {
        _speech.stop();
      }
      _speech.cancel();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.88),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _statusMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),

                // Animated Mic Button
                GestureDetector(
                  onTap: _onMicTap,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      final scale = _isListening ? _pulseAnimation.value : 1.0;
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _isListening
                                  ? [
                                      AppColors.buttonColor,
                                      const Color(0xFFE50914),
                                    ]
                                  : [
                                      const Color(0xFF2C2C36),
                                      const Color(0xFF1E1E26),
                                    ],
                            ),
                            border: Border.all(
                              color: _isListening
                                  ? AppColors.buttonColor
                                  : Colors.white24,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_isListening
                                        ? AppColors.buttonColor
                                        : Colors.black)
                                    .withOpacity(0.35),
                                blurRadius: 20,
                                spreadRadius: _isListening ? 4 : 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_none_rounded,
                            color: Colors.white,
                            size: 46,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 32),

                // Spoken text display
                Container(
                  constraints: const BoxConstraints(minHeight: 50, maxWidth: 320),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1B22),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _spokenText.isEmpty ? "Speak now..." : _spokenText,
                    style: TextStyle(
                      color: _spokenText.isEmpty ? Colors.white38 : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 36),

                // Actions: Cancel & Search button if text recognized
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => _finishAndPop(""),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        backgroundColor: const Color(0xFF22222B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (_spokenText.trim().isNotEmpty) ...[
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () => _finishAndPop(_spokenText),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          backgroundColor: AppColors.buttonColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          "Search",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
