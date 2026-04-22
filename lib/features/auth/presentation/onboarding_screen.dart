import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  bool isLastPage = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        padding: const EdgeInsets.only(bottom: 80),
        child: PageView(
          controller: _controller,
          onPageChanged: (index) {
            setState(() => isLastPage = index == 2);
          },
          children: [
            _buildPage(
              "AI Study Planner",
              "Organize your life automatically.",
              Icons.auto_awesome,
            ),
            _buildPage(
              "Track Progress",
              "Monitor your daily streaks and habits.",
              Icons.bar_chart,
            ),
            _buildPage(
              "Stay Focused",
              "Block distractions and achieve your goals.",
              Icons.shield,
            ),
          ],
        ),
      ),
      bottomSheet: isLastPage
          ? TextButton(
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF4A55A2),
                minimumSize: const Size.fromHeight(80),
              ),
              onPressed: () async {
                // Save the marker so onboarding never shows again
                final prefs = await SharedPreferences.getInstance();
                prefs.setBool('showHome', true);

                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                }
              },
              child: const Text("Get Started", style: TextStyle(fontSize: 20)),
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              height: 80,
              color: AppColors.background,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => _controller.jumpToPage(2),
                    child: const Text("SKIP", style: TextStyle(color: Colors.white54)),
                  ),
                  TextButton(
                    onPressed: () => _controller.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut),
                    child: const Text("NEXT", style: TextStyle(color: Color(0xFF6B7BFF))),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPage(String title, String subtitle, IconData icon) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 100, color: const Color(0xFF6B7BFF)),
        const SizedBox(height: 40),
        Text(title,
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 20),
        Text(subtitle,
            style: const TextStyle(fontSize: 16, color: Colors.white54)),
      ],
    );
  }
}
