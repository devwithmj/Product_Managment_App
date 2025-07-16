# AI Coding Instructions for Product Management App

This is a **Flutter mobile application** for generating and printing product labels with **bilingual support (English/Persian)** and **barcode scanning**. The app manages products in a local SQLite database and generates PDF labels for printing.

## Architecture Overview

### Core Components
- **Models**: Product data models with Persian/English dual language support (`lib/models/`)
- **Services**: Database persistence, PDF generation, and printing services (`lib/services/`)  
- **Screens**: Main UI flows for product management and label printing (`lib/screens/`)
- **Utils**: Label layout calculations and formatting utilities (`lib/utils/`)
- **Widgets**: Reusable UI components for labels and product items (`lib/widgets/`)

### Key Data Flow
1. **Product Management**: `ProductListScreen` → `DatabaseService` → SQLite with JSON backup fallback
2. **Label Generation**: `PrintScreen` → `PrintService` → PDF generation → System print dialog
3. **Layout Calculation**: `LabelLayout` calculates positions → `LabelWidget` renders → PDF or screen display

## Critical Patterns & Conventions

### Database Architecture
- **Hybrid persistence**: SQLite primary + JSON file backup for iOS compatibility
- **Schema versioning**: Migrations handled in `DatabaseService._onUpgrade()` with version tracking in `AppConfig.databaseVersion`
- **Graceful degradation**: Falls back to file-based storage when SQLite fails (read-only scenarios)

```dart
// Always check database status before operations
bool isReadOnly = await _databaseService.isDatabaseReadOnly();
```

### Bilingual Implementation
- **Dual text fields**: All products have `nameEn`/`nameFa`, `brandEn`/`brandFa` properties
- **Font management**: English uses 'Roboto', Persian uses 'Vazirmatn' (`AppFonts` in constants)
- **RTL support**: Persian text wrapped in `Directionality(textDirection: TextDirection.rtl)`

### Label System Architecture
- **Template-driven**: `LabelTemplates` defines physical dimensions, margins, font sizes
- **Dual coordinate systems**: 
  - Screen display uses pixels (`LabelLayout.calculateLabelPositions()`)
  - PDF generation uses points (`LabelLayout.calculateLabelPositionsForPDF()`)
- **Multi-layout support**: Standard 2-column vs compact 3-column layouts detected by `columnsPerPage`

```dart
// Standard label templates include Avery 5160, custom sizes
LabelSize selectedSize = LabelTemplates.avery5160; // 6.67cm x 2.54cm, 3x10 grid
```

### PDF Generation Workflow
1. **Font loading**: Persian fonts loaded from assets (`Vazirmatn-Regular.ttf`, `Vazirmatn-Bold.ttf`)
2. **Layout calculation**: `LabelLayout.organizeProductsIntoPages()` chunks products by template capacity
3. **Rendering**: Different layouts based on `labelSize.columnsPerPage` (2-col standard vs 3-col compact)
4. **Price formatting**: Special handling for `$XX.XX` format with separate cents rendering

## Development Workflows

### Adding New Label Templates
1. Define dimensions in `LabelTemplates` class following existing pattern
2. Add to `LabelTemplates.allSizes` list
3. Test with `LabelArrangementHelper.validateAllTemplates()` for page fit validation

### Database Schema Changes
1. Increment `AppConfig.databaseVersion`
2. Add migration logic in `DatabaseService._onUpgrade()`
3. Handle both SQLite and JSON backup formats
4. Test read-only fallback scenarios

### Testing Label Layouts
```bash
# Run with device/simulator to test printing pipeline
flutter run
# Use label preview screen for visual validation
# Check PDF output in temp directory (debug mode)
```

## Critical Dependencies

- **`sqflite`**: Primary database with fallback handling
- **`pdf` + `printing`**: Label generation and system print integration  
- **`mobile_scanner`**: Barcode scanning for product lookup
- **`auto_size_text`**: Dynamic text sizing for label constraints
- **Custom fonts**: Persian support requires Vazirmatn font family

## Common Issues & Solutions

### PDF Generation Errors
- Font loading failures fall back to default fonts (check `_loadFonts()` error handling)
- Empty product lists generate blank page with message
- Label positioning validated with debug output in console

### Database Corruption
- App detects read-only state and shows repair dialog
- Backup/restore functionality via JSON files in documents directory
- Manual database reset available through settings

### Persian Text Rendering
- Always wrap Persian text in `Directionality` widget
- Use `AppFonts.persianFont` consistently
- Font size scaling differs between Persian and English (`persianFontSize` vs `englishFontSize`)

---

*Focus on bilingual label printing workflows and robust database handling when making changes.*
