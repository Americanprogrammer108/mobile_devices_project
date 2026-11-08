import 'package:flutter/material.dart';
import '../product_search/product_search_screen.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {

  // Filters (all, toBuy, purchased) for the shopping list
  static const List<String> filters = ['All', 'To Buy', 'Purchased'];

  static String currentFilter = 'All';

  // mock products for the shopping list (name and default image)
  final List<Map<String, dynamic>> mockProducts = [
    {'name': 'Milk', 'image': const Icon(Icons.local_drink), 'purchased': false, 'quantity': 1},
    {'name': 'Bananas', 'image': const Icon(Icons.apple), 'purchased': false, 'quantity': 6},
    {'name': 'Bread', 'image': const Icon(Icons.bakery_dining), 'purchased': false, 'quantity': 1},
    {'name': 'Chicken', 'image': const Icon(Icons.set_meal), 'purchased': false, 'quantity': 2},
    {'name': 'Tomatoes', 'image': const Icon(Icons.local_florist), 'purchased': false, 'quantity': 4},
    {'name': 'Pasta', 'image': const Icon(Icons.dinner_dining), 'purchased': false, 'quantity': 1},
    {'name': 'Eggs', 'image': const Icon(Icons.egg), 'purchased': true, 'quantity': 1},
    {'name': 'Onions', 'image': const Icon(Icons.spa), 'purchased': true, 'quantity': 3},
  ];

  int getFilterCounts(String filter) {
    if (filter == 'To Buy') {
      return mockProducts.where((product) => !product['purchased']).length;
    } else if (filter == 'Purchased') {
      return mockProducts.where((product) => product['purchased']).length;
    } else {
      return mockProducts.length;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductSearchScreen(),
                )
              ); 
            }
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // dialog to add a new item
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Add an Item'),
                    // content: Import the add item manually widget here
                    content: const Text('Add item widget to be added'),
                  );
                }
              );
            }
          ),
        ]
      ),
      body: Column(
        children: [
          const Padding(padding: EdgeInsets.all(8.0)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: filters.map((filter) {
              return ElevatedButton(
                onPressed: () {
                  setState(() {
                    currentFilter = filter;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentFilter == filter ? Colors.green : Colors.grey.shade200
                ),
                child: Text('$filter ${(filter != 'All' ? {getFilterCounts(filter)} : '')}', 
                  style: TextStyle(
                    color: currentFilter == filter ? Colors.white : Colors.grey.shade800
                  )
                ),
              );
            }).toList(),
          ),

          Expanded(
            child: ListView(
              children: [
                if (currentFilter == 'All' || currentFilter == 'To Buy') 
                  buildProductSection('To Buy', false),
                if (currentFilter == 'All' || currentFilter == 'Purchased')
                  buildProductSection('Purchased', true)
              ]
            )
          )
        ]
      ),
    );
  }

  // build product sections
  Widget buildProductSection(String title, bool purchased) {
    final products = mockProducts
        .where((product) => product['purchased'] == purchased)
        .toList();

    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (products.isNotEmpty && purchased && currentFilter == 'All')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

        // Products belonging to this section
        ...products.map((product) => buildProductRow(product)),
      ],
    );
  }  

  // build product rows
  Widget buildProductRow(Map<String, dynamic> product) {
    final bool purchased = product['purchased'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Checkbox(
            value: purchased,
            activeColor: Colors.green,
            onChanged: (value) {
              setState(() {
                product['purchased'] = value!;
              });
            },
          ),

          Expanded(
            child: Opacity(
              opacity: purchased ? 0.4 : 1.0,
              child: Row(
                children: [
                  SizedBox(width: 40, child: product['image']),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      product['name'],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Quantity controls
          Opacity(
            opacity: purchased ? 0.4 : 1.0,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: purchased ? null : () {
                    setState(() {
                      if (product['quantity'] > 1) {
                        product['quantity']--;
                      }
                    });
                  },
                ),

                Text('${product['quantity']}'),

                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: purchased
                      ? null
                      : () {
                          setState(() {
                            product['quantity']++;
                          });
                        },
                ),
              ],
            ),
          ),

          IconButton(
            icon: const Icon(
              Icons.delete,
              color: Colors.red,
            ),
            onPressed: () {
              setState(() {
                mockProducts.remove(product);
              });
            },
          ),
        ],
      ),
    );
  }
}
