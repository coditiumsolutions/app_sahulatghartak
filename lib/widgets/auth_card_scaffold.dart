import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Shared visual shell for auth screens (login/registration): a colored
/// header with decorative circles, an avatar badge straddling a white
/// rounded-top card, and a back button.
class AuthCardScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData avatarIcon;
  final Widget child;
  final Color accentColor;

  const AuthCardScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.avatarIcon = Icons.person,
    this.accentColor = kPrimaryColor,
  });

  static const double avatarRadius = 46;
  static const double headerHeight = 85;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final effectiveHeaderHeight = headerHeight + (topInset - 20).clamp(0, double.infinity);
    return Scaffold(
      backgroundColor: accentColor,
      body: Stack(
        children: [
          Positioned(
            top: -70,
            left: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          Positioned(
            top: -30,
            right: -60,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
          Column(
            children: [
              SizedBox(height: effectiveHeaderHeight),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(24, avatarRadius + 24, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.black.withValues(alpha: 0.5)),
                          ),
                          const SizedBox(height: 32),
                          child,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: effectiveHeaderHeight - avatarRadius,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: avatarRadius * 2,
                height: avatarRadius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                padding: const EdgeInsets.all(6),
                child: CircleAvatar(
                  backgroundColor: accentColor,
                  child: Icon(avatarIcon, color: Colors.white, size: 42),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration authFieldDecoration({required String hint, Widget? suffixIcon}) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFF5F5F7),
    suffixIcon: suffixIcon,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kPrimaryColor, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent)),
  );
}

Widget authFieldLabel(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
  );
}

class GenderSelector extends FormField<String> {
  GenderSelector({
    super.key,
    String? initialValue,
    required ValueChanged<String> onChanged,
    FormFieldValidator<String>? validator,
  }) : super(
          initialValue: initialValue,
          validator: validator,
          builder: (state) {
            const labels = ['Male', 'Female', 'Other'];
            const icons = [Icons.male_rounded, Icons.female_rounded, Icons.transgender_rounded];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    for (var i = 0; i < labels.length; i++) ...[
                      if (i != 0) const SizedBox(width: 12),
                      Expanded(
                        child: _GenderOption(
                          label: labels[i],
                          icon: icons[i],
                          selected: state.value == labels[i],
                          hasError: state.hasError,
                          onTap: () {
                            state.didChange(labels[i]);
                            onChanged(labels[i]);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(state.errorText!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ),
              ],
            );
          },
        );
}

class _GenderOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool hasError;
  final VoidCallback onTap;

  const _GenderOption({required this.label, required this.icon, required this.selected, required this.hasError, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? kPrimaryColor : const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? kPrimaryColor : (hasError ? Colors.redAccent.withValues(alpha: 0.6) : Colors.transparent)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? Colors.white : Colors.black45, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  final Color color;

  const AuthPrimaryButton({super.key, required this.label, required this.isLoading, required this.onPressed, this.color = kPrimaryColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade400,
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
