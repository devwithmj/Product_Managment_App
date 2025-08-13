#!/bin/bash

# App Icon Installer Script for Product Management App
# This script takes your source icon and places it in all required locations

echo "🎨 Product Management App - Icon Installer"
echo "==========================================="

# Check if source icon exists
if [ ! -f "app_icon_source/icon_1024.png" ]; then
    echo "❌ Source icon not found!"
    echo "Please place your icon (1024x1024 PNG) at: app_icon_source/icon_1024.png"
    echo ""
    echo "💡 Your icon should:"
    echo "  - Be 1024x1024 pixels"
    echo "  - Have transparent background (PNG format)"
    echo "  - Be recognizable at small sizes (16x16)"
    echo "  - Match your app's theme"
    echo ""
    exit 1
fi

echo "✅ Source icon found: app_icon_source/icon_1024.png"

# Check if ImageMagick is available for resizing
if command -v magick >/dev/null 2>&1; then
    echo "✅ ImageMagick found - generating all icon sizes..."
    echo ""
    
    # Create backup of existing icons
    echo "📦 Creating backup of existing icons..."
    mkdir -p icon_backup/android
    mkdir -p icon_backup/ios
    
    # Backup Android icons
    cp -r android/app/src/main/res/mipmap-* icon_backup/android/ 2>/dev/null || true
    
    # Backup iOS icons
    cp -r ios/Runner/Assets.xcassets/AppIcon.appiconset/* icon_backup/ios/ 2>/dev/null || true
    
    echo "✅ Backup complete"
    echo ""
    
    # Generate Android Icons
    echo "📱 Generating Android icons..."
    magick app_icon_source/icon_1024.png -resize 48x48 android/app/src/main/res/mipmap-mdpi/ic_launcher.png
    magick app_icon_source/icon_1024.png -resize 72x72 android/app/src/main/res/mipmap-hdpi/ic_launcher.png
    magick app_icon_source/icon_1024.png -resize 96x96 android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
    magick app_icon_source/icon_1024.png -resize 144x144 android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
    magick app_icon_source/icon_1024.png -resize 192x192 android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
    echo "  ✅ Android icons generated (5 sizes)"
    
    # Generate iOS Icons  
    echo "🍎 Generating iOS icons..."
    magick app_icon_source/icon_1024.png -resize 1024x1024 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png
    magick app_icon_source/icon_1024.png -resize 20x20 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png
    magick app_icon_source/icon_1024.png -resize 40x40 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png
    magick app_icon_source/icon_1024.png -resize 60x60 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png
    magick app_icon_source/icon_1024.png -resize 29x29 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png
    magick app_icon_source/icon_1024.png -resize 58x58 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png
    magick app_icon_source/icon_1024.png -resize 87x87 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png
    magick app_icon_source/icon_1024.png -resize 40x40 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png
    magick app_icon_source/icon_1024.png -resize 80x80 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png
    magick app_icon_source/icon_1024.png -resize 120x120 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png
    magick app_icon_source/icon_1024.png -resize 120x120 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png
    magick app_icon_source/icon_1024.png -resize 180x180 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png
    magick app_icon_source/icon_1024.png -resize 76x76 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png
    magick app_icon_source/icon_1024.png -resize 152x152 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png
    magick app_icon_source/icon_1024.png -resize 167x167 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png
    echo "  ✅ iOS icons generated (15 sizes)"
    
    echo ""
    echo "🎉 Icons installed successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Run: flutter clean"
    echo "2. Run: flutter build apk (for Android)"
    echo "3. Run: flutter build ios (for iOS)"
    echo "4. Uninstall old app from device"
    echo "5. Install new app to see your custom icon"
    echo ""
    echo "💾 Original icons backed up to: icon_backup/"
    
elif command -v sips >/dev/null 2>&1; then
    echo "✅ SIPS found (macOS) - generating all icon sizes..."
    echo ""
    
    # Similar process with SIPS (macOS native)
    # Android Icons
    echo "📱 Generating Android icons with SIPS..."
    sips -z 48 48 app_icon_source/icon_1024.png --out android/app/src/main/res/mipmap-mdpi/ic_launcher.png
    sips -z 72 72 app_icon_source/icon_1024.png --out android/app/src/main/res/mipmap-hdpi/ic_launcher.png
    sips -z 96 96 app_icon_source/icon_1024.png --out android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
    sips -z 144 144 app_icon_source/icon_1024.png --out android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
    sips -z 192 192 app_icon_source/icon_1024.png --out android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
    echo "  ✅ Android icons generated"
    
    # iOS Icons
    echo "🍎 Generating iOS icons with SIPS..."
    sips -z 1024 1024 app_icon_source/icon_1024.png --out ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png
    sips -z 20 20 app_icon_source/icon_1024.png --out ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png
    sips -z 40 40 app_icon_source/icon_1024.png --out ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png
    sips -z 60 60 app_icon_source/icon_1024.png --out ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png
    sips -z 29 29 app_icon_source/icon_1024.png --out ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png
    sips -z 58 58 app_icon_source/icon_1024.png --out ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png
    sips -z 87 87 app_icon_source/icon_1024.png --out ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png
    sips -z 40 40 app_icon_source/icon_1024.png --out ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png
    sips -z 80 80 app_icon_source/icon_1024.png --out ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png
    sips -z 120 120 app_icon_source/icon_1024.png --out ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png
    sips -z 120 120 app_icon_source/icon_1024.png --out ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png
    sips -z 180 180 app_icon_source/icon_1024.png --out ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png
    sips -z 76 76 app_icon_source/icon_1024.png --out ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png
    sips -z 152 152 app_icon_source/icon_1024.png --out ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png
    sips -z 167 167 app_icon_source/icon_1024.png --out ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png
    echo "  ✅ iOS icons generated"
    
    echo ""
    echo "🎉 Icons installed successfully!"
    
else
    echo "⚠️  No image resizing tools found"
    echo ""
    echo "� Install ImageMagick or use manual method:"
    echo ""
    echo "🔧 Install ImageMagick:"
    echo "  macOS: brew install imagemagick"
    echo "  Ubuntu: sudo apt-get install imagemagick"
    echo "  Windows: choco install imagemagick"
    echo ""
    echo "📋 Or use online tool:"
    echo "1. Go to https://appicon.co/"
    echo "2. Upload your app_icon_source/icon_1024.png"
    echo "3. Download generated icons"
    echo "4. Replace files in android/app/src/main/res/mipmap-*/"
    echo "5. Replace files in ios/Runner/Assets.xcassets/AppIcon.appiconset/"
fi

echo ""
