import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/label_template.dart';
import '../utils/label_layout.dart';
import 'label_widget.dart' hide SizedBox;

class PagePreview extends StatelessWidget {
  final List<Product> products;
  final LabelSize labelSize;
  final double scale;

  const PagePreview({
    Key? key,
    required this.products,
    required this.labelSize,
    this.scale = 0.5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate letter page dimensions
    final double pageWidth = LabelSize.letterWidthPixels * scale;
    final double pageHeight = LabelSize.letterHeightPixels * scale;

    return Container(
      width: pageWidth,
      height: pageHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRect(
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: LabelSize.letterWidthPixels,
            height: LabelSize.letterHeightPixels,
            child: Stack(children: _buildLabels()),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLabels() {
    final List<Widget> labelWidgets = [];
    final List<Rect> positions = LabelLayout.calculateLabelPositions(labelSize);

    // Make sure we don't go beyond the available positions or products
    final int count =
        products.length < positions.length ? products.length : positions.length;

    for (int i = 0; i < count; i++) {
      final position = positions[i];
      final product = products[i];

      labelWidgets.add(
        Positioned(
          left: position.left,
          top: position.top,
          width: position.width,
          height: position.height,
          child: LabelWidget(
            product: product,
            labelSize: labelSize,
            showBorder: true,
          ),
        ),
      );
    }

    // Add visual debugging information to show the grid layout
    // This can be useful for troubleshooting label placement
    for (int row = 0; row < labelSize.rowsPerPage; row++) {
      for (int col = 0; col < labelSize.columnsPerPage; col++) {
        final idx = row * labelSize.columnsPerPage + col;
        if (idx < positions.length) {
          final position = positions[idx];
          labelWidgets.add(
            Positioned(
              left: position.left,
              top: position.top,
              child: Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${row + 1}×${col + 1}',
                  style: const TextStyle(fontSize: 10, color: Colors.blue),
                ),
              ),
            ),
          );
        }
      }
    }

    return labelWidgets;
  }
}
