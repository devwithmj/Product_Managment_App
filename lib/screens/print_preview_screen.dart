import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

/// Custom print preview modal dialog with proper navigation controls
class PrintPreviewDialog extends StatelessWidget {
  final Uint8List pdfBytes;
  final String title;
  final VoidCallback? onBack;

  const PrintPreviewDialog({
    super.key,
    required this.pdfBytes,
    this.title = 'Print Preview',
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              if (onBack != null) {
                onBack!();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () => _handlePrint(context),
              tooltip: 'Print',
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _handleShare(context),
              tooltip: 'Share',
            ),
          ],
        ),
        body: PdfPreview(
          build: (format) => pdfBytes,
          initialPageFormat: PdfPageFormat.letter,
          pdfFileName: '${title.replaceAll(' ', '_').toLowerCase()}.pdf',
          canChangePageFormat: true,
          canDebug: false,
          actions: [
            // Custom action buttons
            PdfPreviewAction(
              icon: const Icon(Icons.print, color: Colors.white),
              onPressed: (context, build, format) => _handlePrint(context),
            ),
            PdfPreviewAction(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: (context, build, format) => _handleShare(context),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            if (onBack != null) {
              onBack!();
            } else {
              Navigator.of(context).pop();
            }
          },
          icon: const Icon(Icons.close),
          label: const Text('Close'),
          backgroundColor: Colors.grey[600],
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Future<void> _handlePrint(BuildContext context) async {
    try {
      await Printing.layoutPdf(
        onLayout: (format) => pdfBytes,
        name: title,
        usePrinterSettings: true,
      );
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackbar(context, 'Error printing: $e');
      }
    }
  }

  Future<void> _handleShare(BuildContext context) async {
    try {
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: '${title.replaceAll(' ', '_').toLowerCase()}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackbar(context, 'Error sharing: $e');
      }
    }
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}

/// Compact print preview modal (smaller frame)
class CompactPrintPreviewDialog extends StatelessWidget {
  final Uint8List pdfBytes;
  final String title;
  final VoidCallback? onBack;

  const CompactPrintPreviewDialog({
    super.key,
    required this.pdfBytes,
    this.title = 'Print Preview',
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16.0),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Column(
          children: [
            // Custom app bar
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        if (onBack != null) {
                          onBack!();
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.print, color: Colors.white),
                      onPressed: () => _handlePrint(context),
                      tooltip: 'Print',
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.white),
                      onPressed: () => _handleShare(context),
                      tooltip: 'Share',
                    ),
                  ],
                ),
              ),
            ),
            // PDF Preview content
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: PdfPreview(
                  build: (format) => pdfBytes,
                  initialPageFormat: PdfPageFormat.letter,
                  pdfFileName:
                      '${title.replaceAll(' ', '_').toLowerCase()}.pdf',
                  canChangePageFormat: false,
                  canDebug: false,
                  useActions: false, // Disable default actions to save space
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePrint(BuildContext context) async {
    try {
      await Printing.layoutPdf(
        onLayout: (format) => pdfBytes,
        name: title,
        usePrinterSettings: true,
      );
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackbar(context, 'Error printing: $e');
      }
    }
  }

  Future<void> _handleShare(BuildContext context) async {
    try {
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: '${title.replaceAll(' ', '_').toLowerCase()}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackbar(context, 'Error sharing: $e');
      }
    }
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}

/// Custom print preview screen with proper navigation controls (kept for compatibility)
class PrintPreviewScreen extends StatelessWidget {
  final Uint8List pdfBytes;
  final String title;
  final VoidCallback? onBack;

  const PrintPreviewScreen({
    super.key,
    required this.pdfBytes,
    this.title = 'Print Preview',
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (onBack != null) {
              onBack!();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _handlePrint(context),
            tooltip: 'Print',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _handleShare(context),
            tooltip: 'Share',
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => pdfBytes,
        initialPageFormat: PdfPageFormat.letter,
        pdfFileName: '${title.replaceAll(' ', '_').toLowerCase()}.pdf',
        canChangePageFormat: true,
        canDebug: false,
        actions: [
          // Custom action buttons
          PdfPreviewAction(
            icon: const Icon(Icons.print, color: Colors.white),
            onPressed: (context, build, format) => _handlePrint(context),
          ),
          PdfPreviewAction(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: (context, build, format) => _handleShare(context),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => _handlePrint(context),
            backgroundColor: Theme.of(context).primaryColor,
            heroTag: "print_fab",
            child: const Icon(Icons.print, color: Colors.white),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            onPressed: () {
              if (onBack != null) {
                onBack!();
              } else {
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
            backgroundColor: Colors.grey[600],
            foregroundColor: Colors.white,
            heroTag: "back_fab",
          ),
        ],
      ),
    );
  }

  Future<void> _handlePrint(BuildContext context) async {
    try {
      await Printing.layoutPdf(
        onLayout: (format) => pdfBytes,
        name: title,
        usePrinterSettings: true,
      );
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackbar(context, 'Error printing: $e');
      }
    }
  }

  Future<void> _handleShare(BuildContext context) async {
    try {
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: '${title.replaceAll(' ', '_').toLowerCase()}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackbar(context, 'Error sharing: $e');
      }
    }
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}

/// Helper class to show the print preview screen
class PrintPreviewHelper {
  /// Show compact print preview in a dialog (recommended for mobile)
  static Future<void> showCompactPreview({
    required BuildContext context,
    required Uint8List pdfBytes,
    String title = 'Print Preview',
    VoidCallback? onBack,
  }) async {
    if (pdfBytes.isEmpty) {
      throw Exception('PDF data is empty');
    }

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => CompactPrintPreviewDialog(
            pdfBytes: pdfBytes,
            title: title,
            onBack: onBack ?? () => Navigator.of(context).pop(),
          ),
    );
  }

  /// Show fullscreen print preview dialog
  static Future<void> showFullscreenDialog({
    required BuildContext context,
    required Uint8List pdfBytes,
    String title = 'Print Preview',
    VoidCallback? onBack,
  }) async {
    if (pdfBytes.isEmpty) {
      throw Exception('PDF data is empty');
    }

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => PrintPreviewDialog(
            pdfBytes: pdfBytes,
            title: title,
            onBack: onBack ?? () => Navigator.of(context).pop(),
          ),
    );
  }

  /// Show print preview in a new screen with navigation controls (legacy)
  static Future<void> showPreview({
    required BuildContext context,
    required Uint8List pdfBytes,
    String title = 'Print Preview',
    VoidCallback? onBack,
  }) async {
    if (pdfBytes.isEmpty) {
      throw Exception('PDF data is empty');
    }

    // Use compact dialog by default for better UX
    await showCompactPreview(
      context: context,
      pdfBytes: pdfBytes,
      title: title,
      onBack: onBack,
    );
  }

  /// Show print preview in a new full screen (original behavior)
  static Future<void> showFullscreenPreview({
    required BuildContext context,
    required Uint8List pdfBytes,
    String title = 'Print Preview',
    VoidCallback? onBack,
  }) async {
    if (pdfBytes.isEmpty) {
      throw Exception('PDF data is empty');
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => PrintPreviewScreen(
              pdfBytes: pdfBytes,
              title: title,
              onBack: onBack,
            ),
      ),
    );
  }

  /// Simple system print dialog (original behavior) - kept for compatibility
  static Future<void> showSystemPrintDialog({
    required BuildContext context,
    required Uint8List pdfBytes,
    String title = 'Print Preview',
  }) async {
    if (pdfBytes.isEmpty) {
      throw Exception('PDF data is empty');
    }

    await Printing.layoutPdf(
      onLayout: (format) => pdfBytes,
      name: title,
      usePrinterSettings: true,
    );
  }
}
