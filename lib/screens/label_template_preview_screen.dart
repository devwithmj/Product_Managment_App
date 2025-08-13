import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/dynamic_label_template.dart';
import '../widgets/dynamic_label_widget.dart';

class LabelTemplatePreviewScreen extends StatefulWidget {
  final DynamicLabelTemplate template;
  final Product? previewProduct;

  const LabelTemplatePreviewScreen({
    super.key,
    required this.template,
    this.previewProduct,
  });

  @override
  State<LabelTemplatePreviewScreen> createState() =>
      _LabelTemplatePreviewScreenState();
}

class _LabelTemplatePreviewScreenState
    extends State<LabelTemplatePreviewScreen> {
  late Product _previewProduct;
  double _scaleFactor = 2.0;

  @override
  void initState() {
    super.initState();
    _previewProduct = widget.previewProduct ?? _createSampleProduct();
  }

  Product _createSampleProduct() {
    return Product(
      id: 'preview',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preview: ${widget.template.name}'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showTemplateInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          // Scale control
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                const Text(
                  'Scale:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Slider(
                    value: _scaleFactor,
                    min: 1.0,
                    max: 4.0,
                    divisions: 6,
                    label: '${(_scaleFactor * 100).round()}%',
                    onChanged: (value) {
                      setState(() {
                        _scaleFactor = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Text('${(_scaleFactor * 100).round()}%'),
              ],
            ),
          ),

          // Preview area
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.grey.shade200,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      // Single label preview
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DynamicLabelWidget(
                          product: _previewProduct,
                          template: widget.template,
                          scaleFactor: _scaleFactor,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Page layout preview (showing multiple labels)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Page Layout Preview',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildPageLayoutPreview(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Template info bottom panel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Template Information',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      'Size',
                      '${widget.template.widthCm} × ${widget.template.heightCm} cm',
                    ),
                    _buildInfoChip(
                      'Layout',
                      '${widget.template.columnsPerPage} × ${widget.template.rowsPerPage}',
                    ),
                    _buildInfoChip(
                      'Labels/Page',
                      '${widget.template.columnsPerPage * widget.template.rowsPerPage}',
                    ),
                    _buildInfoChip(
                      'Content Rows',
                      '${widget.template.visibleRows.length}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _changePreviewProduct,
        icon: const Icon(Icons.refresh),
        label: const Text('Change Sample'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildPageLayoutPreview() {
    final labelsPerRow = widget.template.columnsPerPage;
    final numberOfRows = widget.template.rowsPerPage;
    final maxLabelsToShow =
        6; // Show only first 6 labels to keep preview manageable
    final labelsToShow = (labelsPerRow * 2).clamp(4, maxLabelsToShow);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          for (
            int row = 0;
            row < (labelsToShow / labelsPerRow).ceil() && row < numberOfRows;
            row++
          )
            Padding(
              padding: EdgeInsets.only(
                bottom:
                    row < (labelsToShow / labelsPerRow).ceil() - 1 ? 8.0 : 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (int col = 0; col < labelsPerRow; col++)
                    if (row * labelsPerRow + col < labelsToShow)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: col < labelsPerRow - 1 ? 8.0 : 0,
                          ),
                          child: DynamicLabelWidget(
                            product: _previewProduct,
                            template: widget.template,
                            scaleFactor:
                                0.4, // Much smaller for page layout view
                          ),
                        ),
                      )
                    else
                      const Expanded(child: SizedBox()),
                ],
              ),
            ),
          if (numberOfRows > 2)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '... and ${numberOfRows - 2} more rows',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          color: Colors.blue.shade800,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showTemplateInfo() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(widget.template.name),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Template Specifications',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'Dimensions',
                    '${widget.template.widthCm} × ${widget.template.heightCm} cm',
                  ),
                  _buildInfoRow(
                    'Page Layout',
                    '${widget.template.columnsPerPage} columns × ${widget.template.rowsPerPage} rows',
                  ),
                  _buildInfoRow(
                    'Labels per Page',
                    '${widget.template.columnsPerPage * widget.template.rowsPerPage}',
                  ),
                  _buildInfoRow(
                    'Horizontal Spacing',
                    '${widget.template.horizontalSpacingCm} cm',
                  ),
                  _buildInfoRow(
                    'Vertical Spacing',
                    '${widget.template.verticalSpacingCm} cm',
                  ),
                  _buildInfoRow('Padding', '${widget.template.paddingCm} cm'),

                  const SizedBox(height: 16),
                  const Text(
                    'Content Configuration',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  ...widget.template.visibleRows.asMap().entries.map((entry) {
                    final index = entry.key;
                    final row = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getRowTypeDisplayName(row.type),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${row.fontSize.toInt()}pt • ${row.fontWeight.name} • ${row.alignment.name}${row.isRTL ? ' • RTL' : ''}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _getRowTypeDisplayName(LabelRowType type) {
    switch (type) {
      case LabelRowType.persianNameWithSize:
        return 'Persian Name + Size';
      case LabelRowType.englishNameWithSize:
        return 'English Name + Size';
      case LabelRowType.persianName:
        return 'Persian Name';
      case LabelRowType.englishName:
        return 'English Name';
      case LabelRowType.persianBrand:
        return 'Persian Brand';
      case LabelRowType.englishBrand:
        return 'English Brand';
      case LabelRowType.persianNameBrand:
        return 'Persian Name + Brand';
      case LabelRowType.englishNameBrand:
        return 'English Name + Brand';
      case LabelRowType.persianSize:
        return 'Persian Size';
      case LabelRowType.englishSize:
        return 'English Size';
      case LabelRowType.price:
        return 'Price';
      case LabelRowType.priceWithUnit:
        return 'Price + Unit';
      case LabelRowType.barcode:
        return 'Barcode/PLU';
      case LabelRowType.customText:
        return 'Custom Text';
      case LabelRowType.empty:
        return 'Empty Space';
    }
  }

  void _changePreviewProduct() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Choose Sample Product'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSampleProductOption(
                  'Grocery Item',
                  Product(
                    id: '1',
                    nameEn: 'Organic Apples',
                    nameFa: 'سیب ارگانیک',
                    brandEn: 'Fresh Farm',
                    brandFa: 'مزرعه تازه',
                    sizeValue: '1',
                    unitType: UnitType.lb,
                    price: 3.99,
                    barcode: '12345',
                  ),
                ),
                _buildSampleProductOption(
                  'Rice Package',
                  Product(
                    id: '2',
                    nameEn: 'Basmati Rice',
                    nameFa: 'برنج بسمتی',
                    brandEn: 'Golden Grain',
                    brandFa: 'دانه طلایی',
                    sizeValue: '2',
                    unitType: UnitType.kg,
                    price: 8.50,
                    barcode: '23456',
                  ),
                ),
                _buildSampleProductOption(
                  'Oil Bottle',
                  Product(
                    id: '3',
                    nameEn: 'Olive Oil',
                    nameFa: 'روغن زیتون',
                    brandEn: 'Mediterranean',
                    brandFa: 'مدیترانه‌ای',
                    sizeValue: '500',
                    unitType: UnitType.ml,
                    price: 12.99,
                    barcode: '34567',
                  ),
                ),
                _buildSampleProductOption(
                  'Spice Pack',
                  Product(
                    id: '4',
                    nameEn: 'Black Pepper',
                    nameFa: 'فلفل سیاه',
                    brandEn: 'Spice Master',
                    brandFa: 'استاد ادویه',
                    sizeValue: '100',
                    unitType: UnitType.gr,
                    price: 4.25,
                    barcode: '45678',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  Widget _buildSampleProductOption(String name, Product product) {
    return ListTile(
      title: Text(name),
      subtitle: Text('${product.nameEn} / ${product.nameFa}'),
      onTap: () {
        setState(() {
          _previewProduct = product;
        });
        Navigator.pop(context);
      },
    );
  }
}
