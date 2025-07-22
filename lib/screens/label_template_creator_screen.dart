import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/dynamic_label_template.dart';
import '../widgets/dynamic_label_widget.dart';
import 'label_template_preview_screen.dart';

class LabelTemplateCreatorScreen extends StatefulWidget {
  final DynamicLabelTemplate? initialTemplate;
  final Function(DynamicLabelTemplate)? onTemplateSaved;

  const LabelTemplateCreatorScreen({
    Key? key,
    this.initialTemplate,
    this.onTemplateSaved,
  }) : super(key: key);

  @override
  State<LabelTemplateCreatorScreen> createState() =>
      _LabelTemplateCreatorScreenState();
}

class _LabelTemplateCreatorScreenState
    extends State<LabelTemplateCreatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _columnsController = TextEditingController();
  final _rowsController = TextEditingController();

  List<LabelRow> _labelRows = [];
  late Product _previewProduct;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();

    // Initialize with existing template or defaults
    if (widget.initialTemplate != null) {
      final template = widget.initialTemplate!;
      _nameController.text = template.name;
      _widthController.text = template.widthCm.toString();
      _heightController.text = template.heightCm.toString();
      _columnsController.text = template.columnsPerPage.toString();
      _rowsController.text = template.rowsPerPage.toString();
      _labelRows = List.from(template.labelRows);
    } else {
      // Set defaults for new template
      _nameController.text = 'New Template';
      _widthController.text = '10.0';
      _heightController.text = '3.0';
      _columnsController.text = '2';
      _rowsController.text = '8';
      _labelRows = [
        const LabelRow(
          type: LabelRowType.persianNameWithSize,
          fontSize: 14.0,
          fontWeight: LabelFontWeight.bold,
          isRTL: true,
        ),
        const LabelRow(type: LabelRowType.englishNameWithSize, fontSize: 12.0),
        const LabelRow(
          type: LabelRowType.priceWithUnit,
          fontSize: 16.0,
          fontWeight: LabelFontWeight.bold,
        ),
      ];
    }

    // Create sample product for preview
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
  void dispose() {
    _nameController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _columnsController.dispose();
    _rowsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Label Template'),
        actions: [
          IconButton(
            icon: const Icon(Icons.preview),
            onPressed: _showPreview,
            tooltip: 'Preview Template',
          ),
          if (_currentStep == 2) // Show save button on final step
            TextButton(onPressed: _saveTemplate, child: const Text('Save')),
        ],
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: Colors.blue),
        ),
        child: Stepper(
          currentStep: _currentStep,
          onStepTapped: (step) {
            setState(() {
              _currentStep = step;
            });
          },
          controlsBuilder: (context, details) {
            return Row(
              children: [
                if (details.stepIndex < 2)
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    child: const Text('Next'),
                  ),
                if (details.stepIndex == 2)
                  ElevatedButton(
                    onPressed: _saveTemplate,
                    child: const Text('Save Template'),
                  ),
                const SizedBox(width: 8),
                if (details.stepIndex > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
              ],
            );
          },
          steps: [
            Step(
              title: const Text('Basic Settings'),
              content: _buildBasicSettingsStep(),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('Label Content'),
              content: _buildLabelContentStep(),
              isActive: _currentStep >= 1,
              state:
                  _currentStep > 1
                      ? StepState.complete
                      : _currentStep == 1
                      ? StepState.indexed
                      : StepState.disabled,
            ),
            Step(
              title: const Text('Preview & Save'),
              content: _buildPreviewStep(),
              isActive: _currentStep >= 2,
              state: _currentStep == 2 ? StepState.indexed : StepState.disabled,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicSettingsStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Template Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Template Name *',
              hintText: 'Enter a descriptive name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a template name';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),
          const Text(
            'Label Dimensions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _widthController,
                  decoration: const InputDecoration(
                    labelText: 'Width (cm) *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    final width = double.tryParse(value);
                    if (width == null || width <= 0) return 'Invalid width';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _heightController,
                  decoration: const InputDecoration(
                    labelText: 'Height (cm) *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    final height = double.tryParse(value);
                    if (height == null || height <= 0) return 'Invalid height';
                    return null;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Text(
            'Page Layout',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _columnsController,
                  decoration: const InputDecoration(
                    labelText: 'Columns per page *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    final cols = int.tryParse(value);
                    if (cols == null || cols <= 0 || cols > 10)
                      return 'Invalid (1-10)';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _rowsController,
                  decoration: const InputDecoration(
                    labelText: 'Rows per page *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    final rows = int.tryParse(value);
                    if (rows == null || rows <= 0 || rows > 20)
                      return 'Invalid (1-20)';
                    return null;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Total labels per page: ${_calculateLabelsPerPage()}',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildLabelContentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Label Rows',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _addNewRow,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Row'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Configure what information appears on each row of your label',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),

        if (_labelRows.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.label_outline,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No rows added yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add some rows to define your label content',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

        ..._labelRows.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          return _buildRowEditor(row, index);
        }).toList(),

        const SizedBox(height: 16),
        Card(
          color: Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tips_and_updates, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Quick Templates',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildQuickTemplateChip(
                      'Bilingual Standard',
                      _applyBilingualTemplate,
                    ),
                    _buildQuickTemplateChip(
                      'Price Focus',
                      _applyPriceFocusTemplate,
                    ),
                    _buildQuickTemplateChip('Minimal', _applyMinimalTemplate),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewStep() {
    final template = _buildCurrentTemplate();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Template Preview',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Template info summary
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Size: ${template.widthCm} × ${template.heightCm} cm'),
                Text(
                  'Layout: ${template.columnsPerPage} × ${template.rowsPerPage} = ${template.columnsPerPage * template.rowsPerPage} labels/page',
                ),
                Text('Content Rows: ${template.visibleRows.length} visible'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Live preview
        const Text(
          'Label Preview',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DynamicLabelWidget(
              product: _previewProduct,
              template: template,
              scaleFactor: 2.5,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Content breakdown
        const Text(
          'Content Breakdown',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children:
                  template.visibleRows.asMap().entries.map((entry) {
                    final index = entry.key;
                    final row = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
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
                                  '${row.fontSize.toInt()}pt, ${row.fontWeight.name}, ${row.alignment.name}${row.isRTL ? ', RTL' : ''}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            row.generateText(_previewProduct),
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRowEditor(LabelRow row, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<LabelRowType>(
                    value: row.type,
                    isExpanded: true,
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
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeRow(index),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Font Size',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        initialValue: row.fontSize.toString(),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final fontSize =
                              double.tryParse(value) ?? row.fontSize;
                          _updateRow(index, row.copyWith(fontSize: fontSize));
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Weight',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      DropdownButton<LabelFontWeight>(
                        value: row.fontWeight,
                        isExpanded: true,
                        onChanged: (newWeight) {
                          if (newWeight != null) {
                            _updateRow(
                              index,
                              row.copyWith(fontWeight: newWeight),
                            );
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
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alignment',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      DropdownButton<LabelTextAlignment>(
                        value: row.alignment,
                        isExpanded: true,
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
                    ],
                  ),
                ),
              ],
            ),

            if (row.type == LabelRowType.customText) ...[
              const SizedBox(height: 16),
              TextFormField(
                initialValue: row.customText ?? '',
                decoration: const InputDecoration(
                  labelText: 'Custom Text',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _updateRow(index, row.copyWith(customText: value));
                },
              ),
            ],

            const SizedBox(height: 12),

            Row(
              children: [
                Switch(
                  value: row.isRTL,
                  onChanged: (value) {
                    _updateRow(index, row.copyWith(isRTL: value));
                  },
                ),
                const SizedBox(width: 8),
                const Text('Right-to-Left (Persian)'),
                const Spacer(),
                Switch(
                  value: row.visible,
                  onChanged: (value) {
                    _updateRow(index, row.copyWith(visible: value));
                  },
                ),
                const SizedBox(width: 8),
                const Text('Visible'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTemplateChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
      backgroundColor: Colors.green.shade100,
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

  int _calculateLabelsPerPage() {
    final cols = int.tryParse(_columnsController.text) ?? 2;
    final rows = int.tryParse(_rowsController.text) ?? 8;
    return cols * rows;
  }

  void _showPreview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                LabelTemplatePreviewScreen(template: _buildCurrentTemplate()),
      ),
    );
  }

  void _updateRow(int index, LabelRow newRow) {
    setState(() {
      _labelRows[index] = newRow;
    });
  }

  void _removeRow(int index) {
    setState(() {
      _labelRows.removeAt(index);
    });
  }

  void _addNewRow() {
    setState(() {
      _labelRows.add(
        const LabelRow(type: LabelRowType.englishName, fontSize: 12.0),
      );
    });
  }

  void _applyBilingualTemplate() {
    setState(() {
      _labelRows = [
        const LabelRow(
          type: LabelRowType.persianNameWithSize,
          fontSize: 14.0,
          fontWeight: LabelFontWeight.bold,
          isRTL: true,
        ),
        const LabelRow(type: LabelRowType.englishNameWithSize, fontSize: 12.0),
        const LabelRow(
          type: LabelRowType.priceWithUnit,
          fontSize: 16.0,
          fontWeight: LabelFontWeight.bold,
        ),
        const LabelRow(type: LabelRowType.barcode, fontSize: 10.0),
      ];
    });
  }

  void _applyPriceFocusTemplate() {
    setState(() {
      _labelRows = [
        const LabelRow(
          type: LabelRowType.persianName,
          fontSize: 12.0,
          fontWeight: LabelFontWeight.bold,
          isRTL: true,
        ),
        const LabelRow(
          type: LabelRowType.priceWithUnit,
          fontSize: 20.0,
          fontWeight: LabelFontWeight.bold,
        ),
        const LabelRow(type: LabelRowType.barcode, fontSize: 10.0),
      ];
    });
  }

  void _applyMinimalTemplate() {
    setState(() {
      _labelRows = [
        const LabelRow(
          type: LabelRowType.englishName,
          fontSize: 14.0,
          fontWeight: LabelFontWeight.bold,
        ),
        const LabelRow(
          type: LabelRowType.price,
          fontSize: 18.0,
          fontWeight: LabelFontWeight.bold,
        ),
      ];
    });
  }

  DynamicLabelTemplate _buildCurrentTemplate() {
    return DynamicLabelTemplate(
      name:
          _nameController.text.trim().isEmpty
              ? 'New Template'
              : _nameController.text.trim(),
      widthCm: double.tryParse(_widthController.text) ?? 10.0,
      heightCm: double.tryParse(_heightController.text) ?? 3.0,
      columnsPerPage: int.tryParse(_columnsController.text) ?? 2,
      rowsPerPage: int.tryParse(_rowsController.text) ?? 8,
      labelRows: _labelRows,
    );
  }

  void _saveTemplate() {
    if (_formKey.currentState?.validate() ?? false) {
      final template = _buildCurrentTemplate();

      if (widget.onTemplateSaved != null) {
        widget.onTemplateSaved!(template);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Template "${template.name}" saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(template);
    }
  }
}
