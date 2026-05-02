import 'package:flutter/material.dart';
import 'package:origin/core/theme/app_theme.dart';
import 'package:origin/features/home/presentation/widgets/authenticity_score_page.dart';

/// Standalone screen that displays the authenticity score dashboard.
///
/// Wraps [AuthenticityScorePage] in a Scaffold with a navigation-ready
/// AppBar so it can be pushed via [Navigator.push].
class AnalyzerDashboardScreen extends StatelessWidget {
  const AnalyzerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.bgPrimary,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColor.textPrimary, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Authenticator',
          style: TextStyle(
            color: AppColor.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const AuthenticityScorePage(),
    );
  }
}
