import 'dart:io';
import 'package:path/path.dart' as path;
import '../extractors/color_extractor.dart';

/// Generates Dart code for colors extracted from Figma
class ColorGenerator {
  /// Generate a Dart file containing color constants
  static Future<void> generateColorFile(
    Map<String, ColorInfo> colors,
    String outputDirectory, {
    String fileName = 'app_colors.dart',
    String className = 'AppColors',
  }) async {
    final dir = Directory(outputDirectory);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final buffer = StringBuffer();

    // File header
    buffer.writeln("import 'package:flutter/material.dart';");
    buffer.writeln();
    buffer.writeln('/// Generated colors from Figma');
    buffer.writeln('/// This file is auto-generated. Do not modify manually.');
    buffer.writeln('class $className {');
    buffer.writeln('  $className._();');
    buffer.writeln();

    // Sort colors by name for consistent output
    final sortedColors = colors.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Generate color constants
    for (final entry in sortedColors) {
      final colorInfo = entry.value;

      // Add documentation comment - clean description for safety
      final cleanDescription = colorInfo.description
          .replaceAll('\n', ' ')
          .replaceAll('\r', ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (cleanDescription.isNotEmpty) {
        buffer.writeln('  /// $cleanDescription');
      }
      buffer.writeln('  /// Original name: ${colorInfo.originalName}');
      buffer.writeln(
          '  static const Color ${colorInfo.name} = Color(${colorInfo.hexValue});');
      buffer.writeln();
    }

    // Add helper methods
    buffer.writeln('  /// Get all colors as a map');
    buffer.writeln('  static Map<String, Color> get allColors => {');
    for (final entry in sortedColors) {
      buffer.writeln("    '${entry.value.name}': ${entry.value.name},");
    }
    buffer.writeln('  };');
    buffer.writeln();

    buffer.writeln('  /// Get color by name (case-insensitive)');
    buffer.writeln('  static Color? getColorByName(String name) {');
    buffer.writeln('    final lowerName = name.toLowerCase();');
    buffer.writeln('    for (final entry in allColors.entries) {');
    buffer.writeln('      if (entry.key.toLowerCase() == lowerName) {');
    buffer.writeln('        return entry.value;');
    buffer.writeln('      }');
    buffer.writeln('    }');
    buffer.writeln('    return null;');
    buffer.writeln('  }');

    buffer.writeln('}');

    // Write to file
    final filePath = path.join(outputDirectory, fileName);
    final file = File(filePath);
    await file.writeAsString(buffer.toString());

    print('✓ Generated color file: $filePath');
    print('  - ${colors.length} colors generated');
  }

  /// Generate a more detailed color file with categories
  static Future<void> generateCategorizedColorFile(
    Map<String, ColorInfo> colors,
    String outputDirectory, {
    String fileName = 'app_colors.dart',
    String className = 'AppColors',
  }) async {
    final dir = Directory(outputDirectory);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // Categorize colors based on their original names
    final categories = _categorizeColors(colors);

    final buffer = StringBuffer();

    // File header
    buffer.writeln("import 'package:flutter/material.dart';");
    buffer.writeln();
    buffer.writeln('/// Generated colors from Figma');
    buffer.writeln('/// This file is auto-generated. Do not modify manually.');
    buffer.writeln('class $className {');
    buffer.writeln('  $className._();');
    buffer.writeln();

    // Generate colors by category
    for (final category in categories.entries) {
      final categoryName = category.key;
      final categoryColors = category.value;

      buffer.writeln('  // $categoryName Colors');
      for (final colorInfo in categoryColors) {
        buffer.writeln('  /// ${colorInfo.description}');
        buffer.writeln('  /// Original name: ${colorInfo.originalName}');
        buffer.writeln(
            '  static const Color ${colorInfo.name} = Color(${colorInfo.hexValue});');
        buffer.writeln();
      }
    }

    // Add helper methods
    buffer.writeln('  /// Get all colors as a map');
    buffer.writeln('  static Map<String, Color> get allColors => {');
    for (final colorInfo in colors.values) {
      buffer.writeln("    '${colorInfo.name}': ${colorInfo.name},");
    }
    buffer.writeln('  };');

    buffer.writeln('}');

    // Write to file
    final filePath = path.join(outputDirectory, fileName);
    final file = File(filePath);
    await file.writeAsString(buffer.toString());

    print('✓ Generated categorized color file: $filePath');
    print('  - ${colors.length} colors in ${categories.length} categories');
  }

  /// Categorize colors based on their names
  static Map<String, List<ColorInfo>> _categorizeColors(
      Map<String, ColorInfo> colors) {
    final categories = <String, List<ColorInfo>>{};

    for (final colorInfo in colors.values) {
      String category = 'General';
      final originalName = colorInfo.originalName.toLowerCase();

      // Determine category based on name patterns
      if (originalName.contains('primary')) {
        category = 'Primary';
      } else if (originalName.contains('secondary')) {
        category = 'Secondary';
      } else if (originalName.contains('accent')) {
        category = 'Accent';
      } else if (originalName.contains('background') ||
          originalName.contains('bg')) {
        category = 'Background';
      } else if (originalName.contains('text') ||
          originalName.contains('font')) {
        category = 'Text';
      } else if (originalName.contains('border') ||
          originalName.contains('stroke')) {
        category = 'Border';
      } else if (originalName.contains('error') ||
          originalName.contains('danger')) {
        category = 'Error';
      } else if (originalName.contains('success') ||
          originalName.contains('green')) {
        category = 'Success';
      } else if (originalName.contains('warning') ||
          originalName.contains('yellow')) {
        category = 'Warning';
      } else if (originalName.contains('info') ||
          originalName.contains('blue')) {
        category = 'Info';
      }

      categories.putIfAbsent(category, () => []).add(colorInfo);
    }

    // Sort categories and colors within each category
    final sortedCategories = <String, List<ColorInfo>>{};
    final sortedCategoryKeys = categories.keys.toList()..sort();

    for (final key in sortedCategoryKeys) {
      final colorList = categories[key]!;
      colorList.sort((a, b) => a.name.compareTo(b.name));
      sortedCategories[key] = colorList;
    }

    return sortedCategories;
  }

  /// Generate a theme extension file for Flutter
  static Future<void> generateThemeExtension(
    Map<String, ColorInfo> colors,
    String outputDirectory, {
    String fileName = 'app_color_theme.dart',
    String extensionName = 'AppColorTheme',
  }) async {
    final dir = Directory(outputDirectory);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final buffer = StringBuffer();

    // File header
    buffer.writeln("import 'package:flutter/material.dart';");
    buffer.writeln();
    buffer.writeln('/// Theme extension for app colors');
    buffer.writeln('/// This file is auto-generated. Do not modify manually.');
    buffer.writeln('@immutable');
    buffer.writeln(
        'class $extensionName extends ThemeExtension<$extensionName> {');
    buffer.writeln();

    // Constructor parameters
    buffer.writeln('  const $extensionName({');
    for (final colorInfo in colors.values) {
      buffer.writeln('    required this.${colorInfo.name},');
    }
    buffer.writeln('  });');
    buffer.writeln();

    // Color properties
    for (final colorInfo in colors.values) {
      buffer.writeln('  /// ${colorInfo.description}');
      buffer.writeln('  final Color ${colorInfo.name};');
      buffer.writeln();
    }

    // copyWith method
    buffer.writeln('  @override');
    buffer.writeln('  $extensionName copyWith({');
    for (final colorInfo in colors.values) {
      buffer.writeln('    Color? ${colorInfo.name},');
    }
    buffer.writeln('  }) {');
    buffer.writeln('    return $extensionName(');
    for (final colorInfo in colors.values) {
      buffer.writeln(
          '      ${colorInfo.name}: ${colorInfo.name} ?? this.${colorInfo.name},');
    }
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln();

    // lerp method
    buffer.writeln('  @override');
    buffer.writeln('  $extensionName lerp($extensionName? other, double t) {');
    buffer.writeln('    if (other is! $extensionName) return this;');
    buffer.writeln('    return $extensionName(');
    for (final colorInfo in colors.values) {
      buffer.writeln(
          '      ${colorInfo.name}: Color.lerp(${colorInfo.name}, other.${colorInfo.name}, t)!,');
    }
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln();

    // Default light theme
    buffer.writeln('  static const light = $extensionName(');
    for (final colorInfo in colors.values) {
      buffer.writeln('    ${colorInfo.name}: Color(${colorInfo.hexValue}),');
    }
    buffer.writeln('  );');

    buffer.writeln('}');

    // Extension on ThemeData
    buffer.writeln();
    buffer.writeln('extension ${extensionName}Extension on ThemeData {');
    buffer.writeln(
        '  $extensionName get appColors => extension<$extensionName>()!;');
    buffer.writeln('}');

    // Write to file
    final filePath = path.join(outputDirectory, fileName);
    final file = File(filePath);
    await file.writeAsString(buffer.toString());

    print('✓ Generated theme extension file: $filePath');
  }
}
