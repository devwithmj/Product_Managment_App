import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/dynamic_label_template.dart';

class DynamicLabelWidget extends StatelessWidget {
  final Product product;
  final DynamicLabelTemplate template;
  final double scaleFactor;

  const DynamicLabelWidget({
    super.key,
    required this.product,
    required this.template,
    this.scaleFactor = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final double labelWidth =
        DynamicLabelTemplate.cmToPixels(template.widthCm) * scaleFactor;
    final double labelHeight =
        DynamicLabelTemplate.cmToPixels(template.heightCm) * scaleFactor;
    final double padding =
        DynamicLabelTemplate.cmToPixels(template.paddingCm) * scaleFactor;

    return Container(
      width: labelWidth,
      height: labelHeight,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 1),
        color: Colors.white,
      ),
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children:
            template.visibleRows.map((row) {
              final text = row.generateText(product);

              // Skip empty rows
              if (text.isEmpty) {
                return SizedBox(height: row.fontSize * 0.3 * scaleFactor);
              }

              // Create the text widget
              Widget textWidget = Text(
                text,
                style: TextStyle(
                  fontSize: row.fontSize * scaleFactor,
                  fontWeight:
                      row.fontWeight == LabelFontWeight.bold
                          ? FontWeight.bold
                          : FontWeight.normal,
                  fontFamily: row.isRTL ? 'Vazirmatn' : 'Roboto',
                ),
                textAlign: _getTextAlignment(row.alignment),
              );

              // Wrap in RTL direction if needed
              if (row.isRTL) {
                textWidget = Directionality(
                  textDirection: TextDirection.rtl,
                  child: textWidget,
                );
              }

              // Handle special formatting for price rows
              if (row.type == LabelRowType.price ||
                  row.type == LabelRowType.priceWithUnit) {
                return _buildPriceRow(product, row);
              }

              return textWidget;
            }).toList(),
      ),
    );
  }

  // Build a special price row with proper formatting
  Widget _buildPriceRow(Product product, LabelRow row) {
    if (row.type == LabelRowType.price) {
      return _buildStyledPriceDisplay(product.price, row.fontSize);
    } else if (row.type == LabelRowType.priceWithUnit) {
      String unit = _getSellingUnit(product.unitType);
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStyledPriceDisplay(product.price, row.fontSize),
          const SizedBox(width: 4),
          Text(
            '/$unit',
            style: TextStyle(
              fontSize: row.fontSize * 0.6 * scaleFactor,
              fontWeight:
                  row.fontWeight == LabelFontWeight.bold
                      ? FontWeight.bold
                      : FontWeight.normal,
            ),
          ),
        ],
      );
    }

    return const Text('');
  }

  // Build styled price display with dollars and cents
  Widget _buildStyledPriceDisplay(double price, double fontSize) {
    final dollars = price.floor();
    final cents = ((price - dollars) * 100).round();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '\$$dollars.',
          style: TextStyle(
            fontSize: fontSize * scaleFactor,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          cents.toString().padLeft(2, '0'),
          style: TextStyle(
            fontSize: fontSize * 0.7 * scaleFactor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Convert alignment enum to Flutter text alignment
  TextAlign _getTextAlignment(LabelTextAlignment alignment) {
    switch (alignment) {
      case LabelTextAlignment.left:
        return TextAlign.left;
      case LabelTextAlignment.center:
        return TextAlign.center;
      case LabelTextAlignment.right:
        return TextAlign.right;
    }
  }

  // Helper method to get selling unit string
  String _getSellingUnit(UnitType unitType) {
    switch (unitType) {
      case UnitType.kg:
        return 'kg';
      case UnitType.lb:
        return 'lb';
      case UnitType.gr:
        return '100gr';
      case UnitType.ea:
      case UnitType.piece:
        return 'ea';
      case UnitType.pack:
        return 'pkg';
      case UnitType.pkg:
        return 'kg';
      case UnitType.plb:
        return 'lb';
      case UnitType.phandered:
        return '100gr';
      default:
        return 'ea';
    }
  }
}

// Label template editor widget
class DynamicLabelTemplateEditor extends StatefulWidget {
  final DynamicLabelTemplate template;
  final Function(DynamicLabelTemplate) onTemplateChanged;
  final Product? previewProduct;

  const DynamicLabelTemplateEditor({
    super.key,
    required this.template,
    required this.onTemplateChanged,
    this.previewProduct,
  });

  @override
  State<DynamicLabelTemplateEditor> createState() =>
      _DynamicLabelTemplateEditorState();
}

class _DynamicLabelTemplateEditorState
    extends State<DynamicLabelTemplateEditor> {
  late DynamicLabelTemplate _currentTemplate;
  late Product _previewProduct;

  @override
  void initState() {
    super.initState();
    _currentTemplate = widget.template;
    _previewProduct =
        widget.previewProduct ??
        Product(
          id: 'preview',
          nameEn: 'Sample Product',
          nameFa: 'محصول نمونه',
          brandEn: 'Brand',
          brandFa: 'برند',
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
        title: Text('Edit Template: ${_currentTemplate.name}'),
        actions: [
          TextButton(onPressed: _addNewRow, child: const Text('Add Row')),
        ],
      ),
      body: Column(
        children: [
          // Preview section
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Center(
              child: DynamicLabelWidget(
                product: _previewProduct,
                template: _currentTemplate,
                scaleFactor: 2.0,
              ),
            ),
          ),

          // Template settings
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Template Name',
                    ),
                    controller: TextEditingController(
                      text: _currentTemplate.name,
                    ),
                    onChanged: (value) {
                      _updateTemplate(_currentTemplate.copyWith(name: value));
                    },
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 100,
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Width (cm)'),
                    controller: TextEditingController(
                      text: _currentTemplate.widthCm.toString(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final width =
                          double.tryParse(value) ?? _currentTemplate.widthCm;
                      _updateTemplate(
                        _currentTemplate.copyWith(widthCm: width),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Height (cm)'),
                    controller: TextEditingController(
                      text: _currentTemplate.heightCm.toString(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final height =
                          double.tryParse(value) ?? _currentTemplate.heightCm;
                      _updateTemplate(
                        _currentTemplate.copyWith(heightCm: height),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Rows editor
          Expanded(
            child: ListView.builder(
              itemCount: _currentTemplate.labelRows.length,
              itemBuilder: (context, index) {
                final row = _currentTemplate.labelRows[index];
                return _buildRowEditor(row, index);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          widget.onTemplateChanged(_currentTemplate);
          Navigator.of(context).pop();
        },
        child: const Icon(Icons.save),
      ),
    );
  }

  Widget _buildRowEditor(LabelRow row, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButton<LabelRowType>(
                    value: row.type,
                    onChanged: (newType) {
                      if (newType != null) {
                        _updateRow(index, row.copyWith(type: newType));
                      }
                    },
                    items:
                        LabelRowType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(_getRowTypeDisplayName(type)),
                          );
                        }).toList(),
                  ),
                ),
                const SizedBox(width: 16),
                Switch(
                  value: row.visible,
                  onChanged: (value) {
                    _updateRow(index, row.copyWith(visible: value));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removeRow(index),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButton<LabelTextAlignment>(
                    value: row.alignment,
                    onChanged: (newAlignment) {
                      if (newAlignment != null) {
                        _updateRow(
                          index,
                          row.copyWith(alignment: newAlignment),
                        );
                      }
                    },
                    items:
                        LabelTextAlignment.values.map((alignment) {
                          return DropdownMenuItem(
                            value: alignment,
                            child: Text(alignment.name.toUpperCase()),
                          );
                        }).toList(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<LabelFontWeight>(
                    value: row.fontWeight,
                    onChanged: (newWeight) {
                      if (newWeight != null) {
                        _updateRow(index, row.copyWith(fontWeight: newWeight));
                      }
                    },
                    items:
                        LabelFontWeight.values.map((weight) {
                          return DropdownMenuItem(
                            value: weight,
                            child: Text(weight.name.toUpperCase()),
                          );
                        }).toList(),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 80,
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Size'),
                    controller: TextEditingController(
                      text: row.fontSize.toString(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final fontSize = double.tryParse(value) ?? row.fontSize;
                      _updateRow(index, row.copyWith(fontSize: fontSize));
                    },
                  ),
                ),
              ],
            ),
            if (row.type == LabelRowType.customText)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextField(
                  decoration: const InputDecoration(labelText: 'Custom Text'),
                  controller: TextEditingController(text: row.customText ?? ''),
                  onChanged: (value) {
                    _updateRow(index, row.copyWith(customText: value));
                  },
                ),
              ),
          ],
        ),
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

  void _updateTemplate(DynamicLabelTemplate newTemplate) {
    setState(() {
      _currentTemplate = newTemplate;
    });
  }

  void _updateRow(int index, LabelRow newRow) {
    final newRows = List<LabelRow>.from(_currentTemplate.labelRows);
    newRows[index] = newRow;
    _updateTemplate(_currentTemplate.copyWith(labelRows: newRows));
  }

  void _removeRow(int index) {
    final newRows = List<LabelRow>.from(_currentTemplate.labelRows);
    newRows.removeAt(index);
    _updateTemplate(_currentTemplate.copyWith(labelRows: newRows));
  }

  void _addNewRow() {
    final newRows = List<LabelRow>.from(_currentTemplate.labelRows);
    newRows.add(const LabelRow(type: LabelRowType.englishName, fontSize: 12.0));
    _updateTemplate(_currentTemplate.copyWith(labelRows: newRows));
  }
}
