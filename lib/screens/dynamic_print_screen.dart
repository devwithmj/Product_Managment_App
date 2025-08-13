import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/dynamic_label_template.dart';
import '../services/dynamic_print_service.dart';
import '../widgets/dynamic_label_widget.dart';

/// Example integration showing how to use dynamic label templates
/// in your existing print screen or as a standalone screen
class DynamicPrintScreen extends StatefulWidget {
  final List<Product> products;

  const DynamicPrintScreen({super.key, required this.products});

  @override
  State<DynamicPrintScreen> createState() => _DynamicPrintScreenState();
}

class _DynamicPrintScreenState extends State<DynamicPrintScreen> {
  DynamicLabelTemplate _selectedTemplate = DynamicLabelTemplates.standard;
  bool _isPrinting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Print ${widget.products.length} Labels'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _isPrinting ? null : _printLabels,
          ),
        ],
      ),
      body: Column(
        children: [
          // Template selection
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Label Template',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  DropdownButton<DynamicLabelTemplate>(
                    value: _selectedTemplate,
                    isExpanded: true,
                    onChanged: (template) {
                      if (template != null) {
                        setState(() {
                          _selectedTemplate = template;
                        });
                      }
                    },
                    items:
                        DynamicLabelTemplates.allTemplates.map((template) {
                          return DropdownMenuItem(
                            value: template,
                            child: Text(
                              '${template.name} (${template.widthCm}×${template.heightCm}cm)',
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Layout: ${_selectedTemplate.columnsPerPage} × ${_selectedTemplate.rowsPerPage} = '
                    '${_selectedTemplate.columnsPerPage * _selectedTemplate.rowsPerPage} labels per page',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ),

          // Preview
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Label Preview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: DynamicLabelWidget(
                      product:
                          widget.products.isNotEmpty
                              ? widget.products.first
                              : _createSampleProduct(),
                      template: _selectedTemplate,
                      scaleFactor: 2.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Label Content:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ..._selectedTemplate.visibleRows.map((row) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(
                            _getRowIcon(row.type),
                            size: 16,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getRowDescription(row),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          if (row.isRTL)
                            const Icon(
                              Icons.format_textdirection_r_to_l,
                              size: 14,
                              color: Colors.orange,
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Print button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _isPrinting ? null : _printLabels,
              icon:
                  _isPrinting
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.print),
              label: Text(_isPrinting ? 'Generating...' : 'Print Labels'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRowIcon(LabelRowType type) {
    switch (type) {
      case LabelRowType.persianNameWithSize:
      case LabelRowType.persianName:
      case LabelRowType.persianBrand:
      case LabelRowType.persianNameBrand:
      case LabelRowType.persianSize:
        return Icons.language;
      case LabelRowType.englishNameWithSize:
      case LabelRowType.englishName:
      case LabelRowType.englishBrand:
      case LabelRowType.englishNameBrand:
      case LabelRowType.englishSize:
        return Icons.text_fields;
      case LabelRowType.price:
      case LabelRowType.priceWithUnit:
        return Icons.attach_money;
      case LabelRowType.barcode:
        return Icons.qr_code;
      case LabelRowType.customText:
        return Icons.edit;
      case LabelRowType.empty:
        return Icons.space_bar;
    }
  }

  String _getRowDescription(LabelRow row) {
    switch (row.type) {
      case LabelRowType.persianNameWithSize:
        return 'Persian name with size in parentheses';
      case LabelRowType.englishNameWithSize:
        return 'English name with size in parentheses';
      case LabelRowType.persianName:
        return 'Persian product name only';
      case LabelRowType.englishName:
        return 'English product name only';
      case LabelRowType.persianBrand:
        return 'Persian brand name';
      case LabelRowType.englishBrand:
        return 'English brand name';
      case LabelRowType.persianNameBrand:
        return 'Persian name and brand';
      case LabelRowType.englishNameBrand:
        return 'English brand and name';
      case LabelRowType.persianSize:
        return 'Persian size information';
      case LabelRowType.englishSize:
        return 'English size information';
      case LabelRowType.price:
        return 'Price in \$XX.XX format';
      case LabelRowType.priceWithUnit:
        return 'Price with selling unit (\$XX.XX /unit)';
      case LabelRowType.barcode:
        return 'Barcode as PLU format';
      case LabelRowType.customText:
        return 'Custom static text: "${row.customText ?? ""}"';
      case LabelRowType.empty:
        return 'Empty space for layout';
    }
  }

  Product _createSampleProduct() {
    return Product(
      id: 'sample',
      nameEn: 'Sample Product',
      nameFa: 'محصول نمونه',
      brandEn: 'Brand Name',
      brandFa: 'نام برند',
      sizeValue: '500',
      unitType: UnitType.gr,
      price: 12.99,
      barcode: '12345',
    );
  }

  Future<void> _printLabels() async {
    setState(() {
      _isPrinting = true;
    });

    try {
      final pdfBytes = await DynamicPrintService.generatePdf(
        products: widget.products,
        template: _selectedTemplate,
      );

      if (mounted) {
        await DynamicPrintService.showPrintPreview(context, pdfBytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating labels: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }
    }
  }
}

/// Example of how to integrate with your existing print workflow
class PrintIntegrationExample {
  /// Replace your existing print service call with this:
  static Future<void> printWithDynamicTemplate({
    required List<Product> products,
    required BuildContext context,
    DynamicLabelTemplate? template,
  }) async {
    final selectedTemplate = template ?? DynamicLabelTemplates.standard;

    try {
      final pdfBytes = await DynamicPrintService.generatePdf(
        products: products,
        template: selectedTemplate,
      );

      await DynamicPrintService.showPrintPreview(context, pdfBytes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error printing labels: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Or use this to show template selection before printing:
  static Future<void> printWithTemplateSelection({
    required List<Product> products,
    required BuildContext context,
  }) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DynamicPrintScreen(products: products),
      ),
    );
  }
}
