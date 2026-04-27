import 'package:flutter/material.dart';

/// Reusable neon-styled text input field with animated border glow.
/// Supports character count hints and multi-line text for will input.
class NeonTextField extends StatefulWidget {
  final String label;
  final String hintText;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final Color? borderColor;
  final TextInputType? keyboardType;
  final bool autoFocus;
  final int? maxLines;
  final int? maxLength;
  final String? charCountHint;

  const NeonTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.onChanged,
    this.controller,
    this.borderColor,
    this.keyboardType,
    this.autoFocus = false,
    this.maxLines = 1,
    this.maxLength,
    this.charCountHint,
  });

  @override
  State<NeonTextField> createState() => _NeonTextFieldState();
}

class _NeonTextFieldState extends State<NeonTextField> {
  int _currentLength = 0;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _currentLength = widget.controller!.text.length;
      widget.controller!.addListener(_updateLength);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_updateLength);
    super.dispose();
  }

  void _updateLength() {
    setState(() {
      _currentLength = widget.controller?.text.length ?? 0;
    });
  }

  Color get _borderColor {
    return widget.borderColor ?? const Color(0xFF00FF88);
  }

  @override
  Widget build(BuildContext context) {
    final showCharCount = widget.maxLength != null || widget.charCountHint != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row with optional character count
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _borderColor,
                letterSpacing: 1.5,
              ),
            ),
            if (showCharCount)
              Text(
                widget.charCountHint != null
                    ? widget.charCountHint!
                    : '$_currentLength/${widget.maxLength}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: _currentLength > (widget.maxLength ?? 100)
                      ? const Color(0xFFFF4444)
                      : const Color(0xFF666666),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _borderColor,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _borderColor.withValues(alpha: 0.15),
                blurRadius: 12,
                spreadRadius: 3,
              ),
            ],
          ),
          child: TextField(
            controller: widget.controller,
            onChanged: (value) {
              _updateLength();
              widget.onChanged(value);
            },
            keyboardType: widget.keyboardType,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: const TextStyle(
                fontFamily: 'Inter',
                color: Color(0x66AAAAAA),
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              counterText: '', // Hide default counter, we show custom one
            ),
          ),
        ),
      ],
    );
  }
}
