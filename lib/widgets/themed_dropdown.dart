import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

const _brandBlue = Color(0xFF016EE3);
const _itemTextStyle = TextStyle(color: Color(0xFF1A2233), fontSize: 14.5, fontWeight: FontWeight.w600);

/// A single dropdown option: [label] is what's shown (and measured to size
/// the popup), [value] is what's returned via [ThemedDropdownField.onChanged].
class ThemedDropdownItem<T> {
  final T value;
  final String label;

  const ThemedDropdownItem({required this.value, required this.label});
}

/// A [DropdownButtonFormField2] pre-styled to match the app's branded
/// dialogs/cards: a soft filled field, a tinted chevron, and — unlike stock
/// Flutter's [DropdownButtonFormField], whose popup always matches the
/// field's full width — a popup that hugs the width of its longest option
/// (capped so it never overflows the screen), wrapping long labels onto up
/// to 2 lines instead of stretching edge-to-edge or truncating.
class ThemedDropdownField<T> extends StatefulWidget {
  final T? value;
  final String? hint;
  final List<ThemedDropdownItem<T>> items;
  final ValueChanged<T?> onChanged;
  final FormFieldValidator<T>? validator;
  final Color accentColor;
  final Color fillColor;

  const ThemedDropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.validator,
    this.accentColor = _brandBlue,
    this.fillColor = const Color(0xFFF6F8FC),
  });

  @override
  State<ThemedDropdownField<T>> createState() => _ThemedDropdownFieldState<T>();
}

class _ThemedDropdownFieldState<T> extends State<ThemedDropdownField<T>> {
  late final ValueNotifier<T?> _selected = ValueNotifier(widget.value);

  @override
  void didUpdateWidget(covariant ThemedDropdownField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) _selected.value = widget.value;
  }

  @override
  void dispose() {
    _selected.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menuWidth = _measureMenuWidth(context, widget.items.map((e) => e.label));

    return DropdownButtonFormField2<T>(
      valueListenable: _selected,
      onChanged: (v) {
        _selected.value = v;
        widget.onChanged(v);
      },
      validator: widget.validator,
      isExpanded: true,
      isDense: false,
      style: _itemTextStyle,
      decoration: themedDropdownDecoration(hint: widget.hint, accentColor: widget.accentColor, fillColor: widget.fillColor),
      // DropdownButtonFormField2 gives the button zero built-in padding when
      // paired with a form decoration, which squashes the selected-value
      // text against the field edges; restore a little breathing room here.
      // isDense must be false too — dense mode fixes the button to a
      // ~24px-tall SizedBox sized only from font/icon size (ignoring this
      // padding), which clips the text instead of just squeezing it. Kept
      // small since decoration's contentPadding also applies on top of this.
      buttonStyleData: const FormFieldButtonStyleData(padding: EdgeInsets.symmetric(vertical: 2)),
      iconStyleData: IconStyleData(icon: Icon(Icons.keyboard_arrow_down_rounded, color: widget.accentColor)),
      dropdownStyleData: DropdownStyleData(
        width: menuWidth,
        maxHeight: 320,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      ),
      menuItemStyleData: const MenuItemStyleData(padding: EdgeInsets.symmetric(horizontal: 16)),
      items: widget.items
          .map((item) => DropdownItem<T>(
                value: item.value,
                intrinsicHeight: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(item.label, style: _itemTextStyle, softWrap: true, maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              ))
          .toList(),
    );
  }
}

/// Sizes the popup to the widest label (plus padding for the item's own
/// horizontal inset and any text overflow slack), capped between a sensible
/// minimum and most of the screen width so a single short option doesn't
/// render a barely-there sliver and a long one never overflows.
double _measureMenuWidth(BuildContext context, Iterable<String> labels) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  double widest = 0;
  for (final label in labels) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: _itemTextStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    if (painter.width > widest) widest = painter.width;
  }
  const horizontalPadding = 16 * 2 + 24; // item padding + breathing room
  return (widest + horizontalPadding).clamp(180.0, screenWidth * 0.78);
}

/// Field decoration matching [ThemedDropdownField]'s look, for call sites
/// that need the raw [DropdownButtonFormField2] (e.g. inside a
/// [StatefulBuilder] dialog where a wrapper widget is inconvenient).
InputDecoration themedDropdownDecoration({
  String? hint,
  Color accentColor = _brandBlue,
  Color fillColor = const Color(0xFFF6F8FC),
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w500),
    isDense: true,
    filled: true,
    fillColor: fillColor,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: accentColor, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent)),
  );
}
