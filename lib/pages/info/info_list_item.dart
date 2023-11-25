import 'package:flutter/material.dart';
import 'package:ndn_sensor_app/extensions.dart';


class InfoListItem extends StatelessWidget {
  final String text;
  final Color? textColor;
  final String? labelText;
  final IconData icon;
  final void Function()? onClick;
  final bool labelTop;
  final Color? iconColor;

  const InfoListItem({
    required this.text,
    this.labelText,
    required this.icon,
    this.onClick,
    this.labelTop = false,
    this.iconColor,
    this.textColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => onClick?.call(),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            icon.toIcon(size: 30, color: iconColor),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (labelText != null && labelTop)
                    Text(labelText!, style: textTheme.labelSmall),
                  Text(text, style: textTheme.bodyLarge!.copyWith(color: textColor)),
                  if (labelText != null && !labelTop)
                    Text(labelText!, style: textTheme.labelSmall),
                ],
              ),
            ),
            SizedBox(width: 20),
            if (onClick != null)
              Icons.chevron_right_rounded.toIcon(size: 30),
          ],
        ),
      ),
    );
  }
}