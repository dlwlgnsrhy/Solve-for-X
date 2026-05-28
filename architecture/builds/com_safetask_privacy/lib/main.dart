import 'package:flutter/material.dart';
import 'config/app_config.dart';
import 'views/mindful_journal_page.dart';
import 'views/zen_focus_page.dart';
import 'views/sentinel_guard_page.dart';

void main() {
  runApp(const SafeSpaceApp());
}

class SafeSpaceApp extends StatelessWidget {
  const SafeSpaceApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppConfig.primaryColor,
        scaffoldBackgroundColor: AppConfig.backgroundColor,
        fontFamily: 'Outfit',
      ),
      home: const DashboardHomeScreen(),
    );
  }
}

class DashboardHomeScreen extends StatefulWidget {
  const DashboardHomeScreen({Key? key}) : super(key: key);

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const MindfulJournalPage(),
    const ZenFocusPage(),
    SentinelGuardPage(),
  ];

  final List<String> _titles = [
    "Mindful Diary",
    "Zen Breathing Clock",
    "Sentinel Verification"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConfig.cardColor,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _titles[_currentIndex],
              style: const TextStyle(
                color: AppConfig.textDarkColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const Text(
              "Secure Sanctuary Active",
              style: TextStyle(
                color: AppConfig.primaryColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock, color: AppConfig.primaryColor),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                  title: const Text("Encrypted Vault Shield"),
                  content: const Text("Your entries are protected by stateful zero-knowledge logic. No unencrypted memory chunks leave this system boundary."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Dismiss", style: TextStyle(color: AppConfig.primaryColor)),
                    )
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 1),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: AppConfig.cardColor,
          selectedItemColor: AppConfig.primaryColor,
          unselectedItemColor: AppConfig.textLightColor,
          showUnselectedLabels: true,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: "Journal",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.timer),
              label: "Zen Focus",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.security),
              label: "Sentinel Guard",
            ),
          ],
        ),
      ),
    );
  }
}