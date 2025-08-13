import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('App Theme'),
            backgroundColor: themeService.primaryColor,
            foregroundColor: Colors.white,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Dark Mode Toggle
              Card(
                child: SwitchListTile(
                  title: const Text(
                    'Dark Mode',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    themeService.isDarkMode
                        ? 'Using dark theme'
                        : 'Using light theme',
                  ),
                  value: themeService.isDarkMode,
                  onChanged: (bool value) {
                    themeService.setDarkMode(value);
                  },
                  secondary: Icon(
                    themeService.isDarkMode
                        ? Icons.dark_mode
                        : Icons.light_mode,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Color Selection Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.palette),
                          const SizedBox(width: 8),
                          Text(
                            'Primary Color',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Current: ${themeService.currentColorName}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Color Grid
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children:
                            ThemeService.availableColors.entries.map((entry) {
                              final colorName = entry.key;
                              final color = entry.value;
                              final isSelected =
                                  themeService.primaryColor == color;

                              return GestureDetector(
                                onTap: () {
                                  themeService.setPrimaryColor(color);

                                  // Show feedback
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Theme changed to $colorName',
                                      ),
                                      duration: const Duration(seconds: 1),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? Colors.black
                                              : Colors.grey.withOpacity(0.3),
                                      width: isSelected ? 3 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child:
                                      isSelected
                                          ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 24,
                                          )
                                          : null,
                                ),
                              );
                            }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // Color names for reference
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children:
                            ThemeService.availableColors.keys.map((colorName) {
                              final isSelected =
                                  themeService.currentColorName == colorName;

                              return Chip(
                                label: Text(
                                  colorName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected ? Colors.white : null,
                                  ),
                                ),
                                backgroundColor:
                                    isSelected
                                        ? themeService.primaryColor
                                        : null,
                                onDeleted: isSelected ? () {} : null,
                                deleteIcon:
                                    isSelected
                                        ? const Icon(Icons.check, size: 16)
                                        : null,
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Preview Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preview',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),

                      const SizedBox(height: 16),

                      // Sample UI elements with current theme
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.label),
                        label: const Text('Print Labels'),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Checkbox(value: true, onChanged: null),
                          const Text('Sample checkbox'),
                        ],
                      ),

                      const SizedBox(height: 8),

                      LinearProgressIndicator(
                        value: 0.7,
                        backgroundColor: Colors.grey.withOpacity(0.2),
                      ),

                      const SizedBox(height: 8),

                      const Text('This shows how your theme looks in the app'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Reset Button
              Card(
                child: ListTile(
                  leading: const Icon(Icons.refresh),
                  title: const Text('Reset to Default'),
                  subtitle: const Text('Blue theme with light mode'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Reset Theme'),
                          content: const Text(
                            'This will reset your theme to the default blue color and light mode. Are you sure?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                themeService.resetToDefault();
                                Navigator.pop(context);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Theme reset to default'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: const Text('Reset'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Information
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Theme Information',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Text(
                        '• Theme changes apply immediately to all screens\n'
                        '• Your preferences are saved automatically\n'
                        '• The splash screen will use your selected color\n'
                        '• Both Persian and English text adapt to dark mode',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
