import 'dart:typed_data';
import 'dart:io';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

import '../models/product.dart';
import '../models/label_template.dart';
import '../utils/label_layout.dart';

class PrintService {
  // Load the Vazirmatn font as a global variable
  static pw.Font? _vazirFont;
  static pw.Font? _vazirFontBold;
  static bool _fontsLoaded = false;

  // Load the fonts from assets
  static Future<void> _loadFonts() async {
    if (_fontsLoaded) return;

    try {
      // Regular font
      final regularFontData = await rootBundle.load(
        'assets/fonts/Vazirmatn-Regular.ttf',
      );
      _vazirFont = pw.Font.ttf(regularFontData);

      // Bold font
      final boldFontData = await rootBundle.load(
        'assets/fonts/Vazirmatn-Bold.ttf',
      );
      _vazirFontBold = pw.Font.ttf(boldFontData);

      _fontsLoaded = true;
      print('Fonts loaded successfully');
    } catch (e) {
      print('Error loading fonts: $e');
      // Fallback to default fonts
      _fontsLoaded = true;
    }
  }

  // Generate a PDF document for printing
  static Future<Uint8List> generatePdf({
    required List<Product> products,
    required LabelSize labelSize,
  }) async {
    // Load fonts first
    await _loadFonts();

    // Create a PDF theme with Vazirmatn font
    final theme = pw.ThemeData.withFont(
      base: _vazirFont ?? pw.Font.helvetica(),
      bold: _vazirFontBold ?? pw.Font.helveticaBold(),
    );

    // Create PDF document with letter size
    final pdf = pw.Document(theme: theme);

    // Calculate exact letter paper size in PDF points
    final pageFormat = PdfPageFormat(
      LabelSize.letterWidthPoints,
      LabelSize.letterHeightPoints,
    );

    if (products.isEmpty) {
      // Handle empty product list with a blank page
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text('No products selected for printing'),
            );
          },
        ),
      );
      return pdf.save();
    }

    // Organize products into pages
    final List<List<Product>> pages = LabelLayout.organizeProductsIntoPages(
      products,
      labelSize,
    );

    // For each page of products
    for (int pageIndex = 0; pageIndex < pages.length; pageIndex++) {
      final pageProducts = pages[pageIndex];

      // Skip empty pages
      if (pageProducts.isEmpty) continue;

      // Calculate positions for labels on this page using PDF points
      final positions = LabelLayout.calculateLabelPositionsForPDF(labelSize);

      // Make sure we don't go beyond the available positions
      final count =
          pageProducts.length < positions.length
              ? pageProducts.length
              : positions.length;

      // Add page to PDF
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.all(0),
          build: (pw.Context context) {
            print(
              "PDF page size: ${pageFormat.width}pt × ${pageFormat.height}pt",
            );

            // Create content for the page
            return pw.Stack(
              children: List.generate(count, (i) {
                final product = pageProducts[i];
                final position = positions[i];

                print(
                  "Label position: ${position.left}pt, ${position.top}pt, ${position.width}pt × ${position.height}pt",
                );

                // Match the exact label format from the sample
                return pw.Positioned(
                  left: position.left,
                  top: position.top,

                  child: pw.Container(
                    width: position.width,
                    height: position.height,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 0.5),
                    ),
                    padding: const pw.EdgeInsets.all(0),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                      children: [
                        // Persian product name in RTL
                        pw.Directionality(
                          textDirection: pw.TextDirection.rtl,
                          child: pw.Text(
                            product.fullNameFa,
                            style: pw.TextStyle(
                              font: _vazirFontBold,
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),

                        // Full product info in English
                        pw.Text(
                          product.fullNameEn,
                          style: const pw.TextStyle(fontSize: 14),
                          textAlign: pw.TextAlign.center,
                        ),

                        // Price with correct formatting
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            // Dollar sign and main price
                            pw.Text(
                              "\$${product.price.floor()}.",
                              style: pw.TextStyle(
                                fontSize: 22,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),

                            // Cents
                            pw.Text(
                              _getCentsFormatted(product.price),
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(top: 6),
                              child: pw.Text(
                                "/Ea.",
                                style: const pw.TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),

                        // /Ea. part
                      ],
                    ),
                  ),
                );
              }),
            );
          },
        ),
      );
    }

    // Save PDF to temporary file for debugging
    _savePdfToFile(pdf);

    return pdf.save();
  }

  // Save PDF to temporary file (for debugging)
  static Future<void> _savePdfToFile(pw.Document pdf) async {
    try {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/debug_labels.pdf');
      await file.writeAsBytes(await pdf.save());
      print('Debug PDF saved to: ${file.path}');
    } catch (e) {
      print('Could not save debug PDF: $e');
    }
  }

  // Helper to get cents with correct formatting
  static String _getCentsFormatted(double price) {
    int cents = ((price - price.floor()) * 100).round();
    return cents.toString().padLeft(2, '0');
  }

  // Print the generated PDF
  static Future<void> printPdf(Uint8List pdfBytes) async {
    if (pdfBytes.isEmpty) {
      throw Exception('PDF data is empty');
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      usePrinterSettings: true,
    );
  }

  // Show a print preview dialog
  static Future<void> showPrintPreview(
    BuildContext context,
    Uint8List pdfBytes,
  ) async {
    if (pdfBytes.isEmpty) {
      throw Exception('PDF data is empty');
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Product Labels',
      usePrinterSettings: true,
    );
  }
}
