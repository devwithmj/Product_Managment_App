import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/label_template.dart';
import '../widgets/label_widget.dart';
import '../utils/constants.dart';

class LabelPreviewScreen extends StatelessWidget {
  final Product product;
  final LabelSize labelSize;

  const LabelPreviewScreen({
    super.key,
    required this.product,
    required this.labelSize,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.labelPreview)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Template info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product: ${product.nameEn}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Label Size: ${labelSize.name}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Dimensions: ${labelSize.widthInches}" × ${labelSize.heightInches}"',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Label preview
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.9,
                        maxHeight: MediaQuery.of(context).size.height * 0.6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            labelSize.name.toLowerCase().contains("avery")
                                ? Colors
                                    .grey
                                    .shade200 // Light background to show transparency
                                : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white,
                            spreadRadius: 2,
                            blurRadius: 7,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: LabelWidget(
                        product: product,
                        labelSize: labelSize,
                        showBorder: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
