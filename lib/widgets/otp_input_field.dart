import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/constants.dart';

/// Boxed digit-by-digit OTP entry — one box per digit, auto-advancing focus
/// forward on entry and backward on delete. Extracted from the pattern
/// originally inline in `otp_verification_screen.dart` so it can be reused
/// by the password-reset flow without duplicating the focus-chaining logic.
class OtpInputField extends StatefulWidget {
  final int length;
  final ValueChanged<String> onChanged;

  /// When this changes from null to a non-null value, the boxes are
  /// programmatically filled — used for the dev-mode OTP autofill banner.
  final String? prefillCode;

  const OtpInputField({
    super.key,
    this.length = 6,
    required this.onChanged,
    this.prefillCode,
  });

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  late final List<TextEditingController> _controllers =
      List.generate(widget.length, (_) => TextEditingController());
  late final List<FocusNode> _focusNodes = List.generate(widget.length, (_) => FocusNode());

  @override
  void didUpdateWidget(covariant OtpInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final code = widget.prefillCode;
    if (code != null && code != oldWidget.prefillCode) {
      _fill(code);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _fill(String code) {
    for (var i = 0; i < widget.length && i < code.length; i++) {
      _controllers[i].text = code[i];
    }
    widget.onChanged(_controllers.map((c) => c.text).join());
    setState(() {});
  }

  Widget _box(int index) {
    return SizedBox(
      width: 46,
      height: 54,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: const Color(0xFFF5F5F7),
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kPrimaryColor, width: 1.5)),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < widget.length - 1) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          widget.onChanged(_controllers.map((c) => c.text).join());
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, _box),
    );
  }
}
