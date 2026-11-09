import 'package:flutter/material.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'add_to_pantry_page.dart';
import './scanner_page.dart';
import '../services/pantry_category_mapper.dart';

class ProductLookupPage extends StatefulWidget {
  const ProductLookupPage({super.key});

  @override
  State<ProductLookupPage> createState() => _ProductLookupPageState();
}

class _ProductLookupPageState extends State<ProductLookupPage> {
  final _controller = TextEditingController();

  Product? _product;
  String? _error;
  bool _loading = false;

  // Incremented on every lookup. A response only updates the UI if it still
  // matches the latest request — otherwise it is a stale answer from an
  // earlier barcode and must be ignored. This is what makes repeated
  // lookups safe.
  int _requestId = 0;



  Future<void> _lookup() async {
    final barcode = _normalizeBarcode(_controller.text);
    if (barcode.isEmpty) return;

    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
      _product = null;
    });

    final config = ProductQueryConfiguration(
      barcode,
      language: OpenFoodFactsLanguage.ENGLISH,
      fields: const [
        ProductField.BARCODE,
        ProductField.NAME,
        ProductField.BRANDS,
        ProductField.QUANTITY,
        ProductField.NUTRITION,
        ProductField.NUTRISCORE,
        ProductField.INGREDIENTS_TEXT,
        ProductField.IMAGE_FRONT_SMALL_URL,
        ProductField.CATEGORIES_TAGS,
      ],
      version: ProductQueryVersion.latestVersion,
    );

    try {
      final result = await OpenFoodAPIClient.getProductV3(config);

      // Widget disposed, or a newer lookup has started since → drop it.
      if (!mounted || requestId != _requestId) return;

      setState(() {
        if (result.status == ProductResultV3.statusSuccess &&
            result.product != null) {
          _product = result.product;
        } else {
          _error = 'Product not found.';
        }
        _loading = false;
      });
    }
    catch (e, stackTrace) {
      if (!mounted || requestId != _requestId) return;
      debugPrint('Open Food Facts lookup error: $e');
      debugPrintStack(stackTrace: stackTrace);
      setState(() {
        _error = 'Network error — check your connection.';
        _loading = false;
      });
    }
    // catch (e, stackTrace) {
    //
    //
    //   // Keep your existing error-handling logic here.
    // }
  }

  /// Opens the camera scanner and, when a barcode is detected,
  /// fills the text field with it and runs the lookup automatically.
  Future<void> _scanBarcode() async {
    final code = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const ScannerPage()));
    if (!mounted || code == null || code.isEmpty) return;

    _controller.text = code;
    _lookup();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product lookup')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _lookup(),
            decoration: InputDecoration(
              labelText: 'Barcode number',
              hintText: 'e.g. 3017620422003',
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo_camera_outlined),
                    tooltip: 'Scan barcode',
                    onPressed: _scanBarcode,
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    tooltip: 'Search',
                    onPressed: _lookup,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          if (_loading) const Center(child: CircularProgressIndicator()),

          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),

          if (_product != null) ...[
            if (_product!.imageFrontSmallUrl != null)
              Center(child: _ProductImage(_product!.imageFrontSmallUrl!)),
            const SizedBox(height: 16),
            Text(
              _product!.productName ?? '(no name)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (_product!.brands != null) Text(_product!.brands!),
            if (_product!.quantity != null) Text(_product!.quantity!),
            const Divider(height: 32),
            _nutrientRow('Energy, kcal/100 g', _nutrient(Nutrient.energyKCal)),
            _nutrientRow('Sugars, g/100 g', _nutrient(Nutrient.sugars)),
            _nutrientRow('Salt, g/100 g', _nutrient(Nutrient.salt)),
            _nutrientRow('Proteins, g/100 g', _nutrient(Nutrient.proteins)),
            const SizedBox(height: 12),
            if (_product!.nutriscore != null)
              Chip(
                label: Text(
                  'Nutri-Score ${_product!.nutriscore!.toUpperCase()}',
                ),
              ),
            if (_product!.ingredientsText != null) ...[
              const SizedBox(height: 16),
              Text(_product!.ingredientsText!),
            ],

            ElevatedButton.icon(
              onPressed: () async {
                final product = _product;
                if (product == null) return;

                final suggestedCategory = PantryCategoryMapper.suggest(
                  tags: product.categoriesTags ?? const <String>[],
                  productName: product.productName ?? '',
                );

                final barcode = _controller.text.trim();

                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                final saved = await navigator.push<bool>(
                  MaterialPageRoute(
                    builder: (_) => AddToPantryPage(
                      barcode: barcode,
                      productName: product.productName ?? 'Unknown product',
                      brand: product.brands ?? '',
                      packageSize: product.quantity ?? '',
                      imageUrl: product.imageFrontSmallUrl ?? '',
                      suggestedCategory: suggestedCategory,
                    ),
                  ),
                );

                if (!mounted) return;

                if (saved == true) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Pantry updated successfully!'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Add to Pantry'),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String? _nutrient(Nutrient nutrient) {
    final product = _product;
    if (product == null) return null;

    final nutritionSets = NutritionHelper().getInputSets(product);
    if (nutritionSets == null || nutritionSets.isEmpty) {
      return null;
    }

    for (final nutritionSet in nutritionSets) {
      final key = nutritionSet.key;

      // Only display values for the product as sold,
      // per 100 g or 100 mL.
      if (key.preparation != NutritionSetKey.preparationAsSold ||
          key.perSize != PerSize.oneHundredGrams) {
        continue;
      }

      final nutrientValue = nutritionSet.nutritionValues?[nutrient];
      final value = nutrientValue?.value ?? nutrientValue?.valueComputed;

      if (value != null) {
        return value.toStringAsFixed(1);
      }
    }

    return null;
  }

  String _normalizeBarcode(String barcode) {
    final cleaned = barcode.trim();

    if (cleaned.length == 12 &&
        RegExp(r'^\d{12}$').hasMatch(cleaned)) {
      return '0$cleaned';
    }

    return cleaned;
  }

  Widget _nutrientRow(String label, String? value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label), Text(value ?? '-')],
    ),
  );
}

/// Product photo that loads independently of the product data:
/// progress bar while downloading, icon on failure, no layout jump,
/// and no blank flash when the URL changes between lookups.
class _ProductImage extends StatelessWidget {
  const _ProductImage(this.url);

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 180,
        width: 180,
        child: Image.network(
          url,
          fit: BoxFit.contain,
          gaplessPlayback: true, // keep old image until the new one decodes
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child; // fully loaded
            final expected = progress.expectedTotalBytes;
            return Center(
              child: CircularProgressIndicator(
                value: expected != null
                    ? progress.cumulativeBytesLoaded / expected
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.image_not_supported_outlined, size: 48),
          ),
        ),
      ),
    );
  }
}
