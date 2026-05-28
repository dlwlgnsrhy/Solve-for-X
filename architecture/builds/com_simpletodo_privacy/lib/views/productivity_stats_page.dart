import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/todo_item.dart';

class ProductivityStatsPage extends StatelessWidget {
  final List<TodoItem> tasks;

  const ProductivityStatsPage({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final total = tasks.length;
    final completed = tasks.where((t) => t.isCompleted).length;
    final completionRate = total == 0 ? 0.0 : completed / total;
    final personalTasks = tasks.where((t) => t.category == 'Personal').length;
    final workTasks = tasks.where((t) => t.category == 'Work').length;
    final urgentTasks = tasks.where((t) => t.category == 'Urgent').length;

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Privacy Audit & Stats',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppConfig.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Zero logs recorded. Complete database isolation.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                _buildProgressCard(completed, total, completionRate),
                const SizedBox(height: 24),
                const Text(
                  'Category Logs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppConfig.primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                _buildBreakdownGrid(personalTasks, workTasks, urgentTasks),
                const SizedBox(height: 24),
                _buildSecurityShield(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(int completed, int total, double rate) {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.bubble_chart, color: AppConfig.secondaryColor),
              SizedBox(width: 8),
              Text(
                'Success Quotient',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConfig.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: rate,
            backgroundColor: AppConfig.backgroundColor,
            color: AppConfig.primaryColor,
            minHeight: 12,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Local Completion Rate',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              Text(
                '${(rate * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppConfig.secondaryColor,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBreakdownGrid(int personal, int work, int urgent) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.95,
      children: [
        _buildStatBox('Personal', personal, Colors.teal.shade300),
        _buildStatBox('Work', work, AppConfig.primaryColor),
        _buildStatBox('Urgent', urgent, AppConfig.secondaryColor),
      ],
    );
  }

  Widget _buildStatBox(String title, int count, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: BorderRadius.circular(AppConfig.borderRadius - 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 8,
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityShield() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConfig.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        border: Border.all(color: AppConfig.primaryColor.withOpacity(0.12)),
      ),
      child: Row(
        children: const [
          Icon(Icons.lock_person_outlined, color: AppConfig.primaryColor, size: 36),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zero-Leak Shield Active',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppConfig.primaryColor,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Local sandbox prevents credential scraping or analytics reporting.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ], 
            ),
          ),
        ],
      ),
    );
  } 
}