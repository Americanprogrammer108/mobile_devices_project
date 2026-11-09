import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String selectedFilter = 'All';

  // Sample history data for testing
  // Each item has a name, activity type, and optional details, along with a icon representing the item
  final List<Map<String, String>> historyItems = [
    {
      'name': 'Milk 2%',
      'activity': 'Scanned',
      'details': 'Added to pantry',
      'category': 'Dairy',
      'quantity': '3 cartons',
      'expirationDate': '2026-11-15',
      'icon': '🥛',
    },
    {'name': 'Banana', 'activity': 'Searched', 'details': '', 'icon': '🍌'},
    {
      'name': 'Cheddar Cheese',
      'activity': 'Added',
      'details': 'Added to shopping list',
      'category': 'Dairy',
      'quantity': '2 blocks',
      'expirationDate': '2026-12-15',
      'icon': '🧀',
    },
    {
      'name': 'Tomato',
      'activity': 'Scanned',
      'details': '',
      'category': 'Vegetables',
      'quantity': 'Not added',
      'expirationDate': 'Not added',
      'icon': '🍅',
    },
    {
      'name': 'Whole Wheat Bread',
      'activity': 'Searched',
      'details': '',
      'category': 'Bakery',
      'quantity': 'Not added',
      'expirationDate': 'Not added',
      'icon': '🍞',
    },
  ];

  // This function opens a pop-up displaying additional details about the product
  void showProductDetails(Map<String, String> item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Product Details'),

          // Displays the selected item/product details through a pop-up
          // The details are the name, category, activity, additional details, quantity, and expiration date of the product
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Displays the icon of the product
              Center(
                child: Text(
                  item['icon'] ?? '🛒',
                  style: const TextStyle(fontSize: 55),
                ),
              ),

              const SizedBox(height: 12),
              // Displays the name of the product
              Center(
                child: Text(
                  item['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Divider(),

              // Displays the category of the product
              Text('Category: ${item['category'] ?? 'Unknown'}'),
              const SizedBox(height: 10),

              // Displays the activity of the product
              Text('Activity: ${item['activity'] ?? 'Unknown'}'),
              const SizedBox(height: 10),

              // Displays additional details
              Text(
                'Details: ${item['details']?.isNotEmpty == true ? item['details'] : 'No additional details'}',
              ),
              const SizedBox(height: 10),

              // Displays the quantity of the product
              Text('Quantity: ${item['quantity'] ?? 'Unknown'}'),
              const SizedBox(height: 10),

              // Displays the expiration date of the product
              Text('Expiration Date: ${item['expirationDate'] ?? 'Unknown'}'),
            ],
          ),

          // Closes the pop-up with the "Close" button
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Added a filter for the gorcery history based on the items activity type
    // The three activity type filters are: All, Searched, Scanned, and Added
    final filteredItems = selectedFilter == 'All'
        ? historyItems
        : historyItems
              .where((item) => item['activity'] == selectedFilter)
              .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('History'),
        centerTitle: true,
        backgroundColor: const Color(0xFF176437),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // List of options for filters
          SizedBox(
            height: 65,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              children: ['All', 'Searched', 'Scanned', 'Added'].map((filter) {
                final isSelected = selectedFilter == filter;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    selectedColor: const Color(0xFF258346),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                    onSelected: (_) {
                      setState(() {
                        selectedFilter = filter;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: filteredItems.isEmpty
                // A message 'No history found' is displayed when no items match the filter
                ? const Center(child: Text('No history found'))
                : ListView.builder(
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final details = item['details'] ?? '';

                      return Column(
                        children: [
                          ListTile(
                            leading: Text(
                              item['icon'] ?? '🛒',
                              style: const TextStyle(fontSize: 30),
                            ),
                            title: Text(
                              item['name'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${item['activity'] ?? ''}'
                              '${details.isNotEmpty ? ' · $details' : ''}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            // Opens the product details pop-up when clicked
                            onTap: () {
                              showProductDetails(item);
                            },
                          ),
                          const Divider(height: 1),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
