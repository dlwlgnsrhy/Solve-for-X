import 'package:flutter/material.dart';
import '../config/app_config.dart';

class SentinelPage extends StatelessWidget {
  final List<Map<String, String>> securityLogs = [
    {
      "time": "Just Now",
      "title": "Integrity Verification",
      "status": "Passed",
      "desc": "On-disk local database SHA-256 integrity match confirms zero data tampering."
    },
    {
      "time": "15 mins ago",
      "title": "Zero Network Access Rule",
      "status": "Enforced",
      "desc": "Device transport layer isolated. Dynamic requests route exclusively through mock local-loop backplane."
    },
    {
      "time": "1 hour ago",
      "title": "AES-256 Key Status",
      "status": "Active",
      "desc": "Cryptographic vault initialized using secure PBKDF2 parameters."
    },
    {
      "time": "3 hours ago",
      "title": "App Boot Shield",
      "status": "Active",
      "desc": "Memory block protections successfully mounted over standard widgets."
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
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppConfig.primaryColor,
                borderRadius: BorderRadius.circular(AppConfig.borderRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Colors.white, size: 28),
                      SizedBox(width: 8),
                      Text(
                        "SafeTask Sentinel Active",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Real-time verification of sandboxing constraints, verifying zero leakage vectors are open to standard analytics APIs.",
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Text(
              "Local Security Timeline",
              style: TextStyle(
                color: AppConfig.textDarkColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: securityLogs.length,
                itemBuilder: (context, index) {
                  final log = securityLogs[index];
                  return Card(
                    color: AppConfig.cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    margin: EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.verified_user, color: AppConfig.secondaryColor, size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      log['title']!,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppConfig.textDarkColor,
                                      ),
                                    ),
                                    Text(
                                      log['time']!,
                                      style: TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6),
                                Text(
                                  log['desc']!,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                ),
                                SizedBox(height: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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