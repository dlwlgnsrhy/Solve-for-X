import 'dart:async';
import 'package:flutter/material.dart';
import '../config/app_config.dart';

class ZenFocusPage extends StatefulWidget {
  const ZenFocusPage({Key? key}) : super(key: key);
  @override
  State<ZenFocusPage> createState() => _ZenFocusPageState();
}

class _ZenFocusPageState extends State<ZenFocusPage> {
  Timer? _timer;
  int _totalSeconds = 1200;
  int _secondsRemaining = 1200;
  bool _isRunning = false;
  final List<String> _mindfulLogs = [];

  void _startTimer() {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        _saveRecord();
        setState(() {
          _isRunning = false;
          _secondsRemaining = _totalSeconds;
        });
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer(int seconds) {
    _timer?.cancel();
    setState(() {
      _totalSeconds = seconds;
      _secondsRemaining = seconds;
      _isRunning = false;
    });
  }

  void _saveRecord() {
    final now = DateTime.now();
    final stamp = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    setState(() {
      _mindfulLogs.insert(0, "Spent ${_totalSeconds ~/ 60}m practicing mindful breathing at $stamp");
    });
  }

  String _formatTime(int total) {
    final min = total ~/ 60;
    final sec = total % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _secondsRemaining / _totalSeconds;
    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Deep Offline Breath",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppConfig.textDarkColor),
            ),
            const SizedBox(height: 4),
            const Text(
              "Breathe softly. Your local environment isolates biometric patterns completely.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppConfig.textLightColor),
            ),
            const SizedBox(height: 24),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200, 
                  height: 200,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: AppConfig.primaryColor.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppConfig.primaryColor),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(_secondsRemaining),
                      style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: AppConfig.textDarkColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isRunning ? "INHALE / EXHALE" : "SOFT REST",
                      style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                        color: AppConfig.secondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConfig.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    elevation: 0,
                  ),
                  onPressed: _isRunning ? _pauseTimer : _startTimer,
                  child: Text(
                    _isRunning ? "Pause Breath" : "Start Zen",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => _resetTimer(1200),
                  child: const Text("20m Cycle", style: TextStyle(color: AppConfig.textDarkColor)),
                ),
                TextButton(
                  onPressed: () => _resetTimer(300),
                  child: const Text("5m Break", style: TextStyle(color: AppConfig.secondaryColor)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Today's Peace Metrics",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConfig.textDarkColor),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _mindfulLogs.isEmpty
                  ? Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppConfig.cardColor,
                        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                      ),
                      child: const Text(
                        "No zen states logged yet. Start a countdown session above.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppConfig.textLightColor, fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _mindfulLogs.length,
                      itemBuilder: (context, idx) {
                        return Card(
                          color: AppConfig.cardColor,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            dense: true,
                            leading: const Icon(Icons.favorite_border, color: AppConfig.secondaryColor),
                            title: Text(_mindfulLogs[idx], style: const TextStyle(fontSize: 12)),
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
}