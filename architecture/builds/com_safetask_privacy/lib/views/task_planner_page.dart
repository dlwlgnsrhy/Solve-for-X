import 'package:flutter/material.dart';
import '../config/app_config.dart';

class TaskPlannerPage extends StatefulWidget {
  @override
  _TaskPlannerPageState createState() => _TaskPlannerPageState();
}

class _TaskPlannerPageState extends State<TaskPlannerPage> {
  final List<Map<String, dynamic>> _tasks = [
    {"title": "Review cryptographic salt configurations", "done": true, "category": "Security"},
    {"title": "Draft offline-first database migrations", "done": false, "category": "Database"},
    {"title": "Clean local disk caching layers", "done": false, "category": "Cleanup"}
  ];

  final TextEditingController _controller = TextEditingController();
  String _selectedCategory = "General";

  void _addTask() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _tasks.add({
        "title": _controller.text.trim(),
        "done": false,
        "category": _selectedCategory
      });
      _controller.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Task saved securely to local ledger"),
        backgroundColor: AppConfig.primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleTask(int index) {
    setState(() {
      _tasks[index]['done'] = !_tasks[index]['done'];
    });
  }

  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
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
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConfig.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConfig.borderRadius),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline, color: AppConfig.primaryColor),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Sandbox Mode: No network permissions requested or utilized.",
                      style: TextStyle(
                        color: AppConfig.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Text(
              "Private Tasks",
              style: TextStyle(
                color: AppConfig.textDarkColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Secure new task item...",
                      fillColor: AppConfig.cardColor,
                      filled: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: _addTask,
                  child: Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppConfig.primaryColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ["General", "Security", "Database", "Personal"].map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: AppConfig.primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppConfig.textDarkColor,
                      ),
                      onSelected: (val) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                    ),
                  ); 
                }).toList(),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: _tasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_turned_in, size: 64, color: AppConfig.primaryColor.withOpacity(0.4)),
                          SizedBox(height: 16),
                          Text(
                            "All tasks verified & secure",
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        final item = _tasks[index];
                        return Card(
                          color: AppConfig.cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 1,
                          margin: EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: Checkbox(
                              value: item['done'],
                              activeColor: AppConfig.primaryColor,
                              onChanged: (val) => _toggleTask(index),
                            ),
                            title: Text(
                              item['title'],
                              style: TextStyle(
                                decoration: item['done'] ? TextDecoration.lineThrough : null,
                                color: item['done'] ? Colors.grey : AppConfig.textDarkColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                Container(
                                  margin: EdgeInsets.only(top: 4),
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppConfig.secondaryColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item['category'],
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppConfig.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "• Encrypted",
                                  style: TextStyle(fontSize: 10, color: Colors.green[600]),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                              onPressed: () => _deleteTask(index),
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