import 'package:flutter/material.dart';

Future<T?> showMaterialModalBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext context) builder,
  bool showDragHandle = true,
}) async {
  var colorScheme = Theme.of(context).colorScheme;

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(left: 30, right: 30, bottom: 20, top: 25 - (showDragHandle ? 0 : 20)),
      child: IntrinsicHeight(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The drag handle
            if (showDragHandle) Center(
              child: Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                  border: Border.all(color: Colors.transparent),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 30),
              child: builder(context),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    ),
  );
}