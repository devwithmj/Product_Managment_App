import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/dynamic_label_template.dart';
import './label_template_creator_screen.dart';
import './dynamic_label_templates_screen.dart';
import './dynamic_print_screen.dart';

/// Demo screen showing all the template management features
class TemplateDemoScreen extends StatefulWidget {
  const TemplateDemoScreen({Key? key}) : super(key: key);

  @override
  State<TemplateDemoScreen> createState() => _TemplateDemoScreenState();
}

class _TemplateDemoScreenState extends State<TemplateDemoScreen> {
  List<DynamicLabelTemplate> _customTemplates = [];
  List<Product> _sampleProducts = [];

  @override
  void initState() {
    super.initState();
    _initializeSampleProducts();
  }

  void _initializeSampleProducts() {
    _sampleProducts = [
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
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Label Template System'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Dynamic Label Template System',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Create, manage, and use custom label templates with bilingual support',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),

            const SizedBox(height: 32),

            // Template Creation Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.add_circle,
                          color: Colors.green.shade600,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Create Templates',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Design custom label layouts with step-by-step wizard',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _createNewTemplate,
                        icon: const Icon(Icons.create),
                        label: const Text('Create New Template'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Template Management Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.settings,
                          color: Colors.blue.shade600,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Manage Templates',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'View, edit, and organize your label templates',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _manageTemplates,
                        icon: const Icon(Icons.dashboard),
                        label: const Text('Template Manager'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Print with Templates Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.print,
                          color: Colors.purple.shade600,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Print with Templates',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Use templates to print labels for your products',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _printWithTemplates,
                        icon: const Icon(Icons.label),
                        label: Text(
                          'Print Sample Labels (${_sampleProducts.length} products)',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Available Templates Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Templates',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pre-built templates
                    const Text(
                      'Pre-built Templates',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...DynamicLabelTemplates.allTemplates
                        .map(
                          (template) => _buildTemplateListItem(
                            template,
                            isPrebuilt: true,
                          ),
                        )
                        .toList(),

                    if (_customTemplates.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Custom Templates',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._customTemplates
                          .map(
                            (template) => _buildTemplateListItem(
                              template,
                              isPrebuilt: false,
                            ),
                          )
                          .toList(),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Sample Products Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sample Products',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._sampleProducts
                        .map((product) => _buildProductListItem(product))
                        .toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateListItem(
    DynamicLabelTemplate template, {
    required bool isPrebuilt,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isPrebuilt ? Colors.blue.shade100 : Colors.green.shade100,
          child: Icon(
            isPrebuilt ? Icons.label : Icons.create,
            color: isPrebuilt ? Colors.blue.shade700 : Colors.green.shade700,
          ),
        ),
        title: Text(template.name),
        subtitle: Text(
          '${template.widthCm} × ${template.heightCm} cm • '
          '${template.columnsPerPage} × ${template.rowsPerPage} layout • '
          '${template.visibleRows.length} rows',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _editTemplate(template),
            ),
            IconButton(
              icon: const Icon(Icons.print, size: 20),
              onPressed: () => _printWithSpecificTemplate(template),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductListItem(Product product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.shade100,
          child: Icon(Icons.inventory, color: Colors.orange.shade700),
        ),
        title: Text('${product.nameEn} / ${product.nameFa}'),
        subtitle: Text(
          '${product.brandEn} • ${product.size} • \$${product.price.toStringAsFixed(2)}',
        ),
        trailing:
            product.barcode.isNotEmpty
                ? Chip(
                  label: Text('PLU: ${product.barcode}'),
                  backgroundColor: Colors.blue.shade50,
                )
                : null,
      ),
    );
  }

  void _createNewTemplate() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => LabelTemplateCreatorScreen(
              onTemplateSaved: (template) {
                setState(() {
                  _customTemplates.add(template);
                });
              },
            ),
      ),
    );
  }

  void _manageTemplates() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => DynamicLabelTemplatesScreen(products: _sampleProducts),
      ),
    );
  }

  void _printWithTemplates() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DynamicPrintScreen(products: _sampleProducts),
      ),
    );
  }

  void _editTemplate(DynamicLabelTemplate template) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => LabelTemplateCreatorScreen(
              initialTemplate: template,
              onTemplateSaved: (updatedTemplate) {
                setState(() {
                  // Update if it's a custom template
                  final index = _customTemplates.indexOf(template);
                  if (index != -1) {
                    _customTemplates[index] = updatedTemplate;
                  }
                });
              },
            ),
      ),
    );
  }

  void _printWithSpecificTemplate(DynamicLabelTemplate template) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DynamicPrintScreen(products: _sampleProducts),
      ),
    );
  }
}
