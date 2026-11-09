import 'package:flutter/material.dart';
import '../../routing/app_routes.dart';
import '../product_details/product_details_screen.dart';

class ProductSearchScreen extends StatefulWidget {
  const ProductSearchScreen({super.key});

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  String searchQuery = '';

  final List<Map<String, dynamic>> products = [
{'name': '2% Milk', 'brand': 'Neilson', 'size': '1 L', 'category': 'Dairy', 'image': Icons.local_drink, 'barcode': '068200002314'},
    {'name': 'Large White Eggs', 'brand': 'Burnbrae Farms', 'size': '12 eggs', 'category': 'Dairy', 'image': Icons.egg, 'barcode': '057316013205'},
    {'name': 'Whole Wheat Bread', 'brand': 'Dempster’s', 'size': '675 g', 'category': 'Bakery', 'image': Icons.bakery_dining, 'barcode': '068700101037'},
    {'name': 'Salted Butter', 'brand': 'Lactantia', 'size': '454 g', 'category': 'Dairy', 'image': Icons.breakfast_dining, 'barcode': '064420005116'},
    {'name': 'Bananas', 'brand': 'No Name', 'size': '1 bunch', 'category': 'Produce', 'image': Icons.shopping_basket, 'barcode': '060383069158'},
    {'name': 'Gala Apples', 'brand': 'No Name', 'size': '3 lb', 'category': 'Produce', 'image': Icons.apple, 'barcode': '060383123456'},
    {'name': 'Orange Juice', 'brand': 'Tropicana', 'size': '1.36 L', 'category': 'Beverages', 'image': Icons.local_cafe, 'barcode': '048500001011'},
    {'name': 'Cheddar Cheese', 'brand': 'Black Diamond', 'size': '400 g', 'category': 'Dairy', 'image': Icons.lunch_dining, 'barcode': '068730030102'},
    {'name': 'Chicken Breast', 'brand': 'Maple Leaf', 'size': '1 kg', 'category': 'Meat', 'image': Icons.set_meal, 'barcode': '063100115019'},
    {'name': 'White Rice', 'brand': 'No Name', 'size': '2 kg', 'category': 'Pantry', 'image': Icons.rice_bowl, 'barcode': '060383999888'},
  ];

  @override
  Widget build(BuildContext context) {

    final filteredProducts = products.where((product) {
      final nameMatch = product['name'].toLowerCase().contains(searchQuery.toLowerCase());
      final brandMatch = product['brand'].toLowerCase().contains(searchQuery.toLowerCase());
      return nameMatch || brandMatch;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Product Search')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search for a product (e.g., "bread")',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () async {
                    final scannedBarcode = await Navigator.pushNamed(
                      context,
                      AppRoutes.scanner,
                    );

                  if (scannedBarcode != null && scannedBarcode is String && context.mounted) {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.productDetails,
                      arguments: scannedBarcode,
                    );
                  }
              
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onChanged: ((value) => {
                    setState(() {
                      searchQuery = value;
                    })
                  }),
            ),

            const SizedBox(height: 12),

            // display text at start

            if (searchQuery.isNotEmpty) ... [
              const Text(
                'Search Results',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.left,
              ),
            
              const SizedBox(height: 12),
            ], 

            Expanded(
              child: filteredProducts.isEmpty ?
              const Center(child: Text('No products found.')) :
              ListView.builder(
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  return Card (
                    child: ListTile(
                      leading: Icon(product['image'], size: 40),
                      title: Text(product['name']),
                      subtitle: Text('${product['size']} • ${product['brand']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
    // Navigate directly and pass the full product map so it displays instantly without a 404 API error
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(localProduct: product),
      ),
    );
  }
                      )
                    )
                  );
                }
              )
            )
          ],
        ),
      ),
    );
  }
}