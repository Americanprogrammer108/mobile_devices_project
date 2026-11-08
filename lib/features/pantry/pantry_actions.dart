import 'package:flutter/material.dart';

import '../../models/pantry_item.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pantry_item_popup.dart';
import 'pantry_data_source.dart';

Future<void> addPantryItem(BuildContext context) async {
  final item = await showDialog<PantryItem>(
    context: context,
    builder: (_) => const PantryItemDialog(),
  );
  if (item == null || !context.mounted) return;
  await _run(
    context,
    () => pantryDataSource.addItem(item),
    '${item.name} added to pantry.',
  );
}

Future<void> editPantryItem(BuildContext context, PantryItem exisiting) async {
  final item = await showDialog<PantryItem>(
    context: context,
    builder: (_) => PantryItemDialog(exisiting: exisiting),
  );
  if (item == null || !context.mounted) return;
  await _run(
    context,
    () => pantryDataSource.updateItem(item),
    '${item.name} updated',
  );
}

Future<void> deletePantryItem(BuildContext context, PantryItem item) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete pantry item?'),
      content: Text('Remove "${item.name}" from your pantry?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.iconRed),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  await _run(
    context,
    () => pantryDataSource.deleteItem(item.id),
    '${item.name} deleted',
  );
}

Future<void> _run(
  BuildContext context,
  Future<void> Function() action,
  String successMessage,
) async {
  String message = successMessage;
  try {
    await action();
  } catch (error) {
    message = 'Something went wrong: $error';
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(15, 0, 16, 70),
      ),
    );
}
