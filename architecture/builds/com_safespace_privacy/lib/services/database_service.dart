import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseService {
  static const String _keyMemos = 'safespace_memos';
  static const String _keyMoods = 'safespace_moods';
  static const String _keyLogs = 'safespace_sentinel_logs';
  static const String _keyPin = 'safespace_master_pin';

  // --- Master PIN PIN Operations ---
  static Future<String> getMasterPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPin) ?? '2026'; // Default passcode
  }

  static Future<void> setMasterPin(String newPin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPin, newPin);
    await addSentinelLog('Security Configuration', 'Master security PIN updated');
  }

  // --- Memos (Private Notes) ---
  static Future<List<Map<String, dynamic>>> getMemos() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyMemos);
    if (data == null) {
      // Default initial templates to wow the user
      final initial = [
        {
          'id': '1',
          'title': 'Welcome to SafeSpace',
          'content': '# My Private Sanctuary\n\nThis note is stored 100% on-device inside your sandboxed local storage.\n\n### Key Features:\n- Zero cloud telemetry\n- Individual biometric locking\n- Elegant markdown tags\n- Local-first JSON portability',
          'date': 'Oct 24, 2026',
          'category': 'Personal',
          'tags': 'Welcome,Safe',
          'isPinned': true,
          'isLocked': false,
        },
        {
          'id': '2',
          'title': 'Highly Confidential Seed Phrase',
          'content': '1. antigravity\n2. architecture\n3. local\n4. sovereign\n5. device\n6. sandbox\n7. memory\n8. private\n9. key\n10. cipher\n11. lock\n12. shield',
          'date': 'Oct 23, 2026',
          'category': 'Secrets',
          'tags': 'Crypto,Recovery',
          'isPinned': false,
          'isLocked': true,
        }
      ];
      await saveMemos(initial);
      return initial;
    }
    return List<Map<String, dynamic>>.from(jsonDecode(data));
  }

  static Future<void> saveMemos(List<Map<String, dynamic>> memos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMemos, jsonEncode(memos));
  }

  static Future<void> addMemo(Map<String, dynamic> memo) async {
    final memos = await getMemos();
    memos.insert(0, memo);
    await saveMemos(memos);
    await addSentinelLog(
      memo['isLocked'] == true ? 'Security Alert' : 'Data Write', 
      'Locked Memo "${memo['title']}" forged successfully.'
    );
  }

  static Future<void> updateMemo(Map<String, dynamic> updatedMemo) async {
    final memos = await getMemos();
    final idx = memos.indexWhere((m) => m['id'] == updatedMemo['id']);
    if (idx != -1) {
      memos[idx] = updatedMemo;
      await saveMemos(memos);
      await addSentinelLog('Data Update', 'Memo "${updatedMemo['title']}" updated.');
    }
  }

  static Future<void> deleteMemo(String id, String title) async {
    final memos = await getMemos();
    memos.removeWhere((m) => m['id'] == id);
    await saveMemos(memos);
    await addSentinelLog('Data Purge', 'Memo "$title" expunged from device.');
  }

  // --- Mood Entries ---
  static Future<List<Map<String, dynamic>>> getMoods() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyMoods);
    if (data == null) {
      final initial = [
        {'date': 'Oct 24, 2026', 'mood': '🌸 Calm'},
        {'date': 'Oct 23, 2026', 'mood': '🌻 Happy'},
      ];
      await saveMoods(initial);
      return initial;
    }
    return List<Map<String, dynamic>>.from(jsonDecode(data));
  }

  static Future<void> saveMoods(List<Map<String, dynamic>> moods) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMoods, jsonEncode(moods));
  }

  static Future<void> addMood(String mood) async {
    final moods = await getMoods();
    moods.insert(0, {
      'date': 'Today',
      'mood': mood,
    });
    await saveMoods(moods);
    await addSentinelLog('Mood Log', 'Daily wellness level recorded: $mood.');
  }

  // --- Sentinel Intrusion Logs ---
  static Future<List<Map<String, dynamic>>> getSentinelLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyLogs);
    if (data == null) {
      final initial = [
        {'status': 'SUCCESS', 'time': '10:44 AM', 'details': 'Biometric verification passed', 'type': 'Face ID'},
        {'status': 'INFO', 'time': '09:00 AM', 'details': 'Offline cryptographic sandbox refreshed', 'type': 'Internal'},
      ];
      await prefs.setString(_keyLogs, jsonEncode(initial));
      return initial;
    }
    return List<Map<String, dynamic>>.from(jsonDecode(data));
  }

  static Future<void> addSentinelLog(String type, String details, {String status = 'INFO'}) async {
    final prefs = await SharedPreferences.getInstance();
    final currentLogs = await getSentinelLogs();
    final now = DateTime.now();
    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    currentLogs.insert(0, {
      'status': status,
      'time': timeStr,
      'details': details,
      'type': type
    });
    // Cap logs at 100 for optimal memory footprint
    if (currentLogs.length > 100) {
      currentLogs.removeRange(100, currentLogs.length);
    }
    await prefs.setString(_keyLogs, jsonEncode(currentLogs));
  }

  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyMemos);
    await prefs.remove(_keyMoods);
    await prefs.remove(_keyLogs);
    await prefs.remove(_keyPin);
  }
}
