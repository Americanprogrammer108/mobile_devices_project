import 'package:flutter/material.dart';

import '../../models/pantry_item.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pantry_item_popup.dart';
import 'pantry_data_source.dart';


/**
 * Opens the app dialog (pop-up) and saves the new item. Shows a snackbar
 * when it is done.
 *////
Future<void> addPantryItem(BuildContext context) async {
  final item = await showDialog<PantryItem>(
    context: context,
    builder: (_) => const PantryItemDialog(),
  );
  
  //Stop if the user pressed Cancel or left the screen
  if (item == null || !context.mounted) return;
  await _run(
    context,
    () => pantryDataSource.addItem(item),
    '${item.name} added to pantry.',
  );
}

/**
 * Opens the dialog filled with the item's details and save the changes.
 * Shows a snackbar when it's gone
 *////
Future<void> editPantryItem(BuildContext context, PantryItem exisiting) async {
  final item = await showDialog<PantryItem>(
    context: context,
    builder: (_) => PantryItemDialog(exisiting: exisiting),
  );

  //Stop if the user pressed Cancel or left the screen
  if (item == null || !context.mounted) return;
  await _run(
    context,
    () => pantryDataSource.updateItem(item),
    '${item.name} updated',
  );
}

/**
 * Asks the user to confirm, then deletes the item. Shows a snackbar
 * when its done
 *////
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

  // Stop unless the user pressed delete
  if (confirmed != true || !context.mounted) return;
  await _run(
    context,
    () => pantryDataSource.deleteItem(item.id),
    '${item.name} deleted',
  );
}

/**
 * Runs a save or delete, then shows a snackbar with the result. Shows
 * an error message instead if something goes wrong.
 */
///
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

  //The screen may have closed while saving
  if (!context.mounted) return;

  //Remove any old snackbar, then show the new one 
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
