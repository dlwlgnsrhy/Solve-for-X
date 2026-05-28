import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/app_config.dart';
import 'views/dashboard_page.dart';
import 'views/journal_page.dart';
import 'views/vault_page.dart';
import 'views/sentinel_page.dart';
import 'views/settings_page.dart';

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
        fontFamily: GoogleFonts.outfit().fontFamily,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: AppConfig.primaryColor,
          secondary: AppConfig.secondaryColor,
        ),
      ),
      home: const MainNavigationContainer(),
    );
  }
}

class MainNavigationContainer extends StatefulWidget {
  const MainNavigationContainer({Key? key}) : super(key: key);

  @override
  _MainNavigationContainerState createState() => _MainNavigationContainerState();
}

class _MainNavigationContainerState extends State<MainNavigationContainer> {
  int _currentIndex = 0;

  void _onDataCleared() {
    setState(() {
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      DashboardHomeScreen(onNavigate: (index) {
        setState(() {
          _currentIndex = index;
        });
      }),
      const JournalPage(),
      const VaultPage(),
      const SentinelPage(),
      SettingsPage(onDataCleared: _onDataCleared),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppConfig.cardColor,
          selectedItemColor: AppConfig.primaryColor,
          unselectedItemColor: Colors.black38,
          selectedLabelStyle: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.outfit(fontSize: 10),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.spa_rounded), label: 'Sanctuary'),
            BottomNavigationBarItem(icon: Icon(Icons.book_rounded), label: 'Memos'),
            BottomNavigationBarItem(icon: Icon(Icons.vpn_key_rounded), label: 'Vault'),
            BottomNavigationBarItem(icon: Icon(Icons.terminal_rounded), label: 'Sentinel'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}