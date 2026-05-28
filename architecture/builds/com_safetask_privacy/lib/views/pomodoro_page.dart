import 'dart:async';
import 'package:flutter/material.dart';
import '../config/app_config.dart';

class PomodoroPage extends StatefulWidget {
  @override
  _PomodoroPageState createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> {
  Timer? _timer;
  int _totalSeconds = 1500;
  int _secondsRemaining = 1500;
  bool _isRunning = false;
  final List<String> _localRecords = [];

  void _startTimer() {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
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
    final timestamp = DateTime.now().toLocal().toString().substring(11, 16);
    setState(() {
      _localRecords.insert(0, "Completed a Focus block [${_totalSeconds ~/ 60}m] at $timestamp");
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
            Text(
              "Deep Offline Focus",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppConfig.textDarkColor,
              ),
            ),
            SizedBox(height: 6),
            Text(
              "No data is transferred; timestamps remain strictly in local memory.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            SizedBox(height: 32),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: AppConfig.primaryColor.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(AppConfig.primaryColor),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(_secondsRemaining),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppConfig.textDarkColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _isRunning ? "ACTIVE TRACKING" : "TIMER PAUSED",
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                        color: _isRunning ? AppConfig.secondaryColor : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConfig.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: _isRunning ? _pauseTimer : _startTimer,
                  child: Text(
                    _isRunning ? "Pause Session" : "Start Focus",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 12),
                TextButton(
                  onPressed: () => _resetTimer(1500),
                  child: Text("Reset 25m", style: TextStyle(color: AppConfig.textDarkColor)),
                ),
                TextButton(
                  onPressed: () => _resetTimer(300),
                  child: Text("5m Break", style: TextStyle(color: AppConfig.secondaryColor)),
                ),
              ],
            ),
            SizedBox(height: 32),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Local Focus Session Logs",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConfig.textDarkColor,
                ),
              ),
            ),
            SizedBox(height: 12),
            Expanded(
              child: _localRecords.isEmpty
                  ? Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppConfig.cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        "No dynamic logs written yet for this offline session.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _localRecords.length,
                      itemBuilder: (context, idx) {
                        return Card(
                          color: AppConfig.cardColor,
                          margin: EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            dense: true,
                            leading: Icon(Icons.history_toggle_off, color: AppConfig.secondaryColor),
                            title: Text(_localRecords[idx], style: TextStyle(fontSize: 12)),
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