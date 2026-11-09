import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_devices_project/services/open_food_facts_service.dart';

void main() {
  test('Invalid barcode returns null', () async {
    var requested = false;

    final client = MockClient((request) async {
      requested = true;
      return http.Response('{}', 200);
    });

    final service = OpenFoodFactsService(client: client);
    final product = await service.getProduct('invalid');

    expect(product, isNull);
    expect(requested, isFalse);
    service.dispose();
  });

  test('Valid barcode returns filtered product', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/v2/product/3017620422003.json');

      return http.Response(
        jsonEncode({
          'status': 1,
          'product': {
            'code': '3017620422003',
            'product_name': 'Nutella',
            'brands': 'Ferrero',
            'categories_tags': ['en:spreads'],
            'image_front_url': 'https://example.com/nutella.jpg',
            'quantity': '400 g',
          },
        }),
        200,
      );
    });

    final service = OpenFoodFactsService(client: client);
    final product = await service.getProduct('3017620422003');

    expect(product, isNotNull);
    expect(product!['name'], 'Nutella');
    expect(product['brand'], 'Ferrero');
    expect(product['category'], 'Other');
    expect(product['packageSize'], '400 g');

    service.dispose();
  });

  test('Unknown product returns null', () async {
    final client = MockClient(
      (request) async => http.Response(jsonEncode({'status': 0}), 200),
    );

    final service = OpenFoodFactsService(client: client);
    final product = await service.getProduct('3017620422003');

    expect(product, isNull);
    service.dispose();
  });
}
