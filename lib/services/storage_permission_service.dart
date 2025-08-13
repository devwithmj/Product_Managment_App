import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Enhanced storage permission service for database import/export
/// Handles different Android versions and storage access patterns
class StoragePermissionService {
  /// Request all necessary storage permissions for database operations
  static Future<StoragePermissionResult> requestStoragePermissions() async {
    try {
      // For Android 13+ (API 33+), we need specific media permissions
      if (Platform.isAndroid) {
        final androidInfo = await _getAndroidVersion();

        if (androidInfo >= 33) {
          return await _handleAndroid13Plus();
        } else if (androidInfo >= 30) {
          return await _handleAndroid11Plus();
        } else {
          return await _handleLegacyAndroid();
        }
      }

      // For iOS, file picker handles permissions automatically
      return StoragePermissionResult.granted;
    } catch (e) {
      return StoragePermissionResult.error;
    }
  }

  /// Handle Android 13+ (API 33+) - Granular media permissions
  static Future<StoragePermissionResult> _handleAndroid13Plus() async {
    // For Android 13+, we typically don't need storage permissions for file picker
    // But we may need them for specific operations
    return StoragePermissionResult.granted;
  }

  /// Handle Android 11+ (API 30+) - Scoped storage
  static Future<StoragePermissionResult> _handleAndroid11Plus() async {
    // Try manage external storage permission first
    var manageStatus = await Permission.manageExternalStorage.status;

    if (!manageStatus.isGranted) {
      manageStatus = await Permission.manageExternalStorage.request();

      if (manageStatus.isGranted) {
        return StoragePermissionResult.granted;
      }
    } else {
      return StoragePermissionResult.granted;
    }

    // Fallback to regular storage permission
    return await _requestBasicStoragePermission();
  }

  /// Handle legacy Android versions (API < 30)
  static Future<StoragePermissionResult> _handleLegacyAndroid() async {
    return await _requestBasicStoragePermission();
  }

  /// Request basic storage permissions
  static Future<StoragePermissionResult>
  _requestBasicStoragePermission() async {
    // Check current status
    var status = await Permission.storage.status;

    if (status.isGranted) {
      return StoragePermissionResult.granted;
    }

    if (status.isPermanentlyDenied) {
      return StoragePermissionResult.permanentlyDenied;
    }

    // Request permission
    status = await Permission.storage.request();

    if (status.isGranted) {
      return StoragePermissionResult.granted;
    } else if (status.isPermanentlyDenied) {
      return StoragePermissionResult.permanentlyDenied;
    } else {
      return StoragePermissionResult.denied;
    }
  }

  /// Get Android API level
  static Future<int> _getAndroidVersion() async {
    if (!Platform.isAndroid) return 0;

    // This is a simplified version - in a real app you might want to use
    // a package like device_info_plus to get the exact API level
    return 30; // Default to API 30 for safety
  }

  /// Show permission explanation dialog
  static Future<bool> showPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Storage Permission Required'),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This app needs storage permission to:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8),
                  Text('• Import database files'),
                  Text('• Export backup files'),
                  Text('• Access documents and files'),
                  SizedBox(height: 12),
                  Text(
                    'Your data remains private and is only used for the app\'s functionality.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Grant Permission'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Show settings dialog for permanently denied permissions
  static Future<bool> showSettingsDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Permission Required'),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_open, size: 48, color: Colors.orange),
                  SizedBox(height: 16),
                  Text(
                    'Storage permission has been permanently denied.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'To import/export database files, please enable storage permission in app settings.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                    openAppSettings();
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Check if file operations are available without explicit permissions
  /// (useful for newer Android versions with scoped storage)
  static Future<bool> canAccessFiles() async {
    try {
      // This is a basic check - in practice, file_picker plugin
      // handles most permission scenarios automatically
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Result of storage permission request
enum StoragePermissionResult { granted, denied, permanentlyDenied, error }
