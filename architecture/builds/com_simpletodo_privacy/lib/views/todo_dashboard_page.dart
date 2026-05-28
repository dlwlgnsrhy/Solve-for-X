import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/todo_item.dart';

class TodoDashboardPage extends StatefulWidget {
  final List<TodoItem> tasks;
  final Function(TodoItem) onToggle;
  final Function(TodoItem) onDelete;
  final Function(String, String) onAdd;

  const TodoDashboardPage({
    super.key,
    required this.tasks,
    required this.onToggle,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  State<TodoDashboardPage> createState() => _TodoDashboardPageState();
}

class _TodoDashboardPageState extends State<TodoDashboardPage> {
  final TextEditingController _taskController = TextEditingController();
  String _selectedCategory = 'Personal';

  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppConfig.cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppConfig.borderRadius),
                  topRight: Radius.circular(AppConfig.borderRadius),
                ),
              ),
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create New Mindful Task',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppConfig.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _taskController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Capture a private goal...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: AppConfig.backgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Mindful Category',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppConfig.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ['Personal', 'Work', 'Urgent'].map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) {
                              setModalState(() {
                                _selectedCategory = cat;
                              });
                              setState(() {
                                _selectedCategory = cat;
                              });
                            }
                          },
                          selectedColor: AppConfig.primaryColor.withOpacity(0.15),
                          backgroundColor: AppConfig.backgroundColor,
                          labelStyle: TextStyle(
                            color: isSelected ? AppConfig.primaryColor : Colors.grey.shade700,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_taskController.text.trim().isNotEmpty) {
                          widget.onAdd(_taskController.text.trim(), _selectedCategory);
                          _taskController.clear();
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConfig.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Save to Local Vault', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.tasks.length;
    final completed = widget.tasks.where((t) => t.isCompleted).length;
    final double progress = total == 0 ? 0 : completed / total;

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SafeSpace',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppConfig.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your Friendly Private Haven',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppConfig.secondaryColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: AppConfig.primaryColor, size: 44),
                    onPressed: () => _showAddTaskSheet(context),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppConfig.cardColor,
                  borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox(
                      height: 64,
                      width: 64,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 6,
                            backgroundColor: AppConfig.backgroundColor,
                            color: AppConfig.primaryColor,
                          ),
                          Center(
                            child: Text(
                              '${(progress * 100).toInt()}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppConfig.primaryColor,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mindful Performance',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppConfig.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$completed of $total items securely processed in local memory.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ], 
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Tasks & Milestones',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConfig.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: widget.tasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.spa, size: 64, color: AppConfig.primaryColor.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text(
                            'Quiet & Tranquil Today',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enjoy the quiet or log a task with local-only security.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
                      itemCount: widget.tasks.length,
                      itemBuilder: (context, index) {
                        final item = widget.tasks[index];
                        return Dismissible(
                          key: Key(item.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: AppConfig.secondaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                            ),
                            child: const Icon(Icons.delete_outline, color: AppConfig.secondaryColor),
                          ),
                          onDismissed: (dir) {
                            widget.onDelete(item);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppConfig.cardColor,
                              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.015),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: ListTile(
                              leading: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                                child: IconButton(
                                  key: ValueKey(item.isCompleted),
                                  icon: Icon(
                                    item.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                                    color: item.isCompleted ? AppConfig.primaryColor : Colors.grey.shade400,
                                    size: 26,
                                  ),
                                  onPressed: () => widget.onToggle(item),
                                ),
                              ),
                              title: Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: item.isCompleted ? Colors.grey : Colors.grey.shade800,
                                  decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(item.category).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  item.category,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _getCategoryColor(item.category),
                                  ),
                                ),
                              ),
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

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Work':
        return AppConfig.primaryColor;
      case 'Urgent':
        return AppConfig.secondaryColor;
      default:
        return Colors.teal.shade300;
    }
  }
}