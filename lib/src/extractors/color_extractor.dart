import '../models/figma_response.dart';
import '../utils/string_utils.dart';

/// Extracts color information from Figma data
class ColorExtractor {
  /// Extract colors from Figma file data
  static Map<String, ColorInfo> extractColors(FigmaFile figmaFile) {
    final colors = <String, ColorInfo>{};

    // Extract colors from styles
    for (final entry in figmaFile.styles.entries) {
      final style = entry.value;
      if (style.styleType == 'FILL') {
        // Find a node that uses this style to get the actual color value
        final colorValue = _findColorValueForStyleInDocument(
          figmaFile.document,
          entry.key,
        );

        if (colorValue != null) {
          final variableName = StringUtils.toDartVariableName(style.name);
          colors[variableName] = ColorInfo(
            name: variableName,
            originalName: style.name,
            description:
                style.description ?? StringUtils.toDescription(style.name),
            hexValue: colorValue.toHex(),
            figmaColor: colorValue,
          );
        }
      }
    }

    // Also extract colors from nodes directly (for cases without styles)
    _extractColorsFromDocument(figmaFile.document, colors);

    return colors;
  }

  /// Find color value for a specific style ID by searching through document
  static FigmaColor? _findColorValueForStyleInDocument(
      FigmaDocument document, String styleId) {
    // Search through all children of the document
    for (final child in document.children) {
      final result = _findColorValueForStyle(child, styleId);
      if (result != null) return result;
    }
    return null;
  }

  /// Find color value for a specific style ID by searching through nodes
  static FigmaColor? _findColorValueForStyle(FigmaNode node, String styleId) {
    // Check if this node uses the style
    if (node.styles != null && node.styles!['fill'] == styleId) {
      return _extractColorFromNode(node);
    }

    // Recursively search children
    for (final child in node.children) {
      final result = _findColorValueForStyle(child, styleId);
      if (result != null) return result;
    }

    return null;
  }

  /// Extract color from a node's fills
  static FigmaColor? _extractColorFromNode(FigmaNode node) {
    if (node.fills == null || node.fills!.isEmpty) return null;

    // Fills is a list, get the first solid fill
    for (final fill in node.fills!) {
      if (fill is Map<String, dynamic> &&
          fill['type'] == 'SOLID' &&
          fill['color'] != null) {
        return FigmaColor.fromJson(fill['color'] as Map<String, dynamic>);
      }
    }

    return null;
  }

  /// Extract colors from document (for nodes without styles)
  static void _extractColorsFromDocument(
      FigmaDocument document, Map<String, ColorInfo> colors) {
    for (final child in document.children) {
      _extractColorsFromNodes(child, colors);
    }
  }

  /// Extract colors from nodes recursively (for nodes without styles)
  static void _extractColorsFromNodes(
      FigmaNode node, Map<String, ColorInfo> colors) {
    // Skip if this node already has a style (we handle those separately)
    if (node.styles == null || node.styles!['fill'] == null) {
      final color = _extractColorFromNode(node);
      if (color != null) {
        final variableName = StringUtils.toDartVariableName(node.name);
        if (variableName.isNotEmpty && !colors.containsKey(variableName)) {
          colors[variableName] = ColorInfo(
            name: variableName,
            originalName: node.name,
            description: StringUtils.toDescription(node.name),
            hexValue: color.toHex(),
            figmaColor: color,
          );
        }
      }
    }

    // Recursively process children
    for (final child in node.children) {
      _extractColorsFromNodes(child, colors);
    }
  }

  /// Extract colors from a specific frame or component
  static Map<String, ColorInfo> extractColorsFromFrame(
    FigmaFile figmaFile,
    String frameName,
  ) {
    final colors = <String, ColorInfo>{};
    final frames = _findNodesByNameInDocument(figmaFile.document, frameName);

    for (final frame in frames) {
      _extractColorsFromNodes(frame, colors);
    }

    return colors;
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
}

/// Information about a color extracted from Figma
class ColorInfo {
  final String name;
  final String originalName;
  final String description;
  final String hexValue;
  final FigmaColor figmaColor;

  ColorInfo({
    required this.name,
    required this.originalName,
    required this.description,
    required this.hexValue,
    required this.figmaColor,
  });

  @override
  String toString() {
    return 'ColorInfo(name: $name, hex: $hexValue)';
  }
}
