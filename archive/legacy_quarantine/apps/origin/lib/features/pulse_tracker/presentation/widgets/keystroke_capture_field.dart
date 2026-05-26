import 'package:flutter/material.dart';
import 'package:origin/core/theme/app_theme.dart';
import 'package:origin/core/utils/keystroke_tracker.dart';

/// A simple keystroke-capture text field that tracks typing dynamics.
///
/// Wraps a [TextField] and feeds every text change into a [KeystrokeTracker]
/// so the caller can later analyze inter-key timing, backspace patterns, etc.
class KeystrokeCaptureField extends StatefulWidget {
  /// Callback invoked whenever the tracked text changes.
  final ValueChanged<String>? onChange;

  /// Placeholder text shown when the field is empty.
  final String hintText;

  /// Controller for external text management (optional).
  final TextEditingController? controller;

  /// Focus node for external focus management (optional).
  final FocusNode? focusNode;

  /// Number of lines for multi-line mode.
  final int maxLines;

  const KeystrokeCaptureField({
    super.key,
    this.onChange,
    this.hintText = 'Start typing to capture your keystroke dynamics...',
    this.controller,
    this.focusNode,
    this.maxLines = 6,
  });

  @override
  State<KeystrokeCaptureField> createState() =>
      _KeystrokeCaptureFieldState();
}

class _KeystrokeCaptureFieldState
    extends State<KeystrokeCaptureField> {
  late final KeystrokeTracker _tracker;
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  String _prevText = '';

  @override
  void initState() {
    super.initState();
    _tracker = KeystrokeTracker();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _prevText = _controller.text;
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final currentText = _controller.text;
    _tracker.onTextChange(
      oldText: _prevText,
      newText: currentText,
    );
    _prevText = currentText;
    widget.onChange?.call(currentText);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      maxLines: widget.maxLines,
      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
            color: AppColor.textPrimary,
          ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        filled: true,
        fillColor: const Color(0xFF1A1A25),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColor.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColor.neonGreen, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
