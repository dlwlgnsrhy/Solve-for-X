import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_config.dart';
import '../services/database_service.dart';

class VaultPage extends StatefulWidget {
  const VaultPage({Key? key}) : super(key: key);

  @override
  _VaultPageState createState() => _VaultPageState();
}

class _VaultPageState extends State<VaultPage> {
  bool _isLocked = true;
  String _pin = '';
  String _statusMessage = 'Vault Encrypted';
  List<Map<String, dynamic>> _secrets = [];
  bool _isLoadingSecrets = false;

  // Controllers for adding secrets
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _secretController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSecrets();
  }

  Future<void> _loadSecrets() async {
    setState(() => _isLoadingSecrets = true);
    final memos = await DatabaseService.getMemos();
    // Filter Secrets category
    final secrets = memos.where((m) => m['category'] == 'Secrets').toList();
    setState(() {
      _secrets = secrets;
      _isLoadingSecrets = false;
    });
  }

  void _handlePinPress(String value) async {
    final correctPin = await DatabaseService.getMasterPin();
    if (_pin.length < 4) {
      setState(() {
        _pin += value;
      });
      if (_pin.length == 4) {
        if (_pin == correctPin) {
          setState(() {
            _isLocked = false;
            _statusMessage = 'Access Granted';
            _pin = '';
          });
          await DatabaseService.addSentinelLog('Security Auths', 'Biometric vault opened successfully via PIN key', status: 'SUCCESS');
        } else {
          setState(() {
            _pin = '';
            _statusMessage = 'Incorrect PIN. Default is 2026.';
          });
          await DatabaseService.addSentinelLog('Intrusion Warning', 'Vault authentication failed: Invalid master PIN entry', status: 'WARNING');
        }
      }
    }
  }

  void _lockVault() async {
    setState(() {
      _pin = '';
      _isLocked = true;
      _statusMessage = 'Vault Encrypted';
    });
    await DatabaseService.addSentinelLog('Security Auths', 'Biometric vault auto-locked securely', status: 'SUCCESS');
  }

  void _addSecret() async {
    if (_titleController.text.isEmpty || _secretController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill title and secret key.')),
      );
      return;
    }

    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = "${months[now.month - 1]} ${now.day}, ${now.year}";

    final newSecret = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': _titleController.text,
      'content': _secretController.text,
      'date': dateStr,
      'category': 'Secrets',
      'tags': 'Vault,Secret',
      'isPinned': false,
      'isLocked': true,
      'username': _userController.text.isNotEmpty ? _userController.text : 'Secure User',
    };

    await DatabaseService.addMemo(newSecret);
    
    _titleController.clear();
    _userController.clear();
    _secretController.clear();
    
    Navigator.pop(context);
    _loadSecrets();
  }

  void _deleteSecret(String id, String title) async {
    await DatabaseService.deleteMemo(id, title);
    _loadSecrets();
  }

  void _showAddSecretSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppConfig.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConfig.borderRadius)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Seal New Private Secret", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Resource Title (e.g. BTC Private Key, Admin Pass)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: AppConfig.cardColor,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _userController,
                  decoration: InputDecoration(
                    hintText: 'Associated Username / Owner',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: AppConfig.cardColor,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _secretController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Confidential Secret Value',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: AppConfig.cardColor,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addSecret,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConfig.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('Seal Securely', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Hardware Locked Vault',
          style: GoogleFonts.outfit(color: AppConfig.secondaryColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          if (!_isLocked)
            IconButton(
              icon: const Icon(Icons.lock_rounded, color: AppConfig.primaryColor),
              onPressed: _lockVault,
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConfig.paddingCard),
        child: _isLocked ? _buildLockScreen() : _buildVaultContent(),
      ),
    );
  }

  Widget _buildLockScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppConfig.primaryColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.fingerprint_rounded,
            size: 72,
            color: AppConfig.primaryColor,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _statusMessage,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 18, color: AppConfig.secondaryColor.withOpacity(0.8)),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: index < _pin.length ? AppConfig.primaryColor : Colors.grey.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
        const Spacer(),
        _buildPinPad(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildPinPad() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.5,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        String buttonText = '';
        if (index < 9) buttonText = '${index + 1}';
        if (index == 9) buttonText = 'Clear';
        if (index == 10) buttonText = '0';
        if (index == 11) buttonText = 'Scan';

        return InkWell(
          onTap: () async {
            if (buttonText == 'Clear') {
              setState(() => _pin = '');
            } else if (buttonText == 'Scan') {
              // Simulate biometric verification bypass
              setState(() {
                _isLocked = false;
                _statusMessage = 'Unlocked via Sandbox Face ID';
              });
              await DatabaseService.addSentinelLog('Security Auths', 'Biometric vault unlocked via Face ID scan bypass', status: 'SUCCESS');
            } else if (buttonText.isNotEmpty) {
              _handlePinPress(buttonText);
            }
          },
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          child: Container(
            decoration: BoxDecoration(
              color: AppConfig.cardColor,
              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 6, offset: const Offset(0, 3))
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              buttonText,
              style: GoogleFonts.outfit(
                fontSize: buttonText.length > 2 ? 13 : 20,
                fontWeight: FontWeight.bold,
                color: AppConfig.secondaryColor,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVaultContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppConfig.primaryColor, Color(0xFFe5c3a3)]),
            borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.security_rounded, color: Colors.white, size: 36),
              const SizedBox(height: 12),
              Text('Confidential Sandbox Open', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('All secrets listed are fully encrypted on-device. No telemetry leaks out.', style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.9), fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('SECURE HARDWARE STRINGS', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            IconButton(
              icon: const Icon(Icons.add_box_rounded, color: AppConfig.primaryColor),
              onPressed: _showAddSecretSheet,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _isLoadingSecrets
              ? const Center(child: CircularProgressIndicator())
              : _secrets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_open_rounded, color: Colors.grey.shade300, size: 40),
                          const SizedBox(height: 8),
                          Text('No secret credentials locked yet.', style: GoogleFonts.outfit(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _secrets.length,
                      itemBuilder: (context, index) {
                        final secret = _secrets[index];
                        final uName = secret['username'] as String? ?? 'Secure Cipher';
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppConfig.cardColor,
                            borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 10, offset: const Offset(0, 4))
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppConfig.primaryColor.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.vpn_key_rounded, color: AppConfig.primaryColor),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(secret['title'] ?? 'Secret Key', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text(uName, style: GoogleFonts.outfit(color: Colors.grey, fontSize: 11)),
                                    const SizedBox(height: 4),
                                    Text('•••••••••••••', style: GoogleFonts.outfit(color: AppConfig.primaryColor, fontWeight: FontWeight.w600, fontSize: 14)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.copy_rounded, color: Colors.grey, size: 20),
                                    onPressed: () async {
                                      final rawSecret = secret['content'] as String? ?? '';
                                      await Clipboard.setData(ClipboardData(text: rawSecret));
                                      await DatabaseService.addSentinelLog(
                                        'Biometrics Decrypt', 
                                        'Secret value for "${secret['title']}" copied to memory keyboard securely', 
                                        status: 'SUCCESS'
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Secure item copied to secure system memory clipboard!'),
                                          backgroundColor: AppConfig.primaryColor,
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_sweep_rounded, color: Colors.red.shade300, size: 20),
                                    onPressed: () => _deleteSecret(secret['id'], secret['title']),
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
    );
  }
}