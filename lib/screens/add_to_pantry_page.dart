import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/expiry_reminder_time.dart';

class AddToPantryPage extends StatefulWidget {
  final String barcode;
  final String productName;
  final String brand;
  final String packageSize;
  final String imageUrl;
  final String suggestedCategory;

  const AddToPantryPage({
    super.key,
    required this.barcode,
    required this.productName,
    required this.brand,
    required this.packageSize,
    required this.imageUrl,
    this.suggestedCategory = 'Other',
  });

  @override
  State<AddToPantryPage> createState() => _AddToPantryPageState();
}

class _AddToPantryPageState extends State<AddToPantryPage> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');

  final _categories = [
    'Dairy',
    'Produce',
    'Meat & Seafood',
    'Frozen',
    'Beverages',
    'Bakery',
    'Pantry Staples',
    'Other',
  ];

  late String _category;

  @override
  void initState() {
    super.initState();

    _category = _categories.contains(widget.suggestedCategory)
        ? widget.suggestedCategory
        : 'Other';
  }

  DateTime? _expirationDate;
  bool _saving = false;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _selectExpirationDate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selected != null && mounted) {
      setState(() => _expirationDate = selected);
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate() || _saving) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please sign in first.')));
      return;
    }

    setState(() => _saving = true);

    try {
      debugPrint('Expiration date: $_expirationDate');

      final remindAt = calculateExpiryReminder(_expirationDate);

      debugPrint('Calculated reminder: $remindAt');
      debugPrint('Saving pantry item with remindAt=$remindAt');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('items')
          .add({
            'name': widget.productName,
            'count': int.parse(_quantityController.text.trim()),
            'category': _category,
            'expirationDate': _expirationDate == null
                ? null
                : Timestamp.fromDate(_expirationDate!),

            // Expiration notification
            'remindAt': remindAt == null ? null : Timestamp.fromDate(remindAt),

            'barcode': widget.barcode,
            'brand': widget.brand,
            'packageSize': widget.packageSize,
            'imageUrl': widget.imageUrl,
            'createdAt': FieldValue.serverTimestamp(),
            'createdBy': user.uid,
          });

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Product added to pantry!')));

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save product: $error')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = _expirationDate;

    return Scaffold(
      appBar: AppBar(title: const Text('Add to Pantry')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              widget.productName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(widget.brand),
            Text(widget.packageSize),
            const SizedBox(height: 24),

            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final quantity = int.tryParse(value?.trim() ?? '');

                if (quantity == null || quantity <= 0) {
                  return 'Enter a positive whole number';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _category = value);
                }
              },
            ),

            const SizedBox(height: 16),

            ListTile(
              title: const Text('Expiration date'),
              subtitle: Text(
                date == null
                    ? 'Not specified'
                    : '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.calendar_month),
              onTap: _selectExpirationDate,
            ),

            if (_expirationDate != null)
              TextButton(
                onPressed: () {
                  setState(() => _expirationDate = null);
                },
                child: const Text('Clear expiration date'),
              ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _saving ? null : _saveProduct,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: Text(_saving ? 'Saving...' : 'Add to Pantry'),
            ),
          ],
        ),
      ),
    );
  }
}
