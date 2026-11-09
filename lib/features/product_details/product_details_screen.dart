import 'package:flutter/material.dart';
import '../../services/open_food_facts_service.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String? barcode;
  final Map<String, dynamic>? localProduct;

  const ProductDetailsScreen({super.key, this.barcode, this.localProduct});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final OpenFoodFactsService _openFoodFactsService = OpenFoodFactsService();
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _productData;

  @override
  void initState() {
    super.initState();
    if (widget.localProduct != null) {
      setState(() {
        _productData = {
          'barcode': widget.localProduct!['barcode'] ?? 'N/A',
          'name': widget.localProduct!['name'],
          'brand': widget.localProduct!['brand'],
          'category': widget.localProduct!['category'],
          'imageUrl': '',
          'packageSize': widget.localProduct!['size'],
        };
        _isLoading = false;
      });
    } else if (widget.barcode != null) {
      _fetchProductDetails(widget.barcode!); // Add the argument here!
    }
  }

  Future<void> _fetchProductDetails(String barcode) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final product = await _openFoodFactsService.getProduct(barcode);
      setState(() {
        _productData = product;
        _isLoading = false;
        if (product == null) {
          _errorMessage = 'Product not found in Open Food Facts database.';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load product details: $e';
      });
    }
  }

  @override
  void dispose() {
    _openFoodFactsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Details')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (widget.barcode != null) {
                    _fetchProductDetails(widget.barcode!);
                  }
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final product = _productData!;
    final imageUrl = product['imageUrl'] as String?;
    final name = product['name'] as String;
    final brand = product['brand'] as String;
    final category = product['category'] as String;
    final packageSize = product['packageSize'] as String;
    final barcode = product['barcode'] as String;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Product Image
          if (imageUrl != null && imageUrl.isNotEmpty)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  height: 200,
                  width: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.image_not_supported,
                    size: 100,
                    color: Colors.grey,
                  ),
                ),
              ),
            )
          else
            const Center(
              child: Icon(Icons.fastfood, size: 100, color: Colors.grey),
            ),
          const SizedBox(height: 24),

          // Product Name & Brand
          Text(
            name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (brand.isNotEmpty)
            Text(
              brand,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 24),

          // Details Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildInfoRow(Icons.category, 'Category', category),
                  const Divider(height: 24),
                  _buildInfoRow(
                    Icons.straighten,
                    'Package Size',
                    packageSize.isNotEmpty ? packageSize : 'N/A',
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(Icons.qr_code, 'Barcode', barcode),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Action Button to Add to Pantry
          ElevatedButton.icon(
            onPressed: () {
              // Pass the fetched product details to your Add to Pantry page if needed
              // Navigator.pushNamed(context, AppRoutes.addToPantry, arguments: product);
            },
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Add to Pantry'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(width: 16),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        const Spacer(),
        Text(value, style: TextStyle(color: Colors.grey[700], fontSize: 16)),
      ],
    );
  }
}
