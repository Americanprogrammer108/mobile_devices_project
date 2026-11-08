import 'package:flutter/material.dart';

class AddItemBtn extends StatelessWidget {
  const AddItemBtn({super.key, required this.onPressed});

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
