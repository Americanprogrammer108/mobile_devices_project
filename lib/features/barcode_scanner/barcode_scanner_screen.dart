import 'package:flutter/material.dart';
import '../../screens/scanner_page.dart';
import '../product_details/product_details_screen.dart';

class BarcodeScannerScreen extends StatelessWidget {
  const BarcodeScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Barcode Scanner')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code_scanner, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Tap below to open the camera and scan a product barcode to view its details.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  // Await the scanned barcode string from your existing ScannerPage
                  final scannedBarcode = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(builder: (context) => const ScannerPage()),
                  );

                  if (scannedBarcode != null && context.mounted) {
                    // Push to Product Details passing the scanned code
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailsScreen(barcode: scannedBarcode),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Start Scanning'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}