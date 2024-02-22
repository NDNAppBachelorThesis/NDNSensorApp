import 'package:flutter/material.dart';

///
/// A text widget, which has a small label above or below it
class LabeledText extends StatelessWidget {
  final String text;
  final String labelText;
  final Icon? icon;
  final TextStyle? textStyle;
  final TextStyle? labelStyle;
  final bool _scrollable;
  final bool labelBottom;
  final double iconPadding;

  const LabeledText({
    required this.labelText,
    required this.text,
    this.icon,
    this.textStyle,
    this.labelStyle,
    this.labelBottom = false,
    this.iconPadding = 10,
    Key? key,
  })  : _scrollable = false,
        super(key: key);

  const LabeledText.bottom({
    required this.labelText,
    required this.text,
    this.icon,
    this.textStyle,
    this.labelStyle,
    this.iconPadding = 10,
    Key? key,
  })  : _scrollable = false,
        labelBottom = true,
        super(key: key);

  const LabeledText.scrollable({
    required this.labelText,
    required this.text,
    this.icon,
    this.textStyle,
    this.labelStyle,
    this.labelBottom = false,
    this.iconPadding = 10,
    Key? key,
  })  : _scrollable = true,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;

    var usedLabelStyle = labelStyle ?? textTheme.labelSmall;
    var usedTextStyle = textStyle ?? textTheme.bodyMedium;

    var textWidget = _scrollable
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(text, style: usedTextStyle),
          )
        : Text(text, style: usedTextStyle);

    var labelTextWidget = Text(labelText, style: usedLabelStyle);

    return Row(
      children: [
        if (icon != null) ...[
          icon!,
          SizedBox(width: iconPadding),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!labelBottom) labelTextWidget,
              textWidget,
              if (labelBottom) labelTextWidget,
            ],
          ),
        )
      ],
    );
  }
}
