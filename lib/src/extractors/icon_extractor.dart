import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../figma_api_client.dart';
import '../models/figma_response.dart';
import '../utils/string_utils.dart';
import '../utils/change_detector.dart';

/// Extracts icons from Figma data
class IconExtractor {
  final FigmaApiClient apiClient;

  IconExtractor({required this.apiClient});

  /// Extract icons from Figma file
  Future<List<IconInfo>> extractIcons(
    FigmaFile figmaFile,
    String fileKey, {
    String iconsFrameName = 'Icons',
    String format = 'svg',
  }) async {
    final icons = <IconInfo>[];

    // Find the icons frame
    final iconFrames =
        _findNodesByNameInDocument(figmaFile.document, iconsFrameName);

    if (iconFrames.isEmpty) {
      print('Warning: No frame named "$iconsFrameName" found. '
          'Searching for components that might be icons...');

      // Fallback: look for all components
      final components =
          _findNodesByTypeInDocument(figmaFile.document, 'COMPONENT');
      return _processIconNodes(components, figmaFile, fileKey, format: format);
    }

    // Process each icons frame
    for (final frame in iconFrames) {
      final frameIcons =
          await _processIconFrame(frame, figmaFile, fileKey, format: format);
      icons.addAll(frameIcons);
    }

    return icons;
  }

  /// Process an icons frame to extract individual icons
  Future<List<IconInfo>> _processIconFrame(
    FigmaNode frame,
    FigmaFile figmaFile,
    String fileKey, {
    String format = 'svg',
  }) async {
    // Find all components or instances within the frame
    final iconNodes = <FigmaNode>[];
    iconNodes.addAll(frame.findNodesByType('COMPONENT'));
    iconNodes.addAll(frame.findNodesByType('INSTANCE'));

    return _processIconNodes(iconNodes, figmaFile, fileKey, format: format);
  }

  /// Process a list of icon nodes
  Future<List<IconInfo>> _processIconNodes(
    List<FigmaNode> iconNodes,
    FigmaFile figmaFile,
    String fileKey, {
    String format = 'svg',
  }) async {
    if (iconNodes.isEmpty) return [];

    final icons = <IconInfo>[];
    final seenFileNames = <String>{};
    final nodeIds = iconNodes.map((node) => node.id).toList();

    try {
      // Get image URLs from Figma API
      final imageResponse = await apiClient.getImages(
        fileKey: fileKey,
        nodeIds: nodeIds,
        format: format,
      );

      // Process each icon
      for (final node in iconNodes) {
        final imageUrl = imageResponse.images[node.id];
        if (imageUrl != null && imageUrl.isNotEmpty) {
          final iconName = StringUtils.toDartVariableName(node.name);
          final fileName = '${StringUtils.toSnakeCase(node.name)}.$format';

          // Skip duplicates based on file name
          if (seenFileNames.contains(fileName)) {
            print('⚠️  Skipping duplicate icon: $fileName');
            continue;
          }
          seenFileNames.add(fileName);

          icons.add(IconInfo(
            name: iconName,
            originalName: node.name,
            fileName: fileName,
            nodeId: node.id,
            imageUrl: imageUrl,
            format: format,
          ));
        }
      }
    } catch (e) {
      throw IconExtractionException('Failed to get icon URLs: $e');
    }

    return icons;
  }

  /// Download icons to a specified directory with smart change detection
  Future<void> downloadIcons(
    List<IconInfo> icons,
    String outputDirectory, {
    ChangeDetector? changeDetector,
  }) async {
    final dir = Directory(outputDirectory);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    print('Downloading ${icons.length} icons to $outputDirectory...');

    int successCount = 0;
    int failCount = 0;
    int skippedCount = 0;
    int changedCount = 0;

    for (int i = 0; i < icons.length; i++) {
      final icon = icons[i];
      final filePath = path.join(outputDirectory, icon.fileName);
      final file = File(filePath);

      // Smart change detection
      bool needsDownload = true;

      if (changeDetector != null) {
        needsDownload = await changeDetector.hasIconChanged(
            icon.nodeId, icon.fileName, icon.imageUrl, filePath);

        if (!needsDownload) {
          print('⏭️  No changes detected: ${icon.fileName}');
          skippedCount++;
          successCount++;
          continue;
        } else if (await file.exists()) {
          print('🔄 Content changed: ${icon.fileName}');
          changedCount++;
        } else {
          print('🆕 New icon: ${icon.fileName}');
        }
      } else {
        // Fallback to simple file existence check
        if (await file.exists()) {
          print('⏭️  Skipping existing file: ${icon.fileName}');
          skippedCount++;
          successCount++;
          continue;
        }
      }

      try {
        print('Downloading ${icon.fileName} (${i + 1}/${icons.length})...');

        final imageData = await apiClient.downloadImage(icon.imageUrl).timeout(
              const Duration(seconds: 30),
              onTimeout: () => throw TimeoutException(
                  'Download timeout', const Duration(seconds: 30)),
            );

        await file.writeAsBytes(imageData);
        print('✓ Downloaded ${icon.fileName}');
        successCount++;

        // Update change detector
        if (changeDetector != null) {
          await changeDetector.updateIcon(
              icon.nodeId, icon.fileName, icon.imageUrl, filePath);
        }
      } catch (e) {
        print('✗ Failed to download ${icon.fileName}: $e');
        failCount++;

        // If too many failures, stop the process
        if (failCount > 5) {
          print('❌ Too many download failures. Stopping download process.');
          break;
        }
      }

      // Small delay to avoid overwhelming the server
      if (i < icons.length - 1) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    print(
        'Icon download completed! ✓ $successCount successful, ✗ $failCount failed');
    if (changeDetector != null && (skippedCount > 0 || changedCount > 0)) {
      print(
          '📊 Smart detection: ${skippedCount} unchanged, ${changedCount} updated');
    }
  }

  /// Extract icons from a specific frame by name pattern
  Future<List<IconInfo>> extractIconsFromFramePattern(
    FigmaFile figmaFile,
    String fileKey,
    String frameNamePattern, {
    String format = 'svg',
  }) async {
    final icons = <IconInfo>[];
    final frames =
        _findNodesByNameInDocument(figmaFile.document, frameNamePattern);

    for (final frame in frames) {
      final frameIcons =
          await _processIconFrame(frame, figmaFile, fileKey, format: format);
      icons.addAll(frameIcons);
    }

    return icons;
  }

  /// Find nodes by name in document
  static List<FigmaNode> _findNodesByNameInDocument(
      FigmaDocument document, String namePattern) {
    final result = <FigmaNode>[];
    for (final child in document.children) {
      result.addAll(child.findNodesByName(namePattern));
    }
    return result;
  }

  /// Find nodes by type in document
  static List<FigmaNode> _findNodesByTypeInDocument(
      FigmaDocument document, String nodeType) {
    final result = <FigmaNode>[];
    for (final child in document.children) {
      result.addAll(child.findNodesByType(nodeType));
    }
    return result;
  }
}

/// Information about an icon extracted from Figma
class IconInfo {
  final String name;
  final String originalName;
  final String fileName;
  final String nodeId;
  final String imageUrl;
  final String format;

  IconInfo({
    required this.name,
    required this.originalName,
    required this.fileName,
    required this.nodeId,
    required this.imageUrl,
    required this.format,
  });

  /// Get the asset path for Flutter
  String get assetPath => 'assets/icons/$fileName';

  @override
  String toString() {
    return 'IconInfo(name: $name, fileName: $fileName)';
  }
}

/// Exception thrown during icon extraction
class IconExtractionException implements Exception {
  final String message;

  IconExtractionException(this.message);

  @override
  String toString() => 'IconExtractionException: $message';
}
