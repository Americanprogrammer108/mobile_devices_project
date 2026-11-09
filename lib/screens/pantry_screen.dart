import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/expiry_reminder_time.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({required this.user, super.key});
  final User user;

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  DateTime? _calculateReminderTime(DateTime? expirationDate) {
    if (expirationDate == null) return null;

    // Temporary five-minute notification test.
    return DateTime.now().add(const Duration(minutes: 5));
  }

  static const categories = <String>[
    'Dairy',
    'Produce',
    'Meat & Seafood',
    'Frozen',
    'Beverages',
    'Pantry Staples',
    'Bakery',
    'Other',
  ];

  final _name = TextEditingController();
  final _count = TextEditingController(text: '1');
  String _category = 'Other';
  DateTime? _expirationDate;
  bool _saving = false;

  CollectionReference<Map<String, dynamic>> get _items => FirebaseFirestore
      .instance
      .collection('users')
      .doc(widget.user.uid)
      .collection('items');

  @override
  void dispose() {
    _name.dispose();
    _count.dispose();
    super.dispose();
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<DateTime?> _pickDate(DateTime? current) async {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
  }

  Future<void> _addItem() async {
    final name = _name.text.trim();
    final count = int.tryParse(_count.text.trim());

    if (name.isEmpty || count == null || count < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter an item name and non-negative whole-number count.',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final remindAt = _calculateReminderTime(_expirationDate);

      debugPrint('Expiration date: $_expirationDate');
      debugPrint('Calculated reminder: $remindAt');

      await _items.add({
        'name': name,
        'count': count,
        'category': _category,
        'expirationDate': _expirationDate == null
            ? null
            : Timestamp.fromDate(_dateOnly(_expirationDate!)),
        'remindAt': remindAt == null ? null : Timestamp.fromDate(remindAt),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': widget.user.uid,
      });

      debugPrint('Pantry item saved with reminder: $remindAt');

      if (!mounted) return;

      setState(() {
        _name.clear();
        _count.text = '1';
        _category = 'Other';
        _expirationDate = null;
      });
    } on FirebaseException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message ?? error.code)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editItem(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final data = document.data();
    final nameController = TextEditingController(
      text: data['name'] as String? ?? '',
    );
    final countController = TextEditingController(
      text: '${data['count'] ?? 1}',
    );
    final formKey = GlobalKey<FormState>();
    String category = categories.contains(data['category'])
        ? data['category'] as String
        : 'Other';
    DateTime? expiration = (data['expirationDate'] as Timestamp?)?.toDate();

    try {
      final changes = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Edit pantry item'),
            content: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Item name',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Enter an item name'
                            : null,
                      ),
                      TextFormField(
                        controller: countController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Count'),
                        validator: (value) {
                          final count = int.tryParse(value?.trim() ?? '');
                          return count == null || count < 0
                              ? 'Enter a non-negative whole number'
                              : null;
                        },
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        items: categories
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => category = value);
                          }
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          expiration == null
                              ? 'No expiration date'
                              : 'Expires: ${_formatDate(expiration!)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Choose expiration date',
                              icon: const Icon(Icons.calendar_month),
                              onPressed: () async {
                                final picked = await _pickDate(expiration);
                                if (picked != null) {
                                  setDialogState(() => expiration = picked);
                                }
                              },
                            ),
                            if (expiration != null)
                              IconButton(
                                tooltip: 'Clear expiration date',
                                icon: const Icon(Icons.clear),
                                onPressed: () =>
                                    setDialogState(() => expiration = null),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.pop(dialogContext, {
                    'name': nameController.text.trim(),
                    'count': int.parse(countController.text.trim()),
                    'category': category,
                    'expirationDate': expiration == null
                        ? null
                        : Timestamp.fromDate(_dateOnly(expiration!)),
                    'remindAt': calculateExpiryReminder(expiration) == null
                        ? null
                        : Timestamp.fromDate(
                            calculateExpiryReminder(expiration)!,
                          ),
                  });
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      );
      if (changes == null || !mounted) return;
      try {
        await document.reference.update(changes);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pantry item updated.')));
      } on FirebaseException catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message ?? error.code)));
      }
    } finally {
      // Avoid disposing controllers during the closing dialog animation.
      await Future<void>.delayed(const Duration(milliseconds: 350));
      nameController.dispose();
      countController.dispose();
    }
  }

  Future<void> _deleteItem(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final name = document.data()['name'] as String? ?? 'this item';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete pantry item?'),
        content: Text('Remove "$name" from your pantry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await document.reference.delete();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pantry item deleted.')));
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message ?? error.code)));
    }
  }

  Widget _expirationStatus(DateTime? expiration) {
    if (expiration == null) return const Text('No expiration date');
    final days = _dateOnly(
      expiration,
    ).difference(_dateOnly(DateTime.now())).inDays;
    final String label;
    final Color color;
    if (days < 0) {
      label = 'Expired ${-days} day(s) ago';
      color = Colors.red;
    } else if (days == 0) {
      label = 'Expires today';
      color = Colors.orange;
    } else if (days <= 3) {
      label = 'Expires in $days day(s)';
      color = Colors.yellow;
    } else {
      label = 'Fresh · expires ${_formatDate(expiration)}';
      color = Colors.green;
    }
    return Text(label, style: TextStyle(color: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pantry'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: 'Item name',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 92,
                      child: TextField(
                        controller: _count,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Count'),
                      ),
                    ),
                  ],
                ),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  key: ValueKey(_category),
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _category = value);
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _expirationDate == null
                            ? 'No expiration date selected'
                            : 'Expires: ${_formatDate(_expirationDate!)}',
                      ),
                    ),
                    IconButton(
                      tooltip: 'Choose expiration date',
                      icon: const Icon(Icons.calendar_month),
                      onPressed: () async {
                        final date = await _pickDate(_expirationDate);
                        if (date != null && mounted) {
                          setState(() => _expirationDate = date);
                        }
                      },
                    ),
                    if (_expirationDate != null)
                      IconButton(
                        tooltip: 'Clear expiration date',
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _expirationDate = null),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _items.orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final documents = snapshot.data!.docs;
                if (documents.isEmpty) {
                  return const Center(child: Text('No pantry entries yet.'));
                }
                return ListView.builder(
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    final document = documents[index];
                    final item = document.data();
                    final category =
                        item['category'] as String? ?? 'Uncategorized';
                    final expiration = (item['expirationDate'] as Timestamp?)
                        ?.toDate();
                    return ListTile(
                      title: Text(item['name'] as String? ?? 'Unnamed'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Count: ${item['count'] ?? '?'} · $category'),
                          _expirationStatus(expiration),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Edit item',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _editItem(document),
                          ),
                          IconButton(
                            tooltip: 'Delete item',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deleteItem(document),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: _saving ? null : _addItem,
          icon: const Icon(Icons.add),
          label: Text(_saving ? 'Saving…' : 'Add entry'),
        ),
      ),
    );
  }
}
