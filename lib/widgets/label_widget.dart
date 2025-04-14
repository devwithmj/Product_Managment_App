import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../models/product.dart';
import '../models/label_template.dart';
import '../utils/constants.dart';

class LabelWidget extends StatelessWidget {
  final Product product;
  final LabelSize labelSize;
  final bool showBorder;
  final bool showBarcode;

  const LabelWidget({
    Key? key,
    required this.product,
    required this.labelSize,
    this.showBorder = true,
    this.showBarcode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate aspect ratio
    final double aspectRatio = labelSize.widthCm / labelSize.heightCm;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border:
              showBorder ? Border.all(color: Colors.black, width: 1.0) : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: _buildLabel(),
        ),
      ),
    );
  }

  Widget _buildLabel() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Top: Persian product name (right-to-left)
        Directionality(
          textDirection: TextDirection.rtl,
          child: AutoSizeText(
            product.fullNameFa,
            style: TextStyle(
              fontFamily: AppFonts.persianFont,
              fontWeight: FontWeight.bold,
              fontSize: labelSize.persianFontSize,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            minFontSize: 10,
          ),
        ),

        // Middle: Full product name and info in English
        AutoSizeText(
          product.fullNameEn,
          style: TextStyle(
            fontFamily: AppFonts.englishFont,
            fontWeight: FontWeight.bold,
            fontSize: labelSize.englishFontSize,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          minFontSize: 8,
        ),

        // Bottom: Price with specific formatting as seen in samples
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dollar sign and main price
            Text(
              "\$${product.price.floor()}.",
              style: TextStyle(
                fontFamily: AppFonts.englishFont,
                fontWeight: FontWeight.bold,
                fontSize: labelSize.priceFontSize,
              ),
            ),

            // Cents (00 for whole numbers, actual cents for fractional)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                _getCentsFormatted(product.price),
                style: TextStyle(
                  fontFamily: AppFonts.englishFont,
                  fontWeight: FontWeight.bold,
                  fontSize: labelSize.englishFontSize,
                ),
              ),
            ),

            // /Ea. part
            Text(
              "/Ea.",
              style: TextStyle(
                fontFamily: AppFonts.englishFont,
                fontSize: labelSize.englishFontSize,
              ),
            ),
          ],
        ),

        // Optional barcode
        if (showBarcode && product.barcode.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: BarcodeWidget(
              barcode: Barcode.code128(),
              data: product.barcode,
              drawText: true,
              height: 40,
              style: const TextStyle(fontSize: 8),
            ),
          ),
      ],
    );
  }

  // Helper to get cents with correct formatting
  String _getCentsFormatted(double price) {
    int cents = ((price - price.floor()) * 100).round();
    return cents.toString().padLeft(2, '0');
  }
}
