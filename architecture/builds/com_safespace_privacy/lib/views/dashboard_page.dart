import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_config.dart';
import '../services/database_service.dart';
import 'graph_page.dart';

class DashboardHomeScreen extends StatefulWidget {
  final Function(int) onNavigate;
  const DashboardHomeScreen({Key? key, required this.onNavigate}) : super(key: key);

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  List<Map<String, dynamic>> _moods = [];
  int _memoCount = 0;
  int _wordCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final moods = await DatabaseService.getMoods();
    final memos = await DatabaseService.getMemos();
    
    int words = 0;
    for (var m in memos) {
      final content = m['content'] as String? ?? '';
      words += content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    }

    setState(() {
      _moods = moods;
      _memoCount = memos.length;
      _wordCount = words;
      _isLoading = false;
    });
  }

  Future<void> _recordMood(String mood) async {
    await DatabaseService.addMood(mood);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Daily reflection level "$mood" secured locally.'),
        backgroundColor: AppConfig.primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _loadStats();
  }

  Map<String, double> _calculateMoodDistribution() {
    if (_moods.isEmpty) return {};
    final Map<String, int> counts = {};
    for (var m in _moods) {
      final moodStr = m['mood'] as String? ?? '🌸 Calm';
      counts[moodStr] = (counts[moodStr] ?? 0) + 1;
    }
    
    final Map<String, double> distribution = {};
    counts.forEach((key, value) {
      distribution[key] = value / _moods.length;
    });
    return distribution;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppConfig.backgroundColor,
        body: Center(child: CircularProgressIndicator(color: AppConfig.primaryColor)),
      );
    }

    final distribution = _calculateMoodDistribution();

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStats,
          color: AppConfig.primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppConfig.paddingCard, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildHeroCard(),
                const SizedBox(height: 24),
                
                // Mood Log Widget
                Text(
                  "SECURE MOOD ANCHOR",
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: AppConfig.secondaryColor.withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 10),
                _buildMoodTrackerWidget(),
                const SizedBox(height: 24),

                // Stats Dashboard Grid
                Text(
                  "LOCAL SOVEREIGN STATISTICS",
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: AppConfig.secondaryColor.withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 10),
                _buildStatsGrid(),
                const SizedBox(height: 24),

                // Mind Graph Section
                Text(
                  "SOVEREIGN KNOWLEDGE MAPPING",
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: AppConfig.secondaryColor.withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 10),
                _buildMindGraphLaunchCard(),
                const SizedBox(height: 24),

                // Mood Analytics Distribution Card
                if (distribution.isNotEmpty) ...[
                  _buildMoodDistributionCard(distribution),
                  const SizedBox(height: 20),
                ],

                // Security Shield Box
                _buildSecurityStateIndicator(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WELCOME BACK',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: AppConfig.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppConfig.appName,
              style: GoogleFonts.outfit(
                color: AppConfig.secondaryColor,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppConfig.primaryColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.shield_rounded, color: AppConfig.primaryColor, size: 24),
        ),
      ],
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppConfig.primaryColor, Color(0xFFe5c3a3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppConfig.primaryColor.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '🌸 100% On-Device Sandboxing',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your Safe Haven',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A beautifully warm, zero-leakage vault protecting your private notes, recovery phrases, and daily self-reflections.',
            style: GoogleFonts.outfit(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodTrackerWidget() {
    final moodsList = ['🌸 Calm', '🌻 Happy', '🛡️ Safe', '🧸 Cozy'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "How are you feeling in this private sanctuary today?",
            style: GoogleFonts.outfit(fontSize: 13, color: AppConfig.secondaryColor.withOpacity(0.7)),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: moodsList.map((m) {
              return InkWell(
                onTap: () => _recordMood(m),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppConfig.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppConfig.primaryColor.withOpacity(0.1)),
                  ),
                  child: Text(
                    m,
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppConfig.secondaryColor),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _buildStatCard('Total Memos', '$_memoCount', Icons.description_rounded, AppConfig.primaryColor),
        _buildStatCard('Words Saved', '$_wordCount', Icons.article_rounded, const Color(0xFF68d391)),
        _buildStatCard('Lock Level', 'Hardware', Icons.fingerprint_rounded, AppConfig.primaryColor),
      ],
    );
  }

  Widget _buildStatCard(String label, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color.withOpacity(0.8), size: 18),
          Text(
            val,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppConfig.secondaryColor,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(color: Colors.grey, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMoodDistributionCard(Map<String, double> distribution) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Sanctuary Mindful Balance",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppConfig.secondaryColor),
          ),
          const SizedBox(height: 12),
          ...distribution.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key, style: GoogleFonts.outfit(fontSize: 12, color: AppConfig.secondaryColor)),
                      Text('${(entry.value * 100).toInt()}%', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppConfig.primaryColor)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: entry.value,
                      backgroundColor: AppConfig.backgroundColor,
                      valueColor: AlwaysStoppedAnimation<Color>(AppConfig.primaryColor),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSecurityStateIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF68d391).withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        border: Border.all(color: const Color(0xFF68d391).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.security_rounded, color: Color(0xFF48bb78)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Local Hardware Encryption Enabled',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: const Color(0xFF2f855a),
                  ),
                ),
                Text(
                  'Data is sandboxed. No analytical tracker network hooks active.',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF38a169),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMindGraphLaunchCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GraphPage()),
          );
        },
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConfig.primaryColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hub_rounded,
                  color: AppConfig.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sovereign Mind Graph',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppConfig.secondaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Visualize on-device neural clusters of tags and memos. Tap to zoom, pan, and read connected thoughts.',
                      style: GoogleFonts.outfit(
                        color: AppConfig.secondaryColor.withOpacity(0.65),
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppConfig.primaryColor,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
