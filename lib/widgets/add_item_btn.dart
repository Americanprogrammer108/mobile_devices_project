import 'package:flutter/material.dart';

/**
 * The green "+ Add Item" button used on the Home and Pantry screens/
 * Its colour and size come from the app theme
 *////
class AddItemBtn extends StatelessWidget {
  const AddItemBtn({super.key, required this.onPressed});

  /// What happens when the button is tapped
  final VoidCallback onPressed;
  
  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add),
      label: const Text('Add Item'),
    );
  }
}
