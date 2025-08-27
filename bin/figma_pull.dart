#!/usr/bin/env dart

import 'dart:io';
import 'package:args/args.dart';
import 'package:figma_puller/figma_puller.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'file-key',
      abbr: 'k',
      help: 'Figma file key to pull from.',
      mandatory: true,
    )
    ..addOption(
      'token',
      abbr: 't',
      help: 'Your Figma API access token.',
      mandatory: true,
    )
    ..addOption(
      'output-dir',
      abbr: 'o',
      help: 'Output directory for generated files.',
      defaultsTo: 'lib/generated',
    )
    ..addOption(
      'assets-dir',
      abbr: 'a',
      help: 'Assets directory for downloaded icons.',
      defaultsTo: 'assets/icons',
    )
    ..addOption(
      'icons-frame',
      abbr: 'f',
      help: 'Name of the frame containing icons in Figma.',
      defaultsTo: 'Icons',
    )
    ..addOption(
      'icon-format',
      help: 'Format for downloaded icons (svg, png).',
      defaultsTo: 'svg',
      allowed: ['svg', 'png'],
    )
    ..addFlag(
      'colors-only',
      help: 'Only extract colors, skip icons.',
      negatable: false,
    )
    ..addFlag(
      'icons-only',
      help: 'Only extract icons, skip colors.',
      negatable: false,
    )
    ..addFlag(
      'categorized',
      help: 'Generate categorized output files.',
      negatable: false,
    )
    ..addFlag(
      'theme-extension',
      help: 'Generate Flutter theme extension for colors.',
      negatable: false,
    )
    ..addFlag(
      'icon-widgets',
      help: 'Generate Flutter widget helpers for icons.',
      negatable: false,
    )
    ..addFlag(
      'clean',
      help: 'Clean output directories before generating new files.',
      negatable: false,
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      help: 'Enable verbose logging.',
      negatable: false,
    )
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Show this help message.',
      negatable: false,
    );

  try {
    final argResults = parser.parse(arguments);

    if (argResults['help'] as bool) {
      _printUsage(parser);
      return;
    }

    final fileKey = argResults['file-key'] as String;
    final token = argResults['token'] as String;
    final outputDir = argResults['output-dir'] as String;
    final assetsDir = argResults['assets-dir'] as String;
    final iconsFrame = argResults['icons-frame'] as String;
    final iconFormat = argResults['icon-format'] as String;
    final colorsOnly = argResults['colors-only'] as bool;
    final iconsOnly = argResults['icons-only'] as bool;
    final categorized = argResults['categorized'] as bool;
    final themeExtension = argResults['theme-extension'] as bool;
    final iconWidgets = argResults['icon-widgets'] as bool;
    final clean = argResults['clean'] as bool;
    final verbose = argResults['verbose'] as bool;

    if (colorsOnly && iconsOnly) {
      _printError('Cannot specify both --colors-only and --icons-only');
      exit(1);
    }

    await _runFigmaPull(
      fileKey: fileKey,
      token: token,
      outputDir: outputDir,
      assetsDir: assetsDir,
      iconsFrame: iconsFrame,
      iconFormat: iconFormat,
      colorsOnly: colorsOnly,
      iconsOnly: iconsOnly,
      categorized: categorized,
      themeExtension: themeExtension,
      iconWidgets: iconWidgets,
      clean: clean,
      verbose: verbose,
    );
  } catch (e) {
    if (e is FormatException) {
      _printError('Invalid arguments: ${e.message}');
      print('');
      _printUsage(parser);
      exit(1);
    } else {
      _printError('Unexpected error: $e');
      exit(1);
    }
  }
}

Future<void> _runFigmaPull({
  required String fileKey,
  required String token,
  required String outputDir,
  required String assetsDir,
  required String iconsFrame,
  required String iconFormat,
  required bool colorsOnly,
  required bool iconsOnly,
  required bool categorized,
  required bool themeExtension,
  required bool iconWidgets,
  required bool clean,
  required bool verbose,
}) async {
  try {
    _printHeader();

    if (verbose) {
      print('Configuration:');
      print('  File Key: $fileKey');
      print('  Output Directory: $outputDir');
      print('  Assets Directory: $assetsDir');
      print('  Icons Frame: $iconsFrame');
      print('  Icon Format: $iconFormat');
      print('  Colors Only: $colorsOnly');
      print('  Icons Only: $iconsOnly');
      print('  Categorized: $categorized');
      print('  Theme Extension: $themeExtension');
      print('  Icon Widgets: $iconWidgets');
      print('  Clean Mode: $clean');
      print('');
    }

    // Clean directories if requested
    if (clean) {
      print('🧹 Cleaning directories...');
      await _cleanDirectories(outputDir, assetsDir, colorsOnly, iconsOnly);
    }

    // Initialize change detector
    final changeDetector = ChangeDetector(outputDirectory: outputDir);
    await changeDetector.initialize();

    // Initialize API client
    final apiClient = FigmaApiClient(apiToken: token);

    try {
      // Fetch Figma file
      print('📡 Fetching Figma file...');
      final figmaFile = await apiClient.getFile(fileKey);
      print('✅ Successfully fetched file: ${figmaFile.name}');

      // Extract and generate colors
      if (!iconsOnly) {
        print('\n🎨 Processing colors...');
        final colors = ColorExtractor.extractColors(figmaFile);

        if (colors.isNotEmpty) {
          if (categorized) {
            await ColorGenerator.generateCategorizedColorFile(
              colors,
              outputDir,
              fileName: 'app_colors.dart',
            );
          } else {
            await ColorGenerator.generateColorFile(
              colors,
              outputDir,
              fileName: 'app_colors.dart',
            );
          }

          if (themeExtension) {
            await ColorGenerator.generateThemeExtension(
              colors,
              outputDir,
              fileName: 'app_color_theme.dart',
            );
          }
        } else {
          print('⚠️  No colors found in the Figma file');
        }
      }

      // Extract and generate icons
      if (!colorsOnly) {
        print('\n🔍 Processing icons...');
        final iconExtractor = IconExtractor(apiClient: apiClient);
        final icons = await iconExtractor.extractIcons(
          figmaFile,
          fileKey,
          iconsFrameName: iconsFrame,
          format: iconFormat,
        );

        if (icons.isNotEmpty) {
          // Download icons with smart change detection
          await iconExtractor.downloadIcons(icons, assetsDir,
              changeDetector: changeDetector);

          // Generate icon files
          if (categorized) {
            await IconGenerator.generateCategorizedIconFile(
              icons,
              outputDir,
              fileName: 'app_icons.dart',
            );
          } else {
            await IconGenerator.generateIconFile(
              icons,
              outputDir,
              fileName: 'app_icons.dart',
            );
          }

          if (iconWidgets) {
            await IconGenerator.generateIconWidgetFile(
              icons,
              outputDir,
              fileName: 'app_icon_widgets.dart',
            );
          }

          // Generate documentation
          await IconGenerator.generateIconDocumentation(
            icons,
            outputDir,
            fileName: 'ICONS.md',
          );

          // Print pubspec.yaml assets section
          print('\n📋 Add these assets to your pubspec.yaml:');
          print(IconGenerator.generatePubspecAssets(icons));
        } else {
          print('⚠️  No icons found in frame "$iconsFrame"');
        }
      }

      // Save change detector manifest
      await changeDetector.save(figmaFileKey: fileKey);

      print('\n🎉 Figma pull completed successfully!');
      print('📁 Generated files are in: $outputDir');
      if (!colorsOnly) {
        print('🖼️  Downloaded assets are in: $assetsDir');
      }
    } finally {
      apiClient.dispose();
    }
  } catch (e) {
    _printError('Failed to pull from Figma: $e');
    exit(1);
  }
}

void _printHeader() {
  print('╔══════════════════════════════════════╗');
  print('║          Figma Importer              ║');
  print('║   Pull design tokens from Figma      ║');
  print('╚══════════════════════════════════════╝');
  print('');
}

void _printUsage(ArgParser parser) {
  print('Usage: figma_pull [options]');
  print('');
  print('Pull design tokens and assets from a Figma file.');
  print('');
  print('Options:');
  print(parser.usage);
  print('');
  print('Examples:');
  print('  # Basic usage');
  print('  figma_pull --file-key ABC123XYZ --token your_figma_token');
  print('');
  print('  # Custom output directories');
  print(
      '  figma_pull -k ABC123XYZ -t your_token -o lib/design -a assets/images');
  print('');
  print('  # Only extract colors');
  print('  figma_pull -k ABC123XYZ -t your_token --colors-only');
  print('');
  print('  # Generate categorized files with theme extension');
  print(
      '  figma_pull -k ABC123XYZ -t your_token --categorized --theme-extension');
  print('');
  print('  # Extract icons with widget helpers');
  print(
      '  figma_pull -k ABC123XYZ -t your_token --icon-widgets --icon-format svg');
  print('');
  print('  # Clean directories before generating (fresh sync)');
  print('  figma_pull -k ABC123XYZ -t your_token --clean');
}

void _printError(String message) {
  print('❌ Error: $message');
}

/// Clean directories before generating new files
Future<void> _cleanDirectories(
  String outputDir,
  String assetsDir,
  bool colorsOnly,
  bool iconsOnly,
) async {
  try {
    // Clean output directory (Dart files)
    final outputDirectory = Directory(outputDir);
    if (await outputDirectory.exists()) {
      print('  🗑️  Cleaning output directory: $outputDir');

      // Only delete generated files, not the entire directory
      final files = outputDirectory.listSync();
      for (final file in files) {
        if (file is File) {
          final fileName = file.path.split('/').last;
          // Only delete known generated files
          if (fileName.startsWith('app_colors') ||
              fileName.startsWith('app_icons') ||
              fileName.startsWith('app_color_theme') ||
              fileName.startsWith('app_icon_widgets') ||
              fileName == 'ICONS.md') {
            await file.delete();
            print('    ✓ Deleted: $fileName');
          }
        }
      }
    }

    // Clean assets directory (only if processing icons)
    if (!colorsOnly) {
      final assetsDirectory = Directory(assetsDir);
      if (await assetsDirectory.exists()) {
        print('  🗑️  Cleaning assets directory: $assetsDir');

        // Delete all files in assets directory
        final files = assetsDirectory.listSync();
        int deletedCount = 0;
        for (final file in files) {
          if (file is File) {
            await file.delete();
            deletedCount++;
          }
        }
        print('    ✓ Deleted $deletedCount asset files');
      }
    }

    print('✅ Cleaning completed');
  } catch (e) {
    print('⚠️  Warning: Failed to clean directories: $e');
    print('   Continuing with generation...');
  }
}
