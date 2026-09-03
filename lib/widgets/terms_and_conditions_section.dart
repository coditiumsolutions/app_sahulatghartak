import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../utils/motion.dart';

class TermsAndConditionsSection extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String termsTitle;
  final String termsBody;
  final String termsClosing;

  const TermsAndConditionsSection({
    super.key,
    required this.value,
    required this.onChanged,
    required this.termsTitle,
    required this.termsBody,
    required this.termsClosing,
  });

  @override
  State<TermsAndConditionsSection> createState() => _TermsAndConditionsSectionState();
}

class _TermsAndConditionsSectionState extends State<TermsAndConditionsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Terms & Conditions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: kQuickAnimDuration,
                      curve: kStandardCurve,
                      child: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            widget.termsTitle,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.termsBody,
                            style: const TextStyle(fontSize: 13, height: 1.6, color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.termsClosing,
                            style: const TextStyle(fontSize: 13, height: 1.5, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: kQuickAnimDuration,
              sizeCurve: kStandardCurve,
            ),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => widget.onChanged(!widget.value),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 18, 12),
                child: Row(
                  children: [
                    Checkbox(
                      value: widget.value,
                      activeColor: kPrimaryColor,
                      onChanged: (v) => widget.onChanged(v ?? false),
                    ),
                    const Expanded(
                      child: Text('I agree to the Terms and Conditions', style: TextStyle(fontSize: 14, color: Colors.black87)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
