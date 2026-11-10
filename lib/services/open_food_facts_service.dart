
import 'dart:convert';

import 'package:http/http.dart' as http;

class OpenFoodFactsService {
  OpenFoodFactsService({http.Client? client})
      : _client = client ?? http.Client(),
        _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;
  DateTime? lastSearch;

  static const baseUrl = 'https://world.openfoodfacts.org';

  static const userAgent = 'SmartPantry/1.0 (contact: samir.ahmadi@ontariotechu.ca)';

  Future<Map<String, dynamic>?> getProduct(String barcode) async {
    if (!RegExp(r'^\d{8,14}$').hasMatch(barcode)) return null;

    final uri = Uri.parse('$baseUrl/api/v2/product/$barcode.json').replace(
      queryParameters: {
        'fields': 'code,product_name,brands,categories_tags,image_front_url,quantity',
      },
    );
    final response = await _client.get(uri, headers: {
      'User-Agent': userAgent,
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

  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    if (query.trim().isEmpty) return [];
    if (lastSearch != null) {
      final elapsed = DateTime.now().difference(lastSearch!);

      if (elapsed < const Duration(seconds: 6)) {
        throw Exception('Please wait before searching again.');
      }
    }

    lastSearch = DateTime.now();

    final uri = Uri.parse('$baseUrl/cgi/search.pl').replace(
      queryParameters: {
        'search_terms': query.trim(),
        'search_simple': '1',
        'action': 'process',
        'json': '1',
        'page_size': '10',
        'fields': 'code,product_name,brands,categories_tags,image_front_url,quantity',
      },
    );
    final response = await _client.get(uri, headers: {
      'User-Agent': userAgent,
    }).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Product search failed: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['products'] is! List) return [];

    final products = body['products'] as List;
    final results = <Map<String, dynamic>>[];
    final search = query.trim().toLowerCase();

    results.add({
      'barcode': '',
      'name': query.trim(),
      'brand': '',
      'category': 'Other',
      'imageUrl': '',
      'packageSize': '',
      'isGeneric': true,
    });

    for (final item in products) {
      if (item is! Map) continue;

      final product = Map<String, dynamic>.from(item);
      String value(String key) => (product[key] as String?)?.trim() ?? '';
      final name = value('product_name');
      if (name.isEmpty) continue;

      final productName = name.toLowerCase();
      if (!productName.contains(search)) continue;

      results.add({
        'barcode': value('code'),
        'name': name,
        'brand': value('brands'),
        'category': _mapCategory(product['categories_tags']),
        'imageUrl': value('image_front_url'),
        'packageSize': value('quantity'),
        'isGeneric': false,
      });
    }

    int priority(String name) {
      final productName = name.toLowerCase();

      if (productName == search) return 0;
      if (productName.startsWith('$search ')) return 1;
      if (productName.endsWith(' $search')) return 2;

      return 3;
    }

    results.sort((a, b) {
      if (a['isGeneric'] == true && b['isGeneric'] != true) return -1;
      if (b['isGeneric'] == true && a['isGeneric'] != true) return 1;

      final priorityA = priority(a['name'] as String);
      final priorityB = priority(b['name'] as String);

      return priorityA.compareTo(priorityB);
    });

    return results;
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
