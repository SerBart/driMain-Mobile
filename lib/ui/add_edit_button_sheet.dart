import 'package:flutter/material.dart';
import 'primary_buttons.dart';

Future<T?> showAddEditBottomSheet<T>({
  required BuildContext context,
  required String title,
  required Widget body,
  required VoidCallback onSubmit,
  String submitLabel = 'Zapisz',
  String cancelLabel = 'Anuluj',
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) {
      final viewInsets = MediaQuery.of(context).viewInsets;
      return Padding(
        padding: EdgeInsets.only(
          bottom: viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (ctx, scroll) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Text(title, style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scroll,
                    child: body,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: cancelLabel,
                        icon: Icons.close,
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        label: submitLabel,
                        icon: Icons.save,
                        onPressed: onSubmit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
