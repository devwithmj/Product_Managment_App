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

    return labelWidgets;
  }
}
