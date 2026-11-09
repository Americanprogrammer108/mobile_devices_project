
import 'package:flutter/material.dart';
import '../../services/open_food_facts_service.dart';
import '../../screens/scanner_page.dart';
import '../../screens/add_to_pantry_page.dart';

class ProductSearchScreen extends StatefulWidget {
  const ProductSearchScreen({super.key});

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  String searchQuery = '';

  final searchController = TextEditingController();
  final api = OpenFoodFactsService();

  List<Map<String, dynamic>> products = [];

  bool isLoading = false;
  String? errorMessage;
  int requestId = 0;

  Future<void> searchProducts() async {
    final query = searchController.text.trim();
    final currentRequest = ++requestId;

    if (query.isEmpty) {
      setState(() {
        products = [];
        errorMessage = null;
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      products = [];
    });

    try {
      final isBarcode = RegExp(r'^\d{8,14}$').hasMatch(query);

      final results = isBarcode
          ? await api.getProduct(query)
          : await api.searchProducts(query);

      if (!mounted || currentRequest != requestId) return;

      setState(() {
        if (isBarcode) {
          products = results == null
              ? []
              : [results as Map<String, dynamic>];
        } else {
          products = results as List<Map<String, dynamic>>;
        }

        isLoading = false;
      });
    } catch (e) {
      if (!mounted || currentRequest != requestId) return;

      setState(() {
        errorMessage = 'Unable to search. Check your connection.';
        isLoading = false;
      });
    }
  }

  Future<void> scanProduct() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const ScannerPage(),
      ),
    );

    if (!mounted || barcode == null) return;

    final currentRequest = ++requestId;
    searchController.text = barcode;

    setState(() {
      searchQuery = barcode;
      isLoading = true;
      errorMessage = null;
      products = [];
    });

    try {
      final product = await api.getProduct(barcode);

      if (!mounted || currentRequest != requestId) return;

      setState(() {
        products = product == null ? [] : [product];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted || currentRequest != requestId) return;

      setState(() {
        errorMessage = 'Barcode lookup failed.';
        isLoading = false;
      });
    }
  }

  Future<void> addProduct(Map<String, dynamic> product) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddToPantryPage(
          barcode: product['barcode'] as String? ?? '',
          productName: product['name'] as String? ?? '',
          brand: product['brand'] as String? ?? '',
          packageSize: product['packageSize'] as String? ?? '',
          imageUrl: product['imageUrl'] as String? ?? '',
          suggestedCategory: product['category'] as String? ?? 'Other',
        ),
      ),
    );
  }

  @override
  void dispose() {
    ++requestId;
    searchController.dispose();
    api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Search')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                searchProducts();
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search for a product (e.g., "bread")',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () {
                    scanProduct();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onChanged: (value) {
                ++requestId;
                setState(() {
                  searchQuery = value;
                  products = [];
                  errorMessage = null;
                  isLoading = false;
                });
              },
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: isLoading ? null : searchProducts,
              child: const Text('Search Products'),
            ),

            const SizedBox(height: 12),

            if (searchQuery.isNotEmpty) ...[
              const Text(
                'Search Results',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 12),
            ],

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                  ? Center(
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
                  : products.isEmpty
                  ? const Center(child: Text('No products found.'))
                  : ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  final imageUrl = product['imageUrl'] as String? ?? '';
                  final isGeneric = product['isGeneric'] == true;

                  return Card(
                    child: ListTile(
                      leading: isGeneric
                          ? const Icon(Icons.shopping_basket, size: 40)
                          : imageUrl.isNotEmpty
                          ? Image.network(
                        imageUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.fastfood, size: 40);
                        },
                      )
                          : const Icon(Icons.fastfood, size: 40),

                      title: Text(product['name'] ?? ''),

                      subtitle: Text(
                        isGeneric
                            ? 'Generic grocery item'
                            : '${product['packageSize'] ?? ''} • ${product['brand'] ?? ''}',
                      ),

                      trailing: IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          addProduct(product);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
