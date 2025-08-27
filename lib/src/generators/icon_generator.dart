import 'dart:io';
import 'package:path/path.dart' as path;
import '../extractors/icon_extractor.dart';

/// Generates Dart code for icons extracted from Figma
class IconGenerator {
  /// Generate a Dart file containing icon asset paths
  static Future<void> generateIconFile(
    List<IconInfo> icons,
    String outputDirectory, {
    String fileName = 'app_icons.dart',
    String className = 'AppIcons',
    String assetPrefix = 'assets/icons/',
  }) async {
    final dir = Directory(outputDirectory);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final buffer = StringBuffer();

    // File header
    buffer.writeln('/// Generated icon assets from Figma');
    buffer.writeln('/// This file is auto-generated. Do not modify manually.');
    buffer.writeln('class $className {');
    buffer.writeln('  $className._();');
    buffer.writeln();

    // Sort icons by name for consistent output
    final sortedIcons = List<IconInfo>.from(icons)
      ..sort((a, b) => a.name.compareTo(b.name));

    // Generate icon constants
    for (final icon in sortedIcons) {
      buffer.writeln('  /// ${icon.originalName}');
      buffer.writeln(
          "  static const String ${icon.name} = '$assetPrefix${icon.fileName}';");
      buffer.writeln();
    }

    // Add helper methods
    buffer.writeln('  /// Get all icon paths as a map');
    buffer.writeln('  static Map<String, String> get allIcons => {');
    for (final icon in sortedIcons) {
      buffer.writeln("    '${icon.name}': ${icon.name},");
    }
    buffer.writeln('  };');
    buffer.writeln();

    buffer.writeln('  /// Get icon path by name (case-insensitive)');
    buffer.writeln('  static String? getIconByName(String name) {');
    buffer.writeln('    final lowerName = name.toLowerCase();');
    buffer.writeln('    for (final entry in allIcons.entries) {');
    buffer.writeln('      if (entry.key.toLowerCase() == lowerName) {');
    buffer.writeln('        return entry.value;');
    buffer.writeln('      }');
    buffer.writeln('    }');
    buffer.writeln('    return null;');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// Get all icon names');
    buffer.writeln(
        '  static List<String> get iconNames => allIcons.keys.toList();');

    buffer.writeln('}');

    // Write to file
    final filePath = path.join(outputDirectory, fileName);
    final file = File(filePath);
    await file.writeAsString(buffer.toString());

    print('✓ Generated icon file: $filePath');
    print('  - ${icons.length} icons generated');
  }

  /// Generate a more advanced icon file with Flutter widgets
  static Future<void> generateIconWidgetFile(
    List<IconInfo> icons,
    String outputDirectory, {
    String fileName = 'app_icon_widgets.dart',
    String className = 'AppIconWidgets',
    String assetPrefix = 'assets/icons/',
  }) async {
    final dir = Directory(outputDirectory);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final buffer = StringBuffer();

    // File header
    buffer.writeln("import 'package:flutter/material.dart';");
    buffer.writeln("import 'package:flutter_svg/flutter_svg.dart';");
    buffer.writeln();
    buffer.writeln('/// Generated icon widgets from Figma');
    buffer.writeln('/// This file is auto-generated. Do not modify manually.');
    buffer.writeln('class $className {');
    buffer.writeln('  $className._();');
    buffer.writeln();

    // Sort icons by name for consistent output
    final sortedIcons = List<IconInfo>.from(icons)
      ..sort((a, b) => a.name.compareTo(b.name));

    // Generate icon widget methods
    for (final icon in sortedIcons) {
      final isVector = icon.format == 'svg';

      buffer.writeln('  /// ${icon.originalName}');
      buffer.writeln('  static Widget ${icon.name}({');
      buffer.writeln('    double? width,');
      buffer.writeln('    double? height,');
      buffer.writeln('    Color? color,');
      buffer.writeln('    BoxFit fit = BoxFit.contain,');
      buffer.writeln('  }) {');

      if (isVector) {
        buffer.writeln('    return SvgPicture.asset(');
        buffer.writeln("      '$assetPrefix${icon.fileName}',");
        buffer.writeln('      width: width,');
        buffer.writeln('      height: height,');
        buffer.writeln(
            '      colorFilter: color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null,');
        buffer.writeln('      fit: fit,');
        buffer.writeln('    );');
      } else {
        buffer.writeln('    return Image.asset(');
        buffer.writeln("      '$assetPrefix${icon.fileName}',");
        buffer.writeln('      width: width,');
        buffer.writeln('      height: height,');
        buffer.writeln('      color: color,');
        buffer.writeln('      fit: fit,');
        buffer.writeln('    );');
      }

      buffer.writeln('  }');
      buffer.writeln();
    }

    // Add helper methods
    buffer.writeln('  /// Get icon widget by name');
    buffer.writeln('  static Widget? getIconByName(');
    buffer.writeln('    String name, {');
    buffer.writeln('    double? width,');
    buffer.writeln('    double? height,');
    buffer.writeln('    Color? color,');
    buffer.writeln('    BoxFit fit = BoxFit.contain,');
    buffer.writeln('  }) {');
    buffer.writeln('    switch (name.toLowerCase()) {');

    for (final icon in sortedIcons) {
      buffer.writeln("      case '${icon.name.toLowerCase()}':");
      buffer.writeln('        return ${icon.name}(');
      buffer.writeln('          width: width,');
      buffer.writeln('          height: height,');
      buffer.writeln('          color: color,');
      buffer.writeln('          fit: fit,');
      buffer.writeln('        );');
    }

    buffer.writeln('      default:');
    buffer.writeln('        return null;');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  /// Get all available icon names');
    buffer.writeln('  static List<String> get availableIcons => [');
    for (final icon in sortedIcons) {
      buffer.writeln("    '${icon.name}',");
    }
    buffer.writeln('  ];');

    buffer.writeln('}');

    // Write to file
    final filePath = path.join(outputDirectory, fileName);
    final file = File(filePath);
    await file.writeAsString(buffer.toString());

    print('✓ Generated icon widget file: $filePath');
    print('  - ${icons.length} icon widgets generated');
  }

  /// Generate pubspec.yaml assets section
  static String generatePubspecAssets(
    List<IconInfo> icons, {
    String assetPrefix = 'assets/icons/',
  }) {
    final buffer = StringBuffer();
    buffer.writeln('  assets:');

    for (final icon in icons) {
      buffer.writeln('    - $assetPrefix${icon.fileName}');
    }

    return buffer.toString();
  }

  /// Generate README documentation for icons
  static Future<void> generateIconDocumentation(
    List<IconInfo> icons,
    String outputDirectory, {
    String fileName = 'ICONS.md',
  }) async {
    final dir = Directory(outputDirectory);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final buffer = StringBuffer();

    // Header
    buffer.writeln('# App Icons');
    buffer.writeln();
    buffer.writeln('This document lists all icons imported from Figma.');
    buffer.writeln();
    buffer.writeln('**Total Icons:** ${icons.length}');
    buffer.writeln();

    // Sort icons by name
    final sortedIcons = List<IconInfo>.from(icons)
      ..sort((a, b) => a.name.compareTo(b.name));

    // Table header
    buffer.writeln('| Icon Name | Original Name | File Name | Format |');
    buffer.writeln('|-----------|---------------|-----------|---------|');

    // Table rows
    for (final icon in sortedIcons) {
      buffer.writeln(
          '| `${icon.name}` | ${icon.originalName} | ${icon.fileName} | ${icon.format.toUpperCase()} |');
    }

    buffer.writeln();
    buffer.writeln('## Usage');
    buffer.writeln();
    buffer.writeln('### Using AppIcons class:');
    buffer.writeln('```dart');
    buffer.writeln("import 'package:your_app/generated/app_icons.dart';");
    buffer.writeln();
    buffer.writeln('// Get icon path');
    if (sortedIcons.isNotEmpty) {
      buffer.writeln('String iconPath = AppIcons.${sortedIcons.first.name};');
    }
    buffer.writeln('```');
    buffer.writeln();
    buffer.writeln('### Using AppIconWidgets class:');
    buffer.writeln('```dart');
    buffer
        .writeln("import 'package:your_app/generated/app_icon_widgets.dart';");
    buffer.writeln();
    buffer.writeln('// Use as widget');
    if (sortedIcons.isNotEmpty) {
      buffer.writeln('Widget icon = AppIconWidgets.${sortedIcons.first.name}(');
      buffer.writeln('  width: 24,');
      buffer.writeln('  height: 24,');
      buffer.writeln('  color: Colors.blue,');
      buffer.writeln(');');
    }
    buffer.writeln('```');

    // Write to file
    final filePath = path.join(outputDirectory, fileName);
    final file = File(filePath);
    await file.writeAsString(buffer.toString());

    print('✓ Generated icon documentation: $filePath');
  }

  /// Generate a categorized icon file
  static Future<void> generateCategorizedIconFile(
    List<IconInfo> icons,
    String outputDirectory, {
    String fileName = 'app_icons.dart',
    String className = 'AppIcons',
    String assetPrefix = 'assets/icons/',
  }) async {
    final dir = Directory(outputDirectory);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // Categorize icons
    final categories = _categorizeIcons(icons);

    final buffer = StringBuffer();

    // File header
    buffer.writeln('/// Generated icon assets from Figma');
    buffer.writeln('/// This file is auto-generated. Do not modify manually.');
    buffer.writeln('class $className {');
    buffer.writeln('  $className._();');
    buffer.writeln();

    // Generate icons by category
    for (final category in categories.entries) {
      final categoryName = category.key;
      final categoryIcons = category.value;

      buffer.writeln('  // $categoryName Icons');
      for (final icon in categoryIcons) {
        buffer.writeln('  /// ${icon.originalName}');
        buffer.writeln(
            "  static const String ${icon.name} = '$assetPrefix${icon.fileName}';");
        buffer.writeln();
      }
    }

    buffer.writeln('}');

    // Write to file
    final filePath = path.join(outputDirectory, fileName);
    final file = File(filePath);
    await file.writeAsString(buffer.toString());

    print('✓ Generated categorized icon file: $filePath');
    print('  - ${icons.length} icons in ${categories.length} categories');
  }

  /// Categorize icons based on their names
  static Map<String, List<IconInfo>> _categorizeIcons(List<IconInfo> icons) {
    final categories = <String, List<IconInfo>>{};

    for (final icon in icons) {
      String category = 'General';
      final name = icon.originalName.toLowerCase();

      // Determine category based on name patterns
      if (name.contains('navigation') ||
          name.contains('nav') ||
          name.contains('menu') ||
          name.contains('arrow')) {
        category = 'Navigation';
      } else if (name.contains('social') || name.contains('share')) {
        category = 'Social';
      } else if (name.contains('action') || name.contains('button')) {
        category = 'Actions';
      } else if (name.contains('communication') ||
          name.contains('message') ||
          name.contains('mail') ||
          name.contains('phone')) {
        category = 'Communication';
      } else if (name.contains('media') ||
          name.contains('play') ||
          name.contains('video') ||
          name.contains('music')) {
        category = 'Media';
      } else if (name.contains('file') ||
          name.contains('document') ||
          name.contains('folder')) {
        category = 'Files';
      } else if (name.contains('user') ||
          name.contains('person') ||
          name.contains('profile') ||
          name.contains('account')) {
        category = 'User';
      } else if (name.contains('settings') ||
          name.contains('config') ||
          name.contains('gear') ||
          name.contains('tool')) {
        category = 'Settings';
      }

      categories.putIfAbsent(category, () => []).add(icon);
    }

    // Sort categories and icons within each category
    final sortedCategories = <String, List<IconInfo>>{};
    final sortedCategoryKeys = categories.keys.toList()..sort();

    for (final key in sortedCategoryKeys) {
      final iconList = categories[key]!;
      iconList.sort((a, b) => a.name.compareTo(b.name));
      sortedCategories[key] = iconList;
    }

    return sortedCategories;
  }
}
