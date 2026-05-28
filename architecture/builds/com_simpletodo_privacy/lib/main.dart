import 'package:flutter/material.dart';
import 'config/app_config.dart';
import 'models/todo_item.dart';
import 'views/todo_dashboard_page.dart';
import 'views/productivity_stats_page.dart';
import 'views/secure_chat_page.dart';
import 'views/secure_settings_page.dart';

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
        primaryColor: AppConfig.primaryColor,
        scaffoldBackgroundColor: AppConfig.backgroundColor,
        fontFamily: 'Outfit',
        useMaterial3: true,
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

  final List<TodoItem> _tasks = [
    TodoItem(id: '1', title: 'Prepare design system proposal', category: 'Work', isCompleted: true),
    TodoItem(id: '2', title: 'Review local keychain integration', category: 'Urgent', isCompleted: false),
    TodoItem(id: '3', title: 'Plan Sunday mindful layout session', category: 'Personal', isCompleted: false),
  ];

  void _toggleTask(TodoItem item) {
    setState(() {
      item.isCompleted = !item.isCompleted;
    });
  }

  void _deleteTask(TodoItem item) {
    setState(() {
      _tasks.removeWhere((t) => t.id == item.id);
    });
  }

  void _addNewTask(String title, String category) {
    setState(() {
      _tasks.insert(
        0,
        TodoItem(
          id: DateTime.now().toIso8601String(),
          title: title,
          category: category,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      TodoDashboardPage(
        tasks: _tasks,
        onToggle: _toggleTask,
        onDelete: _deleteTask,
        onAdd: _addNewTask,
      ),
      ProductivityStatsPage(tasks: _tasks),
      const SecureChatPage(),
      const SecureSettingsPage(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.shade100, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: AppConfig.cardColor,
          selectedItemColor: AppConfig.primaryColor,
          unselectedItemColor: Colors.grey.shade400,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.check_box_outlined),
              activeIcon: Icon(Icons.check_box_rounded),
              label: 'Checklist',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics_rounded),
              label: 'Metrics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              activeIcon: Icon(Icons.chat_bubble_rounded),
              label: 'Sanctuary',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.lock_outline_rounded),
              activeIcon: Icon(Icons.lock_rounded),
              label: 'Vault',
            ),
          ],
        ),
      ),
    );
  }
}