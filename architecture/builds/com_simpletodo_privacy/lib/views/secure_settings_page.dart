import 'package:flutter/material.dart';
import '../config/app_config.dart';

class SecureSettingsPage extends StatelessWidget {
  const SecureSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Settings & Security',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppConfig.primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your secure hardware cryptographic profile status.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppConfig.cardColor,
                  borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                ),
                child: Column(
                  children: [
                    _buildSettingsRow(
                      icon: Icons.fingerprint,
                      title: "Biometric Authentication",
                      subtitle: "Required on application resume",
                      trailing: Switch(
                        value: true,
                        onChanged: (v) {},
                        activeColor: AppConfig.primaryColor,
                      ),
                    ),
                    const Divider(height: 24),
                    _buildSettingsRow(
                      icon: Icons.vpn_lock,
                      title: "Device Bound Security",
                      subtitle: "Zero cloud backups enabled",
                      trailing: const Icon(Icons.verified, color: AppConfig.secondaryColor),
                    ),
                    const Divider(height: 24),
                    _buildSettingsRow(
                      icon: Icons.sd_storage,
                      title: "Local Database Size",
                      subtitle: "44 KB encrypted storage",
                      trailing: TextButton(
                        child: const Text("Optimize"),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConfig.secondaryColor.withOpacity(0.1),
                    foregroundColor: AppConfig.secondaryColor,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                    ),
                  ),
                  icon: const Icon(Icons.delete_forever),
                  label: const Text("Perform Self Destruct Code Wipe", style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Simulated Self-Destruct initialized. Memory purged!"),
                        backgroundColor: AppConfig.secondaryColor,
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Row(
      children: [
        CircleAvatar( 
          backgroundColor: AppConfig.primaryColor.withOpacity(0.1),
          child: Icon(icon, color: AppConfig.primaryColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
        ),
        trailing,
      ],
    );
  }
}