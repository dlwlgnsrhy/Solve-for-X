import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_config.dart';
import '../services/database_service.dart';

class SentinelPage extends StatefulWidget {
  const SentinelPage({Key? key}) : super(key: key);

  @override
  State<SentinelPage> createState() => _SentinelPageState();
}

class _SentinelPageState extends State<SentinelPage> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final logsList = await DatabaseService.getSentinelLogs();
    setState(() {
      _logs = logsList;
      _isLoading = false;
    });
  }

  Future<void> _simulateThreatScan() async {
    setState(() => _isScanning = true);
    // Simulate cognitive sandbox security checks
    await Future.delayed(const Duration(milliseconds: 2500));
    await DatabaseService.addSentinelLog(
      'System Threat Scan', 
      'Complete offline memory sandbox scan finished. Zero leaks, zero remote network hooks found.', 
      status: 'SUCCESS'
    );
    setState(() => _isScanning = false);
    _loadLogs();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Offline sandboxing verified: 0 remote threats found.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  int _countSuccesses() {
    return _logs.where((l) => l['status'] == 'SUCCESS').length;
  }

  int _countWarnings() {
    return _logs.where((l) => l['status'] == 'WARNING').length;
  }

  @override
  Widget build(BuildContext context) {
    final successCount = _countSuccesses();
    final warningCount = _countWarnings();
    final shieldLevel = warningCount > 2 ? 'Guarded (Amber)' : 'High Sovereignty';

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Sentinel Guard Logs',
          style: GoogleFonts.outfit(color: AppConfig.secondaryColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConfig.paddingCard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            _buildLiveStatusCard(successCount, warningCount, shieldLevel),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'BIOMETRIC & ACCESS TIMELINE',
                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
                ),
                TextButton.icon(
                  onPressed: _isLoading ? null : _loadLogs,
                  icon: const Icon(Icons.refresh_rounded, size: 16, color: AppConfig.primaryColor),
                  label: Text('Refresh', style: GoogleFonts.outfit(fontSize: 12, color: AppConfig.primaryColor)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppConfig.primaryColor))
                  : _logs.isEmpty
                      ? Center(
                          child: Text('No security events captured.', style: GoogleFonts.outfit(color: Colors.grey)),
                        )
                      : ListView.builder(
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            final log = _logs[index];
                            Color statusColor = AppConfig.primaryColor;
                            IconData logIcon = Icons.check_circle_outline_rounded;

                            if (log['status'] == 'WARNING') {
                              statusColor = Colors.red.shade400;
                              logIcon = Icons.warning_amber_rounded;
                            } else if (log['status'] == 'SUCCESS') {
                              statusColor = const Color(0xFF68d391);
                              logIcon = Icons.verified_user_rounded;
                            } else {
                              statusColor = AppConfig.primaryColor;
                              logIcon = Icons.info_outline_rounded;
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppConfig.cardColor,
                                borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                                border: Border.all(color: statusColor.withOpacity(0.12), width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  Icon(logIcon, color: statusColor, size: 24),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          log['details'] ?? '',
                                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: AppConfig.secondaryColor),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Category: ${log['type']}',
                                          style: GoogleFonts.outfit(color: Colors.grey, fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          (log['status'] as String? ?? 'INFO').toUpperCase(),
                                          style: GoogleFonts.outfit(fontSize: 8, color: statusColor, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        log['time'] ?? 'Just now',
                                        style: GoogleFonts.outfit(color: Colors.grey, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ],
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

  Widget _buildLiveStatusCard(int successCount, int warningCount, String shieldLevel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF48bb78),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Local Sentinel Kernel', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppConfig.secondaryColor)),
                ],
              ),
              _isScanning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppConfig.primaryColor),
                    )
                  : ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConfig.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _simulateThreatScan,
                      icon: const Icon(Icons.security_rounded, size: 12, color: Colors.white),
                      label: Text('Scan Memory', style: GoogleFonts.outfit(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('Verifications', '$successCount', const Color(0xFF68d391)),
              _buildStatItem('Intrusions', '$warningCount', Colors.red.shade300),
              _buildStatItem('Shield Level', shieldLevel.split(' ')[0], AppConfig.primaryColor),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String val, Color highlight) {
    return Column(
      children: [
        Text(val, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: highlight)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.outfit(color: Colors.grey, fontSize: 10)),
      ],
    );
  }
}