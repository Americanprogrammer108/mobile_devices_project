import 'package:flutter/material.dart';

import '../models/pantry_item.dart';
import '../services/pantry_category_mapper.dart';
import '../utils/expiry_utils.dart';

class PantryItemDialog extends StatefulWidget {
  const PantryItemDialog({super.key, this.exisiting});

  final PantryItem? exisiting;

  @override
  State<PantryItemDialog> createState() => _PantryItemDialogState();
}

class _PantryItemDialogState extends State<PantryItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _quantity;
  late final TextEditingController _unit;
  late String _category;
  late List<String> _categories; 
  DateTime? _expiration;

  @override
  void initState() {
    super.initState();
    final item = widget.exisiting;
    _name = TextEditingController(text: item?.name ?? '');
    _quantity = TextEditingController(text: '${item?.quantity ?? 1}');
    _unit = TextEditingController(text: item?.unit ?? '');
    _category = item?.category ?? 'Other';
    _categories = [
      ...PantryCategoryMapper.categories,
      if (!PantryCategoryMapper.categories.contains(_category)) _category,
    ];
    _expiration = item?.expirationDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _unit.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, 
      initialDate: _expiration ?? DateTime.now(), 
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && mounted) {
      setState(() {
        _expiration = picked;
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final exisiting = widget.exisiting;
    Navigator.pop(
      context,
      PantryItem(
        id: exisiting?.id ?? '',
        name: _name.text.trim(), 
        category: _category, 
        quantity: int.parse(_quantity.text.trim()), 
        unit: _unit.text.trim(),
        expirationDate: _expiration,
        createdAt: exisiting?.createdAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expiration = _expiration;

    return AlertDialog(
      title: Text(widget.exisiting == null ? 'Add item': 'Edit item'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Item name'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Enter an item' : null, 
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantity,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Quantity'),
                        validator: (value) {
                          final quantity = int.tryParse(value?.trim() ?? '');
                          return quantity == null || quantity <= 0 ? 'Whole number' : null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12,),
                    Expanded(
                      child: TextFormField(
                        controller: _unit,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          hintText: 'L, g, pack',
                        ),
                      ),
                    )
                  ],
                ),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    for (final category in _categories)
                    DropdownMenuItem(value: category, child: Text(category)),
                  ], 
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _category = value;
                      });
                    }
                  }
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    expiration == null ? 'No expiration date' : 'Exp: ${formatDate(expiration)}',
                  ),
                  trailing: Row (
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Choose expiration date',
                        icon: const Icon(Icons.calendar_month),
                        onPressed: _pickDate,
                      ),
                      if (expiration != null) 
                      IconButton(
                        tooltip: 'Clear expiration date',
                        onPressed: () => setState(() {
                          _expiration = null;
                        }),
                        icon: const Icon(Icons.clear),
                      )
                    ],
                  )
                )
              ],
            ), 
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}