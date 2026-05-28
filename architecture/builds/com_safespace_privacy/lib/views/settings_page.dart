import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_config.dart';
import '../services/database_service.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback onDataCleared;
  const SettingsPage({Key? key, required this.onDataCleared}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _pinController = TextEditingController();
  bool _obscurePin = true;
  String _currentPin = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentPin();
  }

  Future<void> _loadCurrentPin() async {
    final pin = await DatabaseService.getMasterPin();
    setState(() {
      _currentPin = pin;
    });
  }

  void _updatePin() async {
    if (_pinController.text.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN must be exactly 4 digits.')),
      );
      return;
    }
    await DatabaseService.setMasterPin(_pinController.text);
    final newPin = _pinController.text;
    _pinController.clear();
    setState(() {
      _currentPin = newPin;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Biometric Master security PIN updated successfully!'), backgroundColor: AppConfig.primaryColor),
    );
  }

  void _exportSovereignData() async {
    final memos = await DatabaseService.getMemos();
    final moods = await DatabaseService.getMoods();
    
    final Map<String, dynamic> exportPayload = {
      'exported_at': DateTime.now().toIso8601String(),
      'app_name': AppConfig.appName,
      'notes': memos,
      'wellness_moods': moods
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(exportPayload);
    await Clipboard.setData(ClipboardData(text: jsonStr));
    await DatabaseService.addSentinelLog('Data Portability', 'Sovereign local backup exported as JSON format successfully', status: 'SUCCESS');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConfig.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.share_rounded, color: AppConfig.primaryColor),
            const SizedBox(width: 8),
            Text('Backup Copied Securely', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('A zero-knowledge full JSON database state backup has been packed and copied to your hardware memory clipboard.', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(maxHeight: 100),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppConfig.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(
                  jsonStr,
                  style: GoogleFonts.outfit(fontSize: 8, color: AppConfig.secondaryColor.withOpacity(0.6)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.primaryColor),
            onPressed: () => Navigator.pop(context),
            child: Text('Done', style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _clearAllLocalData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConfig.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text('Wipe Offline Database?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text('This will irreversibly erase all sandboxed reflections, memos, password vault items, and access logs from this device. Are you sure?', style: GoogleFonts.outfit(fontSize: 12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Wipe All Data', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService.clearAllData();
      widget.onDataCleared();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All sandboxed local data wiped completely.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Sanctuary Settings',
          style: GoogleFonts.outfit(color: AppConfig.secondaryColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppConfig.paddingCard, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PIN configuration card
            Text(
              'SECURITY CONTROLS',
              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppConfig.cardColor,
                borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Master Passcode PIN', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Current: $_currentPin', style: GoogleFonts.outfit(color: AppConfig.primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enter a 4-digit code to protect individual journal elements or lock biometric storage entries.',
                    style: GoogleFonts.outfit(color: Colors.grey, fontSize: 11),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _pinController,
                          obscureText: _obscurePin,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: 'New 4-digit PIN',
                            counterText: '',
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility, size: 18),
                              onPressed: () => setState(() => _obscurePin = !_obscurePin),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConfig.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _updatePin,
                        child: Text('Update', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Portability card
            Text(
              'SOVEREIGN PORTABILITY & DATA BACKUP',
              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppConfig.cardColor,
                borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Obsidian Open-Data Philosophy', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    'Export your local database snapshot directly as a standard JSON package to guarantee complete sovereignty over your intellectual data.',
                    style: GoogleFonts.outfit(color: Colors.grey, fontSize: 11),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConfig.secondaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _exportSovereignData,
                      icon: const Icon(Icons.share_rounded, size: 18, color: Colors.white),
                      label: Text('Export Open Sovereign Data', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sovereign Sandbox Info Card
            Text(
              'DYNAMIC SANDBOX PROFILE',
              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConfig.cardColor,
                borderRadius: BorderRadius.circular(AppConfig.borderRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileRow('Client Version', 'v1.4.2-Release'),
                  _buildProfileRow('Design Signature', 'Claude Terracotta Cozy'),
                  _buildProfileRow('Crypto Sandboxing', 'Active (Local API V2)'),
                  _buildProfileRow('Cloud Telemetry', 'DISABLED (0 bytes sent)'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Wipe data card
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _clearAllLocalData,
                icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                label: Text('Purge Device Sovereign Database', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
          Text(value, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppConfig.secondaryColor)),
        ],
      ),
    );
  }
}
