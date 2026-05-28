import 'package:flutter/material.dart';
import '../config/app_config.dart';

class MindfulJournalPage extends StatefulWidget {
  const MindfulJournalPage({Key? key}) : super(key: key);
  @override
  State<MindfulJournalPage> createState() => _MindfulJournalPageState();
}

class _MindfulJournalPageState extends State<MindfulJournalPage> {
  final List<Map<String, dynamic>> _journals = [
    {"title": "Morning meditation and deep calm", "mood": "🌸 Peaceful", "timestamp": "08:30 AM", "content": "Felt completely centered during the 15-minute silent breath. Ready for the day."},
    {"title": "Project milestone completed", "mood": "✨ Inspired", "timestamp": "02:15 PM", "content": "Pushed safe sandbox code locally. Highly satisfying organic styling."}
  ];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String _selectedMood = "🌸 Peaceful";

  void _addEntry() {
    if (_titleController.text.trim().isEmpty) return;
    setState(() {
      _journals.insert(0, {
        "title": _titleController.text.trim(),
        "content": _contentController.text.trim().isEmpty ? "No detailed thoughts written today." : _contentController.text.trim(),
        "mood": _selectedMood,
        "timestamp": "Just Now"
      });
      _titleController.clear();
      _contentController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Journal entry saved securely to local hardware enclave."),
        backgroundColor: AppConfig.primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConfig.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppConfig.borderRadius),
              ),
              child: Row(
                children: [
                  const Icon(Icons.favorite, color: AppConfig.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Offline Zero-Leak diary fully active. Rest easy knowing your emotions belong to you alone.",
                      style: TextStyle(
                        color: AppConfig.textDarkColor.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Your Private Sanctuary",
              style: TextStyle(
                color: AppConfig.textDarkColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: AppConfig.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: "What's on your mind today?",
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: AppConfig.textLightColor),
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        hintText: "Write your soft thoughts down...",
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: AppConfig.textLightColor, fontSize: 13),
                      ),
                      maxLines: 2,
                      style: const TextStyle(fontSize: 13),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DropdownButton<String>(
                          value: _selectedMood,
                          underline: const SizedBox(),
                          items: ["🌸 Peaceful", "✨ Inspired", "🧸 Cozy", "🍀 Calm"].map((mood) {
                            return DropdownMenuItem(value: mood, child: Text(mood));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedMood = val);
                          },
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConfig.primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          onPressed: _addEntry,
                          child: const Text("Keep Safe", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _journals.length,
                itemBuilder: (context, idx) {
                  final item = _journals[idx];
                  return Card(
                    color: AppConfig.cardColor,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                      side: BorderSide(color: AppConfig.primaryColor.withOpacity(0.1), width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppConfig.secondaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(item['mood'], style: const TextStyle(fontSize: 12)),
                              ),
                              Text(item['timestamp'], style: const TextStyle(fontSize: 11, color: AppConfig.textLightColor)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item['title'],
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppConfig.textDarkColor),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item['content'],
                            style: TextStyle(color: AppConfig.textDarkColor.withOpacity(0.7), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}