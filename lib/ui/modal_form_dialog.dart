import 'package:flutter/material.dart';
import 'primary_buttons.dart';

class ModalFormDialog extends StatelessWidget {
  final String title;
  final Widget body;
  final VoidCallback onSubmit;
  final String submitLabel;
  final bool submitLoading;
  final bool dismissible;
  final String cancelLabel;

  const ModalFormDialog({
    super.key,
    required this.title,
    required this.body,
    required this.onSubmit,
    this.submitLabel = 'Zapisz',
    this.submitLoading = false,
    this.dismissible = true,
    this.cancelLabel = 'Anuluj',
  });

  @override
  Widget build(BuildContext context) {
    final content = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: dismissible ? () => Navigator.pop(context) : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(child: SingleChildScrollView(child: body)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: cancelLabel,
                    icon: Icons.arrow_back,
                    onPressed:
                        dismissible ? () => Navigator.pop(context) : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: submitLabel,
                    onPressed: onSubmit,
                    icon: Icons.save,
                    loading: submitLoading,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: content,
    );
  }
}
