# Dynamic Label Template System

This is a comprehensive dynamic label template system for the Product Management App that allows you to create fully customizable label layouts with bilingual support.

## Features

### 🎨 **Dynamic Row Configuration**
- Add, remove, and reorder rows in labels
- Each row can display different product information
- Customizable font sizes, alignments, and weights
- Show/hide individual rows
- RTL (Right-to-Left) support for Persian text

### 📋 **Available Row Types**
1. **Persian Name with Size** - `product.fullNameFa (persian size)`
2. **English Name with Size** - `product.fullNameEn (size)`
3. **Persian Name Only** - `product.nameFa`
4. **English Name Only** - `product.nameEn`
5. **Persian Brand** - `product.brandFa`
6. **English Brand** - `product.brandEn`
7. **Persian Name + Brand** - `product.nameFa product.brandFa`
8. **English Name + Brand** - `product.brandEn product.nameEn`
9. **Persian Size** - `product.persianSize`
10. **English Size** - `product.size`
11. **Price** - `$XX.XX`
12. **Price with Unit** - `$XX.XX /unit (lb/kg/ea/100gr)`
13. **Barcode/PLU** - `PLU# XXXXX`
14. **Custom Text** - Static custom text
15. **Empty Space** - For layout spacing

### 🏷️ **Pre-configured Templates**
- **Standard Bilingual**: Persian name + size, English name + size, price with unit, barcode
- **Compact 3-Column**: Smaller labels for higher density
- **Avery 5160 Compatible**: Standard address label format
- **Price Focus**: Emphasizes pricing information

## Usage

### Basic Usage

```dart
import 'package:product_app/models/dynamic_label_template.dart';
import 'package:product_app/services/dynamic_print_service.dart';
import 'package:product_app/screens/dynamic_print_screen.dart';

// Use a pre-configured template
final template = DynamicLabelTemplates.standard;

// Print labels
final pdfBytes = await DynamicPrintService.generatePdf(
  products: myProducts,
  template: template,
);

await DynamicPrintService.showPrintPreview(context, pdfBytes);
```

### Creating Custom Templates

```dart
final customTemplate = DynamicLabelTemplate(
  name: "My Custom Template",
  widthCm: 10.0,
  heightCm: 3.0,
  columnsPerPage: 2,
  rowsPerPage: 8,
  labelRows: [
    LabelRow(
      type: LabelRowType.persianNameWithSize,
      alignment: LabelTextAlignment.center,
      fontWeight: LabelFontWeight.bold,
      fontSize: 14.0,
      isRTL: true,
    ),
    LabelRow(
      type: LabelRowType.priceWithUnit,
      fontSize: 16.0,
      fontWeight: LabelFontWeight.bold,
    ),
    LabelRow(
      type: LabelRowType.customText,
      customText: "Fresh & Organic",
      fontSize: 10.0,
    ),
  ],
);
```

### Integration with Existing Code

#### Option 1: Replace existing print service calls
```dart
// OLD:
// await PrintService.generatePdf(products: products, labelSize: labelSize);

// NEW:
await DynamicPrintService.generatePdf(
  products: products, 
  template: DynamicLabelTemplates.standard
);
```

#### Option 2: Use the new print screen
```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => DynamicPrintScreen(products: selectedProducts),
  ),
);
```

#### Option 3: Template management screen
```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => DynamicLabelTemplatesScreen(products: products),
  ),
);
```

## Template Configuration

### Physical Dimensions
- `widthCm`, `heightCm`: Label size in centimeters
- `columnsPerPage`, `rowsPerPage`: Grid layout on letter-size paper
- `horizontalSpacingCm`, `verticalSpacingCm`: Spacing between labels
- `pageMargin*`: Margins around the printable area
- `paddingCm`: Inner padding within each label

### Row Configuration
Each `LabelRow` has:
- `type`: What content to display (see row types above)
- `alignment`: Left, center, or right alignment
- `fontWeight`: Normal or bold
- `fontSize`: Font size in points
- `isRTL`: Whether to use right-to-left text direction (for Persian)
- `customText`: Custom text when type is `customText`
- `visible`: Whether to show this row

## Example Templates

### Your Requested Template
```dart
static const requestedTemplate = DynamicLabelTemplate(
  name: "Requested Format",
  widthCm: 10.0,
  heightCm: 3.0,
  columnsPerPage: 2,
  rowsPerPage: 8,
  labelRows: [
    // Row 1: product.fullNameFa (${product.persianSize})
    LabelRow(
      type: LabelRowType.persianNameWithSize,
      alignment: LabelTextAlignment.center,
      fontWeight: LabelFontWeight.bold,
      fontSize: 14.0,
      isRTL: true,
    ),
    // Row 2: product.fullNameEn (${product.size})
    LabelRow(
      type: LabelRowType.englishNameWithSize,
      alignment: LabelTextAlignment.center,
      fontSize: 12.0,
    ),
    // Row 3: product.price product.cent / (selling type)
    LabelRow(
      type: LabelRowType.priceWithUnit,
      alignment: LabelTextAlignment.center,
      fontWeight: LabelFontWeight.bold,
      fontSize: 16.0,
    ),
  ],
);
```

### Compact Price-focused Template
```dart
static const priceFocusTemplate = DynamicLabelTemplate(
  name: "Price Focus",
  widthCm: 8.0,
  heightCm: 2.5,
  columnsPerPage: 3,
  rowsPerPage: 10,
  labelRows: [
    LabelRow(
      type: LabelRowType.persianName,
      fontSize: 10.0,
      isRTL: true,
      fontWeight: LabelFontWeight.bold,
    ),
    LabelRow(
      type: LabelRowType.priceWithUnit,
      fontSize: 20.0,
      fontWeight: LabelFontWeight.bold,
    ),
    LabelRow(
      type: LabelRowType.barcode,
      fontSize: 8.0,
    ),
  ],
);
```

## Migration Guide

### From Static Templates
1. **Replace imports**:
   ```dart
   // OLD
   import '../models/label_template.dart';
   import '../services/print_service.dart';
   
   // NEW
   import '../models/dynamic_label_template.dart';
   import '../services/dynamic_print_service.dart';
   ```

2. **Update print calls**:
   ```dart
   // OLD
   final pdfBytes = await PrintService.generatePdf(
     products: products,
     labelSize: LabelTemplates.avery5160,
   );
   
   // NEW
   final pdfBytes = await DynamicPrintService.generatePdf(
     products: products,
     template: DynamicLabelTemplates.avery5160,
   );
   ```

3. **Update UI components**:
   ```dart
   // OLD
   LabelWidget(product: product, labelSize: labelSize)
   
   // NEW
   DynamicLabelWidget(product: product, template: template)
   ```

## Files Added

- `lib/models/dynamic_label_template.dart` - Core template and row definitions
- `lib/services/dynamic_print_service.dart` - PDF generation using dynamic templates
- `lib/widgets/dynamic_label_widget.dart` - UI widget and template editor
- `lib/screens/dynamic_label_templates_screen.dart` - Template management screen
- `lib/screens/dynamic_print_screen.dart` - Print screen with template selection

## Benefits

1. **Flexibility**: Create any label layout you need
2. **Bilingual Support**: Full Persian/English support with proper RTL handling
3. **Easy Customization**: Visual editor for creating/editing templates
4. **Backward Compatibility**: Can coexist with existing print system
5. **Professional Output**: High-quality PDF generation with proper fonts
6. **Template Reuse**: Save and reuse custom templates

## Next Steps

1. **Test the system** with your existing products
2. **Create custom templates** for your specific needs
3. **Replace existing print screens** gradually
4. **Add template persistence** (save/load from database)
5. **Add more row types** as needed

The system is designed to be a complete replacement for the existing static label system while providing much more flexibility and customization options.
