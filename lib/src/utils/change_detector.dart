import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';

/// Detects changes in Figma assets and generated files
class ChangeDetector {
  final String manifestPath;
  late Map<String, dynamic> _manifest;

  ChangeDetector({required String outputDirectory})
      : manifestPath = path.join(outputDirectory, '.figma_manifest.json');

  /// Load existing manifest or create new one
  Future<void> initialize() async {
    final manifestFile = File(manifestPath);

    if (await manifestFile.exists()) {
      try {
        final content = await manifestFile.readAsString();
        _manifest = json.decode(content) as Map<String, dynamic>;
      } catch (e) {
        print('⚠️  Warning: Failed to read manifest, creating new one: $e');
        _manifest = _createEmptyManifest();
      }
    } else {
      _manifest = _createEmptyManifest();
    }
  }

  /// Create empty manifest structure
  Map<String, dynamic> _createEmptyManifest() {
    return {
      'version': '1.0.0',
      'lastSync': DateTime.now().toIso8601String(),
      'figmaFileKey': '',
      'colors': <String, dynamic>{},
      'icons': <String, dynamic>{},
      'generatedFiles': <String, dynamic>{},
    };
  }

  /// Check if a color has changed
  bool hasColorChanged(String colorName, String hexValue, String originalName) {
    final colorEntry = _manifest['colors'][colorName] as Map<String, dynamic>?;

    if (colorEntry == null) {
      return true; // New color
    }

    return colorEntry['hexValue'] != hexValue ||
        colorEntry['originalName'] != originalName;
  }

  /// Check if an icon has changed
  Future<bool> hasIconChanged(
      String nodeId, String fileName, String imageUrl, String filePath) async {
    final iconEntry = _manifest['icons'][nodeId] as Map<String, dynamic>?;

    if (iconEntry == null) {
      return true; // New icon
    }

    // Check if URL changed (indicates content might be different)
    if (iconEntry['imageUrl'] != imageUrl) {
      return true;
    }

    // Check if file name changed
    if (iconEntry['fileName'] != fileName) {
      return true;
    }

    // Check if local file exists
    final file = File(filePath);
    if (!await file.exists()) {
      return true; // File was deleted
    }

    // Check file hash if we have it stored
    if (iconEntry['fileHash'] != null) {
      final currentHash = await _calculateFileHash(filePath);
      if (iconEntry['fileHash'] != currentHash) {
        return true; // Content changed
      }
    }

    return false; // No changes detected
  }

  /// Check if a generated file needs updating
  Future<bool> hasGeneratedFileChanged(
      String fileName, Map<String, dynamic> sourceData) async {
    final fileEntry =
        _manifest['generatedFiles'][fileName] as Map<String, dynamic>?;

    if (fileEntry == null) {
      return true; // New file
    }

    // Create a hash of the source data to detect changes
    final sourceHash = _calculateDataHash(sourceData);

    return fileEntry['sourceHash'] != sourceHash;
  }

  /// Update color in manifest
  void updateColor(String colorName, String hexValue, String originalName) {
    _manifest['colors'][colorName] = {
      'hexValue': hexValue,
      'originalName': originalName,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  /// Update icon in manifest
  Future<void> updateIcon(
      String nodeId, String fileName, String imageUrl, String filePath) async {
    String? fileHash;

    final file = File(filePath);
    if (await file.exists()) {
      fileHash = await _calculateFileHash(filePath);
    }

    _manifest['icons'][nodeId] = {
      'fileName': fileName,
      'imageUrl': imageUrl,
      'filePath': filePath,
      'fileHash': fileHash,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  /// Update generated file in manifest
  void updateGeneratedFile(String fileName, Map<String, dynamic> sourceData) {
    final sourceHash = _calculateDataHash(sourceData);

    _manifest['generatedFiles'][fileName] = {
      'sourceHash': sourceHash,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  /// Remove icon from manifest (when deleted from Figma)
  void removeIcon(String nodeId) {
    _manifest['icons'].remove(nodeId);
  }

  /// Remove color from manifest (when deleted from Figma)
  void removeColor(String colorName) {
    _manifest['colors'].remove(colorName);
  }

  /// Get list of orphaned icons (exist in manifest but not in current Figma data)
  List<String> getOrphanedIcons(List<String> currentNodeIds) {
    final manifestNodeIds =
        (_manifest['icons'] as Map<String, dynamic>).keys.toList();
    return manifestNodeIds
        .where((nodeId) => !currentNodeIds.contains(nodeId))
        .toList();
  }

  /// Get list of orphaned colors
  List<String> getOrphanedColors(List<String> currentColorNames) {
    final manifestColorNames =
        (_manifest['colors'] as Map<String, dynamic>).keys.toList();
    return manifestColorNames
        .where((colorName) => !currentColorNames.contains(colorName))
        .toList();
  }

  /// Save manifest to file
  Future<void> save({String? figmaFileKey}) async {
    if (figmaFileKey != null) {
      _manifest['figmaFileKey'] = figmaFileKey;
    }
    _manifest['lastSync'] = DateTime.now().toIso8601String();

    final manifestFile = File(manifestPath);

    // Create directory if it doesn't exist
    await manifestFile.parent.create(recursive: true);

    // Write pretty-printed JSON
    const encoder = JsonEncoder.withIndent('  ');
    final jsonString = encoder.convert(_manifest);

    await manifestFile.writeAsString(jsonString);
  }

  /// Calculate SHA-256 hash of a file
  Future<String> _calculateFileHash(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Calculate hash of data structure
  String _calculateDataHash(Map<String, dynamic> data) {
    final jsonString = json.encode(data);
    final bytes = utf8.encode(jsonString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Get manifest statistics
  Map<String, int> getStats() {
    return {
      'colors': (_manifest['colors'] as Map<String, dynamic>).length,
      'icons': (_manifest['icons'] as Map<String, dynamic>).length,
      'generatedFiles':
          (_manifest['generatedFiles'] as Map<String, dynamic>).length,
    };
  }

  /// Clean up orphaned files
  Future<void> cleanupOrphanedFiles(String assetsDirectory) async {
    final orphanedIcons = getOrphanedIcons([]);

    for (final nodeId in orphanedIcons) {
      final iconData = _manifest['icons'][nodeId] as Map<String, dynamic>?;
      if (iconData != null) {
        final filePath = iconData['filePath'] as String?;
        if (filePath != null) {
          final file = File(filePath);
          if (await file.exists()) {
            await file.delete();
            print('🗑️  Deleted orphaned file: ${path.basename(filePath)}');
          }
        }
      }
      removeIcon(nodeId);
    }
  }

  /// Print change summary
  void printChangeSummary(
      List<String> newColors,
      List<String> changedColors,
      List<String> newIcons,
      List<String> changedIcons,
      List<String> orphanedItems) {
    print('\n📊 Change Summary:');

    if (newColors.isNotEmpty) {
      print('  🆕 New colors: ${newColors.length}');
    }

    if (changedColors.isNotEmpty) {
      print('  🔄 Changed colors: ${changedColors.length}');
    }

    if (newIcons.isNotEmpty) {
      print('  🆕 New icons: ${newIcons.length}');
    }

    if (changedIcons.isNotEmpty) {
      print('  🔄 Changed icons: ${changedIcons.length}');
    }

    if (orphanedItems.isNotEmpty) {
      print('  🗑️  Orphaned items: ${orphanedItems.length}');
    }

    if (newColors.isEmpty &&
        changedColors.isEmpty &&
        newIcons.isEmpty &&
        changedIcons.isEmpty &&
        orphanedItems.isEmpty) {
      print('  ✨ No changes detected');
    }
  }
}
