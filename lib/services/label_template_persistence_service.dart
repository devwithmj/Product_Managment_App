import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dynamic_label_template.dart';

/// Service for persisting custom label templates
class LabelTemplatePersistenceService {
  static const String _templatesKey = 'custom_label_templates';

  /// Save a custom template
  static Future<void> saveTemplate(DynamicLabelTemplate template) async {
    final prefs = await SharedPreferences.getInstance();

    // Get existing templates
    final existingTemplates = await getAllTemplates();

    // Update or add template
    final updatedTemplates = <String, DynamicLabelTemplate>{};

    // Add existing templates (excluding the one we're updating)
    for (final existing in existingTemplates) {
      if (existing.name != template.name) {
        updatedTemplates[existing.name] = existing;
      }
    }

    // Add the new/updated template
    updatedTemplates[template.name] = template;

    // Convert to JSON and save
    final templatesJson = updatedTemplates.map(
      (name, template) => MapEntry(name, template.toMap()),
    );

    await prefs.setString(_templatesKey, jsonEncode(templatesJson));
  }

  /// Get all saved templates
  static Future<List<DynamicLabelTemplate>> getAllTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final templatesJson = prefs.getString(_templatesKey);

    if (templatesJson == null || templatesJson.isEmpty) {
      return [];
    }

    try {
      final Map<String, dynamic> templatesMap = jsonDecode(templatesJson);
      return templatesMap.values
          .map((templateJson) => DynamicLabelTemplate.fromMap(templateJson))
          .toList();
    } catch (e) {
      print('Error loading templates: $e');
      return [];
    }
  }

  /// Get all templates including built-in ones
  static Future<List<DynamicLabelTemplate>> getAllTemplatesWithBuiltIn() async {
    final customTemplates = await getAllTemplates();
    final builtInTemplates = DynamicLabelTemplates.allTemplates;

    // Combine built-in and custom templates
    final allTemplates = <DynamicLabelTemplate>[];
    allTemplates.addAll(builtInTemplates);
    allTemplates.addAll(customTemplates);

    // Remove duplicates (custom templates override built-in ones with same name)
    final uniqueTemplates = <String, DynamicLabelTemplate>{};
    for (final template in allTemplates) {
      uniqueTemplates[template.name] = template;
    }

    return uniqueTemplates.values.toList();
  }

  /// Get a specific template by name
  static Future<DynamicLabelTemplate?> getTemplate(String name) async {
    final allTemplates = await getAllTemplatesWithBuiltIn();
    try {
      return allTemplates.firstWhere((template) => template.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Delete a custom template
  static Future<void> deleteTemplate(String name) async {
    final prefs = await SharedPreferences.getInstance();

    // Get existing templates
    final existingTemplates = await getAllTemplates();

    // Remove the specified template
    final updatedTemplates =
        existingTemplates.where((template) => template.name != name).toList();

    // Convert to JSON and save
    final templatesJson = <String, Map<String, dynamic>>{};
    for (final template in updatedTemplates) {
      templatesJson[template.name] = template.toMap();
    }

    await prefs.setString(_templatesKey, jsonEncode(templatesJson));
  }

  /// Check if a template is custom (user-created)
  static Future<bool> isCustomTemplate(String name) async {
    final customTemplates = await getAllTemplates();
    return customTemplates.any((template) => template.name == name);
  }

  /// Clear all custom templates
  static Future<void> clearAllCustomTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_templatesKey);
  }

  /// Export templates as JSON string
  static Future<String> exportTemplates() async {
    final customTemplates = await getAllTemplates();
    final templatesMap = <String, Map<String, dynamic>>{};

    for (final template in customTemplates) {
      templatesMap[template.name] = template.toMap();
    }

    return jsonEncode({
      'version': '1.0',
      'export_date': DateTime.now().toIso8601String(),
      'templates': templatesMap,
    });
  }

  /// Import templates from JSON string
  static Future<int> importTemplates(String jsonString) async {
    try {
      final Map<String, dynamic> importData = jsonDecode(jsonString);
      final Map<String, dynamic> templatesMap = importData['templates'] ?? {};

      int importedCount = 0;

      for (final templateJson in templatesMap.values) {
        final template = DynamicLabelTemplate.fromMap(templateJson);
        await saveTemplate(template);
        importedCount++;
      }

      return importedCount;
    } catch (e) {
      print('Error importing templates: $e');
      throw Exception('Failed to import templates: $e');
    }
  }

  /// Get template usage statistics
  static Future<Map<String, int>> getTemplateUsageStats() async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString('template_usage_stats');

    if (statsJson == null) {
      return {};
    }

    try {
      final Map<String, dynamic> stats = jsonDecode(statsJson);
      return stats.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      return {};
    }
  }

  /// Record template usage
  static Future<void> recordTemplateUsage(String templateName) async {
    final prefs = await SharedPreferences.getInstance();
    final stats = await getTemplateUsageStats();

    stats[templateName] = (stats[templateName] ?? 0) + 1;

    await prefs.setString('template_usage_stats', jsonEncode(stats));
  }
}
