import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

/// Simple App Icon Generator Widget
/// This generates basic app icons programmatically without external packages
class AppIconGenerator extends StatefulWidget {
  const AppIconGenerator({super.key});

  @override
  State<AppIconGenerator> createState() => _AppIconGeneratorState();
}

class _AppIconGeneratorState extends State<AppIconGenerator> {
  final GlobalKey _iconKey = GlobalKey();
  bool _isGenerating = false;
  String _status = 'Ready to generate icons';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Icon Generator'),
        backgroundColor: const Color(0xFF2196F3),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Preview of the icon design
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: RepaintBoundary(key: _iconKey, child: _buildIconDesign()),
            ),

            const SizedBox(height: 24),

            Text(
              _status,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            if (!_isGenerating)
              ElevatedButton.icon(
                onPressed: _generateIcons,
                icon: const Icon(Icons.create),
                label: const Text('Generate App Icons'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              )
            else
              const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildIconDesign() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF2196F3), const Color(0xFF1976D2)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: CustomPaint(painter: _BackgroundPatternPainter()),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Barcode icon representation
                Container(
                  width: 80,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomPaint(painter: _BarcodePainter()),
                ),

                const SizedBox(height: 12),

                // App name
                const Text(
                  'PM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // Persian text
                const Text(
                  'محصول',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateIcons() async {
    setState(() {
      _isGenerating = true;
      _status = 'Generating icons...';
    });

    try {
      // Capture the widget as an image
      RenderRepaintBoundary boundary =
          _iconKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 5.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        Uint8List pngBytes = byteData.buffer.asUint8List();

        // Save to documents directory for preview
        Directory documentsDir = await getApplicationDocumentsDirectory();
        File file = File('${documentsDir.path}/generated_app_icon.png');
        await file.writeAsBytes(pngBytes);

        setState(() {
          _status =
              'Icon saved to:\n${file.path}\n\nNow manually replace icon files in:\n- android/app/src/main/res/mipmap-*/\n- ios/Runner/Assets.xcassets/AppIcon.appiconset/';
          _isGenerating = false;
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error generating icon: $e';
        _isGenerating = false;
      });
    }
  }
}

class _BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.1)
          ..strokeWidth = 2;

    // Draw subtle grid pattern
    for (int i = 0; i < size.width; i += 20) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble(), size.height),
        paint,
      );
    }

    for (int i = 0; i < size.height; i += 20) {
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(size.width, i.toDouble()),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BarcodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.black
          ..strokeWidth = 2;

    // Draw barcode lines
    final lineWidths = [2.0, 1.0, 3.0, 1.0, 2.0, 1.0, 3.0, 2.0, 1.0, 2.0];
    double x = 8;

    for (int i = 0; i < lineWidths.length; i++) {
      canvas.drawLine(
        Offset(x, 8),
        Offset(x, size.height - 8),
        paint..strokeWidth = lineWidths[i],
      );
      x += lineWidths[i] + 2;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Add this to your app navigation to test the generator
// Navigator.push(
//   context,
//   MaterialPageRoute(builder: (context) => const AppIconGenerator()),
// );
