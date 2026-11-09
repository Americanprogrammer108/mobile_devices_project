import 'dart:convert';

import 'package:http/http.dart' as http;

class OpenFoodFactsService {
  OpenFoodFactsService({http.Client? client})
      : _client = client ?? http.Client(),
        _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  static const baseUrl = 'https://world.openfoodfacts.org';

  Future<Map<String, dynamic>?> getProduct(String barcode) async {
    if (!RegExp(r'^\d{8,14}$').hasMatch(barcode)) return null;

    final uri = Uri.parse('$baseUrl/api/v2/product/$barcode.json').replace(
      queryParameters: {
        'fields': 'code,product_name,brands,categories_tags,image_front_url,quantity',
      },
    );
    final response = await _client.get(uri, headers: {
      // Replace with your team's genuine contact address before live use.
      'User-Agent': 'SmartPantry/1.0 (38838)',
    }).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Product lookup failed: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['status'] != 1 || body['product'] is! Map) return null;
    final product = Map<String, dynamic>.from(body['product'] as Map);
    String value(String key) => (product[key] as String?)?.trim() ?? '';
    final name = value('product_name');
    if (name.isEmpty) return null;

    return {
      'barcode': value('code').isEmpty ? barcode : value('code'),
      'name': name,
      'brand': value('brands'),
      'category': _mapCategory(product['categories_tags']),
      'imageUrl': value('image_front_url'),
      'packageSize': value('quantity'),
    };
  }

  String _mapCategory(dynamic rawTags) {
    final tags = rawTags is List ? rawTags.join(' ').toLowerCase() : '';
    if (tags.contains('milk') || tags.contains('cheese') || tags.contains('yogurt')) return 'Dairy';
    if (tags.contains('fruit') || tags.contains('vegetable')) return 'Produce';
    if (tags.contains('meat') || tags.contains('fish') || tags.contains('seafood')) return 'Meat & Seafood';
    if (tags.contains('frozen')) return 'Frozen';
    if (tags.contains('beverage') || tags.contains('drink') || tags.contains('juice')) return 'Beverages';
    if (tags.contains('bread') || tags.contains('bakery')) return 'Bakery';
    if (tags.contains('pasta') || tags.contains('rice') || tags.contains('cereal')) return 'Pantry Staples';
    return 'Other';
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}
