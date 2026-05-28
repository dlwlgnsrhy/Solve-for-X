import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/app_config.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppConfig.backgroundColor,
        cardColor: AppConfig.cardColor,
        primaryColor: AppConfig.primaryColor,
        colorScheme: ColorScheme.dark(
          primary: AppConfig.primaryColor,
          secondary: AppConfig.secondaryColor,
          surface: AppConfig.cardColor,
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [];
    final List<BottomNavigationBarItem> navItems = [];

    // Always include Home
    tabs.add(const DashboardHomeScreen());
    navItems.add(const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_rounded),
      label: 'Home',
    ));

    // Conditional Chat
    if (AppConfig.enableChat) {
      tabs.add(const ChatScreen());
      navItems.add(const BottomNavigationBarItem(
        icon: Icon(Icons.forum_rounded),
        label: 'Chat',
      ));
    }

    // Conditional Settings
    if (AppConfig.enableSettings) {
      tabs.add(const SettingsScreen());
      navItems.add(const BottomNavigationBarItem(
        icon: Icon(Icons.settings_rounded),
        label: 'Settings',
      ));
    }

    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: tabs[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: AppConfig.backgroundColor,
          selectedItemColor: AppConfig.primaryColor,
          unselectedItemColor: Colors.white54,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.outfit(fontSize: 11),
          items: navItems,
        ),
      ),
    );
  }
}

class DashboardHomeScreen extends StatelessWidget {
  const DashboardHomeScreen({super.key});

  IconData _getIconData(String name) {
    switch (name.toLowerCase()) {
      case 'bolt':
        return Icons.bolt_rounded;
      case 'layers':
        return Icons.layers_rounded;
      case 'grain':
        return Icons.grain_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'settings':
        return Icons.settings_rounded;
      default:
        return Icons.circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Elegant Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WELCOME BACK',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: AppConfig.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppConfig.appName,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppConfig.primaryColor, AppConfig.secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppConfig.primaryColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.api_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Glowing Hero Card (Glassmorphism)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppConfig.primaryColor.withOpacity(0.15),
                  AppConfig.secondaryColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConfig.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'BUILD SUCCESSFUL',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppConfig.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppConfig.heroTitle,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppConfig.heroSubtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Dynamic Feature Title
          Text(
            'ACTIVE SPEC MODULES',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.white38,
            ),
          ),
          const SizedBox(height: 16),

          // Grid View of Dynamic Items
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: AppConfig.dynamicItems.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) {
              final item = AppConfig.dynamicItems[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConfig.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.05),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppConfig.primaryColor.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconData(item['icon'] ?? 'circle'),
                        color: AppConfig.secondaryColor,
                        size: 20,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] ?? 'Feature Module',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['description'] ?? 'Swapped content module.',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: Colors.white54,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Welcome to your tailored Chat Portal! How can I assist you with your operations today?',
      'isUser': false,
    }
  ];

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _messages.add({
        'text': _controller.text.trim(),
        'isUser': true,
      });
      final prompt = _controller.text;
      _controller.clear();

      // Simulated dynamic response based on app details
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() {
          _messages.add({
            'text': 'Simulated response from pipeline server (${AppConfig.apiBaseUrl}): Processed request "$prompt" successfully.',
            'isUser': false,
          });
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.08),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppConfig.primaryColor.withOpacity(0.15),
                child: Icon(Icons.chat_bubble_outline_rounded, color: AppConfig.primaryColor),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tailored Service Portal',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'Active Gateway: ${AppConfig.apiBaseUrl}',
                    style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              return Align(
                alignment: msg['isUser'] ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  decoration: BoxDecoration(
                    color: msg['isUser'] ? AppConfig.primaryColor : AppConfig.cardColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(msg['isUser'] ? 16 : 4),
                      bottomRight: Radius.circular(msg['isUser'] ? 4 : 16),
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.05),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    msg['text'],
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Ask your tailored service...',
                    hintStyle: GoogleFonts.outfit(color: Colors.white24, fontSize: 13),
                    fillColor: AppConfig.cardColor,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: AppConfig.primaryColor),
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: _sendMessage,
                style: IconButton.styleFrom(
                  backgroundColor: AppConfig.primaryColor,
                  shape: const CircleBorder(),
                ),
                icon: const Icon(Icons.send_rounded, color: Colors.white),
              )
            ],
          ),
        )
      ],
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SYSTEM CONFIGURATION',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.white38,
            ),
          ),
          const SizedBox(height: 20),

          // Metadata Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppConfig.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                _buildMetaRow('App Name', AppConfig.appName),
                const Divider(color: Colors.white10),
                _buildMetaRow('Version', AppConfig.appVersion),
                const Divider(color: Colors.white10),
                _buildMetaRow('API Endpoint', AppConfig.apiBaseUrl),
                const Divider(color: Colors.white10),
                _buildMetaRow('Theme Palette', '${AppConfig.primaryColorHex} / ${AppConfig.secondaryColorHex}'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Forger Signature Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.03),
                  AppConfig.primaryColor.withOpacity(0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.03),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppConfig.secondaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.verified_user_rounded, color: AppConfig.secondaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cloud Native Pipeline Verified',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'This application has been successfully generated by the autonomous forging core.',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
