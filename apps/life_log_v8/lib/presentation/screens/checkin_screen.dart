import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../presentation/providers/checkin_provider.dart';
import '../../domain/domain.dart';

class CheckinScreen extends ConsumerStatefulWidget {
  const CheckinScreen({super.key});

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  int _selectedEnergy = 3;
  String? _selectedMood;
  String? _selectedFocus;

  static const _moods = ['😡', '😢', '😐', '🙂', '😄'];
  static const _focusModes = ['딥워크', '메일', '회의', '학습'];
  static const _focusLabels = ['DeepWork', 'Email', 'Meeting', 'Study'];

  @override
  Widget build(BuildContext context) {
    final checkinState = ref.watch(checkinProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Deep abyss gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F2027),
                  Color(0xFF203A43),
                  Color(0xFF2C5364),
                ],
              ),
            ),
          ),
          // Glassmorphism card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Heading
                        Text(
                          "Today's Check-in",
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Energy Stars
                        Text(
                          "Energy Level",
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            5,
                            (index) => IconButton(
                              icon: Icon(
                                Icons.star,
                                color:
                                    index < _selectedEnergy
                                        ? Colors.amber
                                        : Colors.grey,
                                size: 36,
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedEnergy = index + 1;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Mood Emojis
                        Text(
                          "Mood",
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _moods.length,
                            (index) => InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedMood = _moods[index];
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Text(
                                  _moods[index],
                                  style: TextStyle(
                                    fontSize:
                                        _selectedMood == _moods[index]
                                            ? 36
                                            : 28,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Focus Chips
                        Text(
                          "Focus Mode",
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(
                            _focusModes.length,
                            (index) => ActionChip(
                              label: Text(
                                _focusModes[index],
                                style: GoogleFonts.inter(
                                  color:
                                      _selectedFocus == _focusLabels[index]
                                          ? Colors.white
                                          : Colors.black87,
                                ),
                              ),
                              backgroundColor:
                                  _selectedFocus == _focusLabels[index]
                                      ? Colors.green
                                      : Colors.grey[200],
                              onPressed: () {
                                setState(() {
                                  _selectedFocus = _focusLabels[index];
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        ElevatedButton(
                          onPressed:
                              checkinState.state == CheckinState.loading
                                  ? null
                                  : () => _onSubmit(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: Text(
                            'Submit',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onSubmit() {
    final data = CheckinData(
      energyLevel: _selectedEnergy,
      mood: _selectedMood ?? '',
      focusMode: _selectedFocus ?? '',
    );
    ref.read(checkinProvider.notifier).submitCheckin(data);
  }
}
