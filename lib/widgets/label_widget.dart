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
    super.key,
    required this.product,
    required this.labelSize,
    this.showBorder = true,
    this.showBarcode = false,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate aspect ratio
    final double aspectRatio = labelSize.widthCm / labelSize.heightCm;

    // Special handling for 3-column layout
    final bool isSmall3Column = labelSize.columnsPerPage == 3;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, // Use white background for all templates
          border:
              showBorder
                  ? Border.all(
                    color: const Color.fromARGB(255, 162, 162, 162),
                    width: 1.0,
                  )
                  : null,
        ),
        child: Padding(
          padding: EdgeInsets.all(
            isSmall3Column ? 4.0 : 6.0,
          ), // Smaller padding for 3-column
          child: _buildLabel(isSmall3Column),
        ),
      ),
    );
  }

  Widget _buildLabel(bool isSmall3Column) {
    // For the 3-column layout, use a more compact design
    if (isSmall3Column) {
      return _buildCompactLabel();
    } else {
      return _buildStandardLabel();
    }
  }

  Widget _buildStandardLabel() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Top: Persian product name (right-to-left)
        Expanded(
          flex: 2,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: AutoSizeText(
              product.fullNameFa,
              style: TextStyle(
                fontFamily: AppFonts.persianFont,
                fontWeight: FontWeight.bold,
                fontSize: labelSize.persianFontSize,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              minFontSize:
                  labelSize.persianFontSize * 0.6, // Minimum 60% of target size
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        // Middle: Full product name and info in English
        Expanded(
          flex: 1,
          child: AutoSizeText(
            product.fullNameEn,
            style: TextStyle(
              fontFamily: AppFonts.englishFont,
              fontSize: labelSize.englishFontSize,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            minFontSize:
                labelSize.englishFontSize * 0.6, // Minimum 60% of target size
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Bottom: Price with specific formatting
        Expanded(
          flex: 2,
          child: Row(
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

              // Cents
              Padding(
                padding: EdgeInsets.only(top: labelSize.priceFontSize * 0.1),
                child: Text(
                  _getCentsFormatted(product.price),
                  style: TextStyle(
                    fontFamily: AppFonts.englishFont,
                    fontWeight: FontWeight.bold,
                    fontSize: labelSize.priceFontSize * 0.5,
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
        ),

        // Optional barcode
        if (showBarcode && product.barcode.isNotEmpty)
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: BarcodeWidget(
                barcode: Barcode.code128(),
                data: product.barcode,
                drawText: true,
                height: 30,
                style: TextStyle(fontSize: labelSize.englishFontSize * 0.5),
              ),
            ),
          ),
      ],
    );
  }

  // Compact version optimized for 3-column layout
  Widget _buildCompactLabel() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Persian product name (RTL) - more compact
        Expanded(
          flex: 1,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: AutoSizeText(
              product.nameFa,
              style: TextStyle(
                fontFamily: AppFonts.persianFont,
                fontWeight: FontWeight.bold,
                fontSize: labelSize.persianFontSize,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              minFontSize: labelSize.persianFontSize * 0.5,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        // English product name - very brief
        Expanded(
          flex: 1,
          child: AutoSizeText(
            product.nameEn, // Shorten name for compact display
            style: TextStyle(
              fontFamily: AppFonts.englishFont,
              fontSize: labelSize.englishFontSize,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            minFontSize: labelSize.englishFontSize * 0.5,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Price with compact formatting
        Expanded(
          flex: 2,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dollar sign and price, simplified
              Text(
                "\$${product.price.toStringAsFixed(2)}",
                style: TextStyle(
                  fontFamily: AppFonts.englishFont,
                  fontWeight: FontWeight.bold,
                  fontSize: labelSize.priceFontSize,
                ),
              ),
            ],
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
