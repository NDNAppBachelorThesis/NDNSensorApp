import 'package:flutter/material.dart';

///
/// A TextBox where you can also click the text to toggle it
class TextCheckbox extends StatelessWidget {
  final bool value;
  final Widget text;
  final void Function(bool value) onChanged;

  const TextCheckbox({
    required this.value,
    required this.text,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
        GestureDetector(child: text, onTap: () => onChanged(!value)),
      ],
    );
  }
}
