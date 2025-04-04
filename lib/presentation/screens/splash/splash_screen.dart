import 'package:flutter/material.dart';
import 'package:smart_vision_application/presentation/screens/home/home_screen_navigator.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../tabs-layout/home_tab.dart';


class SplashScreen extends StatefulWidget {
  static const route = '/';
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Simulate app initialization
    await Future.delayed(const Duration(seconds: 2));
    
    // Initialize speech recognition in background
    final speech = stt.SpeechToText();
    await speech.initialize();
    
    // Navigate to home
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreenNavigator()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated voice wave icon
            _buildVoiceWaveAnimation(),
            const SizedBox(height: 30),
            // App title
            Text(
              "Smart Vision",
              style: AppTextStyles.headline1.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            // Subtitle
            Text(
              "Your personal voice-controlled helper",
              style: AppTextStyles.bodyText.copyWith(
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 40),
            // Loading indicator
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceWaveAnimation() {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Mic icon
          Icon(
            Icons.mic,
            size: 60,
            color: AppColors.primary,
          ),
          // Animated waves
          ...List.generate(3, (index) {
            return AnimatedContainer(
              duration: Duration(milliseconds: 1500 + (index * 300)),
              curve: Curves.easeInOut,
              width: 80 + (index * 40),
              height: 80 + (index * 40),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3 - (index * 0.1)),
                  width: 2,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}