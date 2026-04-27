import 'package:flutter/material.dart';

/// EULA agreement checkbox widget with proper state management.
/// 
/// This widget manages its own checked state and calls onChecked
/// whenever the state changes. The parent widget is responsible for
/// triggering any UI updates (e.g., enabling the submit button).
class EulaCheckbox extends StatefulWidget {
  /// Callback invoked when the checkbox state changes.
  final ValueChanged<bool> onChecked;

  /// Optional callback to show the EULA document.
  final VoidCallback? onViewEula;

  /// Initial checked state. Defaults to false.
  final bool initialValue;

  const EulaCheckbox({
    super.key,
    required this.onChecked,
    this.onViewEula,
    this.initialValue = false,
  });

  @override
  State<EulaCheckbox> createState() => _EulaCheckboxState();
}

class _EulaCheckboxState extends State<EulaCheckbox> {
  bool _isChecked = false;

  @override
  void initState() {
    super.initState();
    _isChecked = widget.initialValue;
  }

  @override
  void didUpdateWidget(EulaCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync with parent's state if initialValue changes
    if (widget.initialValue != oldWidget.initialValue) {
      setState(() {
        _isChecked = widget.initialValue;
      });
    }
  }

  void _toggle() {
    setState(() {
      _isChecked = !_isChecked;
    });
    widget.onChecked(_isChecked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _isChecked,
                onChanged: (value) => _toggle(),
                activeColor: const Color(0xFF00FF88),
                side: const BorderSide(
                  color: Color(0x9900DDFF),
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (widget.onViewEula != null) widget.onViewEula!();
                },
                child: Text(
                  '이용약관 및 EULA 동의',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: const Color(0xFF00DDFF),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
        // Consumer-facing note: explains what agreeing means
        Padding(
          padding: const EdgeInsets.only(top: 4, left: 32),
          child: Text(
            'EULA에 동의해야 카드를 생성할 수 있습니다.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: const Color(0xFF666666),
            ),
          ),
        ),
      ],
    );
  }
}
