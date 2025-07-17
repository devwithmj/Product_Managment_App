# Thermal Printer Integration Guide

## Overview
Your Product Management App now supports thermal printer integration alongside the existing PDF printing functionality. This integration is specifically optimized for the **Star TSP100III** thermal printer with **7.9cm** wide thermal labels.

## Features Added

### 1. **Thermal Label Template**
- New `LabelTemplates.thermal` template designed for 7.9cm wide thermal labels
- Optimized font sizes and layout for thermal printing
- Single label printing capability

### 2. **Thermal Print Service**
- **Bluetooth** and **Network** connection support
- Direct ESC/POS command generation for TSP100III
- Single and multiple label printing
- Connection management and status monitoring

### 3. **Enhanced Print Screen**
- **Print Method Selection**: Choose between PDF Printer and Thermal Printer
- **Thermal Printer Settings**: Access configuration and connection setup
- **Connection Status**: Real-time thermal printer connection display
- **Single Label Printing**: Print individual labels directly from product list

### 4. **Thermal Printer Settings Screen**
- **Connection Type**: Toggle between Bluetooth and Network
- **Manual Connection**: Enter MAC address (Bluetooth) or IP address (Network)
- **Test Print**: Verify printer connection with test label
- **Connection Status**: Monitor printer connectivity

## How to Use

### Initial Setup
1. **Install Dependencies**: The app now includes `flutter_thermal_printer: ^1.2.1+1`
2. **Connect Printer**: 
   - For Bluetooth: Ensure TSP100III is in pairing mode
   - For Network: Connect printer to same WiFi network
3. **Configure Connection**: Use the Settings screen to connect to your printer

### Printing Labels

#### Method 1: PDF Printing (Existing)
1. Select "PDF Printer" as print method
2. Choose any label template except "Thermal (7.9cm)"
3. Select products and print as before

#### Method 2: Thermal Printing (New)
1. Select "Thermal" as print method
2. Label size automatically switches to "Thermal (7.9cm)"
3. Ensure thermal printer is connected (green status indicator)
4. **Single Labels**: Click the orange print icon (🖨️) next to any product
5. **Multiple Labels**: Select products and use the main Print button

### Printer Connection Setup

#### Bluetooth Connection
1. Go to Thermal Printer Settings
2. Select "Bluetooth" connection type
3. Enter your TSP100III MAC address (format: 00:11:22:33:44:55)
4. Click "Connect"
5. Use "Test Print" to verify connection

#### Network Connection  
1. Go to Thermal Printer Settings
2. Select "Network" connection type
3. Enter your TSP100III IP address (format: 192.168.1.100)
4. Click "Connect"
5. Use "Test Print" to verify connection

## Technical Details

### ESC/POS Commands
The thermal printer service generates optimized ESC/POS commands:
- **Bold text** for product names and prices
- **Center alignment** for better label appearance
- **UTF-8 encoding** for Persian text support
- **Full cut** command for clean label separation

### Label Layout (7.9cm width)
- **Persian Product Name**: Bold, large font, center-aligned
- **Brand Name**: Normal font (if different from product name)
- **English Product Name**: Medium font, center-aligned  
- **Price**: Bold, large font with proper formatting ($XX.XX)

### Font Sizes (Thermal Template)
- **English Font**: 12pt
- **Persian Font**: 16pt  
- **Price Font**: 22pt

## Troubleshooting

### Connection Issues
- **Bluetooth**: Ensure printer is discoverable and within range
- **Network**: Verify printer and device are on same WiFi network
- **MAC/IP Address**: Double-check address format and accuracy

### Print Quality
- Use genuine thermal paper (7.9cm width)
- Ensure printer is powered on and ready
- Check paper alignment and loading

### Error Messages
- **"Printer not connected"**: Use Settings to establish connection
- **"Test print failed"**: Check power, paper, and connection
- **"Print failed"**: Verify printer status and paper supply

## Files Modified/Added

### New Files
- `lib/services/thermal_print_service.dart` - Thermal printer functionality
- `lib/screens/thermal_printer_settings_screen.dart` - Settings interface

### Modified Files
- `lib/models/label_template.dart` - Added thermal template
- `lib/screens/print_screen.dart` - Added thermal printing support
- `lib/widgets/product_item.dart` - Added single print button
- `pubspec.yaml` - Added thermal printer dependency

## Compatibility
- **Printer**: Star TSP100III (tested and optimized)
- **Label Paper**: 7.9cm thermal labels
- **Connections**: Bluetooth and Network (WiFi)
- **Platforms**: Android, iOS (with appropriate permissions)

## Future Enhancements
- Auto-discovery for Bluetooth printers
- Custom thermal label sizes
- Print queue management
- Multiple printer support
- Batch printing optimization

---

**Note**: This integration maintains full backward compatibility with existing PDF printing functionality. Users can seamlessly switch between printing methods based on their needs.
