import 'package:flutter/material.dart';
import 'package:origin/core/theme/app_theme.dart';
import 'package:origin/features/home/presentation/widgets/keystroke_write_page.dart';
import 'package:origin/features/home/presentation/widgets/authenticity_score_page.dart';
import 'package:origin/features/stamps/presentation/screens/stamps_list_screen.dart';

/// Home screen with tab navigation (Write, Score, Stamps).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Custom Tab Bar
              _buildCustomTabBar(context),

              // Tab Bar View
              const Expanded(
                child: TabBarView(
                  children: [
                    _WriteTabContent(),
                    _ScoreTabContent(),
                    _StampsTabContent(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTabBar(BuildContext context) {
    final style = Theme.of(context);
    final tabs = <Tab>[
      const Tab(icon: Icon(Icons.edit_rounded, size: 18), text: 'Write'),
      const Tab(icon: Icon(Icons.auto_awesome_rounded, size: 18), text: 'Score'),
      const Tab(icon: Icon(Icons.emoji_events_rounded, size: 18), text: 'Stamps'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColor.bgSecondary,
        border: Border(
          bottom: const BorderSide(color: AppColor.divider, width: 1),
        ),
      ),
      child: TabBar(
        indicator: BoxDecoration(
          color: AppColor.neonGreen,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(12),
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColor.bgPrimary,
        unselectedLabelColor: AppColor.textDim,
        labelStyle: style.textTheme.titleMedium!.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: style.textTheme.titleMedium,
        dividerColor: Colors.transparent,
        tabs: tabs,
      ),
    );
  }
}

class _WriteTabContent extends StatelessWidget {
  const _WriteTabContent();

  @override
  Widget build(BuildContext context) => const KeystrokeWritePage();
}

class _ScoreTabContent extends StatelessWidget {
  const _ScoreTabContent();

  @override
  Widget build(BuildContext context) => const AuthenticityScorePage();
}

class _StampsTabContent extends StatelessWidget {
  const _StampsTabContent();

  @override
  Widget build(BuildContext context) => const StampsListPage();
}
