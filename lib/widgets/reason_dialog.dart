import 'package:flutter/material.dart';

import 'themed_dropdown.dart';

const _brandDark = Color(0xFF0A4FA8);
const _otherReasonValue = '__other__';

/// A confirm dialog requiring a reason before proceeding: a dropdown of
/// preset [reasons] plus an "Other" option that reveals a free-text field.
/// Same visual chrome as [showConfirmDialog], but returns the chosen reason
/// string (or null if dismissed) instead of a bare bool.
Future<String?> showReasonDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required List<String> reasons,
  String cancelLabel = 'Back',
  IconData icon = Icons.cancel_outlined,
  Color color = Colors.red,
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => _ReasonDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      reasons: reasons,
      icon: icon,
      color: color,
    ),
  );
}

class _ReasonDialog extends StatefulWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final List<String> reasons;
  final IconData icon;
  final Color color;

  const _ReasonDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.reasons,
    required this.icon,
    required this.color,
  });

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  String? _selected;
  final _otherController = TextEditingController();

  bool get _isOther => _selected == _otherReasonValue;

  bool get _canConfirm =>
      _selected != null && (!_isOther || _otherController.text.trim().isNotEmpty);

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_canConfirm) return;
    final reason = _isOther ? _otherController.text.trim() : _selected!;
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: _brandDark.withValues(alpha: 0.22), blurRadius: 28, offset: const Offset(0, 12))],
          ),
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: widget.color.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(widget.icon, color: widget.color, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A2233), letterSpacing: -0.2),
              ),
              const SizedBox(height: 8),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: Colors.grey[600], height: 1.4, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Reason',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 6),
              ThemedDropdownField<String>(
                value: _selected,
                hint: 'Select a reason',
                accentColor: widget.color,
                items: [
                  ...widget.reasons.map((r) => ThemedDropdownItem(value: r, label: r)),
                  const ThemedDropdownItem(value: _otherReasonValue, label: 'Other'),
                ],
                onChanged: (v) => setState(() => _selected = v),
              ),
              if (_isOther) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _otherController,
                  autofocus: true,
                  minLines: 2,
                  maxLines: 3,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Tell us more',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w500),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF6F8FC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: widget.color, width: 1.5)),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(widget.cancelLabel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.color,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: widget.color.withValues(alpha: 0.35),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _canConfirm ? _confirm : null,
                      child: Text(widget.confirmLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
