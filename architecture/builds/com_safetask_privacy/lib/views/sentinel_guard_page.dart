import 'package:flutter/material.dart';
import '../config/app_config.dart';

class SentinelGuardPage extends StatelessWidget {
  SentinelGuardPage({Key? key}) : super(key: key);

  final List<Map<String, String>> threatLogs = [
    {
      "time": "Just Now",
      "title": "Local Storage Lock",
      "status": "Safe",
      "desc": "Cryptographic key validated using local enclave verification standard. Zero leak vectors exposed."
    },
    {
      "time": "3 hours ago",
      "title": "Biometric Verification",
      "status": "Verified",
      "desc": "Passed secure local Touch ID / Face ID sensor loop. Process isolated successfully."
    },
    {
      "time": "Yesterday",
      "title": "Sandbox Protocol",
      "status": "Enforced",
      "desc": "Hardware backplane verified app as isolated. Outbound standard TCP routes hard blocked."
    }
  ];

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
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppConfig.primaryColor, AppConfig.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppConfig.borderRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.shield, color: Colors.white, size: 28),
                      SizedBox(width: 8),
                      Text(
                        "Sentinel Active",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "SafeSpace is hardened with fully sandboxed partitions. Your encryption layers remain strictly unlinked from central systems.",
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Hardware Integrity Timeline",
              style: TextStyle(
                color: AppConfig.textDarkColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: threatLogs.length,
                itemBuilder: (context, index) {
                  final log = threatLogs[index];
                  return Card(
                    color: AppConfig.cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConfig.borderRadius)),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.verified, color: AppConfig.secondaryColor, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      log['title']!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppConfig.textDarkColor,
                                      ),
                                    ),
                                    Text(
                                      log['time']!,
                                      style: const TextStyle(fontSize: 11, color: AppConfig.textLightColor),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  log['desc']!,
                                  style: TextStyle(fontSize: 12, color: AppConfig.textDarkColor.withOpacity(0.7)),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    log['status']!.toUpperCase(),
                                    style: TextStyle(fontSize: 9, color: Colors.green[800], fontWeight: FontWeight.bold),
                                  ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}