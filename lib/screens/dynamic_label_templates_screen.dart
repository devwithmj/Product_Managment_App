import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/dynamic_label_template.dart';
import '../widgets/dynamic_label_widget.dart';
import '../services/dynamic_print_service.dart';

class DynamicLabelTemplatesScreen extends StatefulWidget {
  final List<Product>? products;

  const DynamicLabelTemplatesScreen({Key? key, this.products})
    : super(key: key);

  @override
  State<DynamicLabelTemplatesScreen> createState() =>
      _DynamicLabelTemplatesScreenState();
}

class _DynamicLabelTemplatesScreenState
    extends State<DynamicLabelTemplatesScreen> {
  List<DynamicLabelTemplate> _templates = DynamicLabelTemplates.allTemplates;
  DynamicLabelTemplate? _selectedTemplate;
  late Product _previewProduct;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _selectedTemplate = _templates.isNotEmpty ? _templates.first : null;

    // Create a sample product for preview
    _previewProduct = Product(
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
        title: const Text('Dynamic Label Templates'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewTemplate,
          ),
          if (widget.products != null && _selectedTemplate != null)
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: _isPrinting ? null : _printLabels,
            ),
        ],
      ),
      body: Row(
        children: [
          // Left panel - Template list
          Expanded(
            flex: 1,
            child: Card(
              margin: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Templates',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _templates.length,
                      itemBuilder: (context, index) {
                        final template = _templates[index];
                        final isSelected = template == _selectedTemplate;

                        return ListTile(
                          title: Text(template.name),
                          subtitle: Text(
                            '${template.widthCm.toStringAsFixed(1)} × ${template.heightCm.toStringAsFixed(1)} cm\n'
                            '${template.columnsPerPage} × ${template.rowsPerPage} layout',
                          ),
                          isThreeLine: true,
                          selected: isSelected,
                          onTap: () {
                            setState(() {
                              _selectedTemplate = template;
                            });
                          },
                          trailing: PopupMenuButton<String>(
                            onSelected: (action) {
                              switch (action) {
                                case "preview":
                                  showDialog(
                                    context: context,
                                    builder:
                                        (context) => Dialog(
                                          insetPadding: EdgeInsets.zero,
                                          backgroundColor: Colors.transparent,
                                          child: Stack(
                                            children: [
                                              Container(
                                                width: double.infinity,
                                                height: double.infinity,
                                                margin: EdgeInsets.zero,
                                                padding: EdgeInsets.zero,
                                                child: Material(
                                                  borderRadius:
                                                      BorderRadius.zero,
                                                  color: Colors.white,
                                                  child: _buildTemplatePreview(
                                                    template,
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: 16,
                                                right: 16,
                                                child: IconButton(
                                                  icon: const Icon(
                                                    Icons.close,
                                                    size: 32,
                                                  ),
                                                  onPressed:
                                                      () =>
                                                          Navigator.of(
                                                            context,
                                                          ).pop(),
                                                  tooltip: 'Close',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                  );
                                  break;
                                case 'edit':
                                  _editTemplate(template);
                                  break;
                                case 'duplicate':
                                  _duplicateTemplate(template);
                                  break;
                                case 'delete':
                                  _deleteTemplate(template);
                                  break;
                              }
                            },
                            itemBuilder:
                                (context) => [
                                  const PopupMenuItem(
                                    value: 'preview',
                                    child: Text('Preview'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'duplicate',
                                    child: Text('Duplicate'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatePreview(DynamicLabelTemplate template) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  template.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Edit'),
                onPressed: () => _editTemplate(template),
              ),
            ],
          ),
        ),

        // Template info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                'Size',
                '${template.widthCm} × ${template.heightCm} cm',
              ),
              _buildInfoChip(
                'Layout',
                '${template.columnsPerPage} × ${template.rowsPerPage}',
              ),
              _buildInfoChip(
                'Labels/Page',
                '${template.columnsPerPage * template.rowsPerPage}',
              ),
              _buildInfoChip('Rows', '${template.visibleRows.length} visible'),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Preview section
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Preview',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),

        const SizedBox(height: 16),

        Expanded(
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: DynamicLabelWidget(
                product: _previewProduct,
                template: template,
                scaleFactor: 3.0,
              ),
            ),
          ),
        ),

        // Row details
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Label Content',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...template.visibleRows.map((row) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        row.visible ? Icons.visibility : Icons.visibility_off,
                        size: 16,
                        color: row.visible ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getRowDescription(row),
                          style: TextStyle(
                            fontSize: 12,
                            color: row.visible ? Colors.black87 : Colors.grey,
                          ),
                        ),
                      ),
                      Text(
                        '${row.fontSize.toInt()}pt',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
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

  String _getRowDescription(LabelRow row) {
    switch (row.type) {
      case LabelRowType.persianNameWithSize:
        return 'Persian Name with Size (RTL)';
      case LabelRowType.englishNameWithSize:
        return 'English Name with Size';
      case LabelRowType.persianName:
        return 'Persian Name (RTL)';
      case LabelRowType.englishName:
        return 'English Name';
      case LabelRowType.persianBrand:
        return 'Persian Brand (RTL)';
      case LabelRowType.englishBrand:
        return 'English Brand';
      case LabelRowType.persianNameBrand:
        return 'Persian Name + Brand (RTL)';
      case LabelRowType.englishNameBrand:
        return 'English Name + Brand';
      case LabelRowType.persianSize:
        return 'Persian Size (RTL)';
      case LabelRowType.englishSize:
        return 'English Size';
      case LabelRowType.price:
        return 'Price (\$XX.XX)';
      case LabelRowType.priceWithUnit:
        return 'Price with Unit (\$XX.XX /unit)';
      case LabelRowType.barcode:
        return 'Barcode/PLU';
      case LabelRowType.customText:
        return 'Custom Text: "${row.customText ?? ""}"';
      case LabelRowType.empty:
        return 'Empty Space';
    }
  }

  void _createNewTemplate() {
    final newTemplate = DynamicLabelTemplate(
      name: 'New Template ${_templates.length + 1}',
      widthCm: 10.0,
      heightCm: 3.0,
      columnsPerPage: 2,
      rowsPerPage: 8,
      labelRows: const [
        LabelRow(
          type: LabelRowType.persianNameWithSize,
          fontSize: 14.0,
          fontWeight: LabelFontWeight.bold,
          isRTL: true,
        ),
        LabelRow(type: LabelRowType.englishNameWithSize, fontSize: 12.0),
        LabelRow(
          type: LabelRowType.priceWithUnit,
          fontSize: 16.0,
          fontWeight: LabelFontWeight.bold,
        ),
      ],
    );

    _editTemplate(newTemplate, isNew: true);
  }

  void _editTemplate(DynamicLabelTemplate template, {bool isNew = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => DynamicLabelTemplateEditor(
              template: template,
              previewProduct: _previewProduct,
              onTemplateChanged: (updatedTemplate) {
                setState(() {
                  if (isNew) {
                    _templates.add(updatedTemplate);
                  } else {
                    final index = _templates.indexOf(template);
                    if (index != -1) {
                      _templates[index] = updatedTemplate;
                    }
                  }
                  _selectedTemplate = updatedTemplate;
                });
              },
            ),
      ),
    );
  }

  void _duplicateTemplate(DynamicLabelTemplate template) {
    final duplicated = template.copyWith(name: '${template.name} (Copy)');

    setState(() {
      _templates.add(duplicated);
      _selectedTemplate = duplicated;
    });
  }

  void _deleteTemplate(DynamicLabelTemplate template) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Template'),
            content: Text(
              'Are you sure you want to delete "${template.name}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _templates.remove(template);
                    if (_selectedTemplate == template) {
                      _selectedTemplate =
                          _templates.isNotEmpty ? _templates.first : null;
                    }
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  Future<void> _printLabels() async {
    if (widget.products == null || _selectedTemplate == null) return;

    setState(() {
      _isPrinting = true;
    });

    try {
      final pdfBytes = await DynamicPrintService.generatePdf(
        products: widget.products!,
        template: _selectedTemplate!,
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
