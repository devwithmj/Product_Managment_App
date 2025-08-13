import 'package:flutter/material.dart';
import '../services/storage_permission_service.dart';

/// Widget to handle storage permission requests with user-friendly UI
class StoragePermissionHandler extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPermissionGranted;
  final VoidCallback? onPermissionDenied;

  const StoragePermissionHandler({
    super.key,
    required this.child,
    this.onPermissionGranted,
    this.onPermissionDenied,
  });

  @override
  State<StoragePermissionHandler> createState() =>
      _StoragePermissionHandlerState();
}

class _StoragePermissionHandlerState extends State<StoragePermissionHandler> {
  bool _isCheckingPermission = false;

  /// Request storage permission with user-friendly dialogs
  Future<bool> requestPermissionWithDialog() async {
    setState(() {
      _isCheckingPermission = true;
    });

    try {
      // First, show explanation dialog
      final shouldRequest = await StoragePermissionService.showPermissionDialog(
        context,
      );
      if (!shouldRequest) {
        widget.onPermissionDenied?.call();
        return false;
      }

      // Request permission
      final result = await StoragePermissionService.requestStoragePermissions();

      switch (result) {
        case StoragePermissionResult.granted:
          widget.onPermissionGranted?.call();
          _showSuccessMessage();
          return true;

        case StoragePermissionResult.denied:
          _showDeniedMessage();
          widget.onPermissionDenied?.call();
          return false;

        case StoragePermissionResult.permanentlyDenied:
          await StoragePermissionService.showSettingsDialog(context);
          widget.onPermissionDenied?.call();
          return false;

        case StoragePermissionResult.error:
          _showErrorMessage();
          widget.onPermissionDenied?.call();
          return false;
      }
    } finally {
      setState(() {
        _isCheckingPermission = false;
      });
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Storage permission granted successfully'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showDeniedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '❌ Storage permission denied. Some features may not work.',
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚠️ Error requesting storage permission'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isCheckingPermission)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Checking storage permission...',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Simple button to request storage permission
class StoragePermissionButton extends StatefulWidget {
  final String text;
  final VoidCallback? onSuccess;
  final VoidCallback? onFailure;

  const StoragePermissionButton({
    super.key,
    this.text = 'Request Storage Permission',
    this.onSuccess,
    this.onFailure,
  });

  @override
  State<StoragePermissionButton> createState() =>
      _StoragePermissionButtonState();
}

class _StoragePermissionButtonState extends State<StoragePermissionButton> {
  bool _isLoading = false;

  Future<void> _requestPermission() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await StoragePermissionService.requestStoragePermissions();

      if (result == StoragePermissionResult.granted) {
        widget.onSuccess?.call();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Storage permission granted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        widget.onFailure?.call();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Storage permission ${result.name}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _requestPermission,
      icon:
          _isLoading
              ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : const Icon(Icons.folder_open),
      label: Text(widget.text),
    );
  }
}
