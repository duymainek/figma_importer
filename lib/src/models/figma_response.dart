/// Models for Figma API responses
class FigmaFile {
  final String name;
  final FigmaDocument document;
  final Map<String, FigmaStyle> styles;

  FigmaFile({
    required this.name,
    required this.document,
    required this.styles,
  });

  factory FigmaFile.fromJson(Map<String, dynamic> json) {
    final stylesJson = json['styles'] as Map<String, dynamic>? ?? {};
    final styles = <String, FigmaStyle>{};

    for (final entry in stylesJson.entries) {
      styles[entry.key] = FigmaStyle.fromJson(entry.value);
    }

    return FigmaFile(
      name: json['name'] ?? '',
      document: FigmaDocument.fromJson(json['document'] ?? {}),
      styles: styles,
    );
  }
}

class FigmaDocument {
  final String id;
  final String name;
  final String type;
  final List<FigmaNode> children;

  FigmaDocument({
    required this.id,
    required this.name,
    required this.type,
    required this.children,
  });

  factory FigmaDocument.fromJson(Map<String, dynamic> json) {
    final childrenJson = json['children'] as List<dynamic>? ?? [];
    final children = childrenJson
        .map((child) => FigmaNode.fromJson(child as Map<String, dynamic>))
        .toList();

    return FigmaDocument(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      children: children,
    );
  }
}

class FigmaNode {
  final String id;
  final String name;
  final String type;
  final List<FigmaNode> children;
  final List<dynamic>? fills;
  final Map<String, dynamic>? styles;

  FigmaNode({
    required this.id,
    required this.name,
    required this.type,
    required this.children,
    this.fills,
    this.styles,
  });

  factory FigmaNode.fromJson(Map<String, dynamic> json) {
    final childrenJson = json['children'] as List<dynamic>? ?? [];
    final children = childrenJson
        .map((child) => FigmaNode.fromJson(child as Map<String, dynamic>))
        .toList();

    return FigmaNode(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      children: children,
      fills: json['fills'] as List<dynamic>?,
      styles: json['styles'] as Map<String, dynamic>?,
    );
  }

  /// Recursively find all nodes of a specific type
  List<FigmaNode> findNodesByType(String nodeType) {
    final result = <FigmaNode>[];

    if (type == nodeType) {
      result.add(this);
    }

    for (final child in children) {
      result.addAll(child.findNodesByType(nodeType));
    }

    return result;
  }

  /// Find nodes by name pattern
  List<FigmaNode> findNodesByName(String namePattern) {
    final result = <FigmaNode>[];
    final regex = RegExp(namePattern, caseSensitive: false);

    if (regex.hasMatch(name)) {
      result.add(this);
    }

    for (final child in children) {
      result.addAll(child.findNodesByName(namePattern));
    }

    return result;
  }
}

class FigmaStyle {
  final String key;
  final String name;
  final String styleType;
  final String? description;

  FigmaStyle({
    required this.key,
    required this.name,
    required this.styleType,
    this.description,
  });

  factory FigmaStyle.fromJson(Map<String, dynamic> json) {
    return FigmaStyle(
      key: json['key'] ?? '',
      name: json['name'] ?? '',
      styleType: json['styleType'] ?? '',
      description: json['description'],
    );
  }
}

class FigmaColor {
  final double r;
  final double g;
  final double b;
  final double a;

  FigmaColor({
    required this.r,
    required this.g,
    required this.b,
    required this.a,
  });

  factory FigmaColor.fromJson(Map<String, dynamic> json) {
    return FigmaColor(
      r: (json['r'] as num?)?.toDouble() ?? 0.0,
      g: (json['g'] as num?)?.toDouble() ?? 0.0,
      b: (json['b'] as num?)?.toDouble() ?? 0.0,
      a: (json['a'] as num?)?.toDouble() ?? 1.0,
    );
  }

  /// Convert to Flutter Color hex format
  String toHex() {
    final alpha = (a * 255).round();
    final red = (r * 255).round();
    final green = (g * 255).round();
    final blue = (b * 255).round();

    return '0x${alpha.toRadixString(16).padLeft(2, '0').toUpperCase()}'
        '${red.toRadixString(16).padLeft(2, '0').toUpperCase()}'
        '${green.toRadixString(16).padLeft(2, '0').toUpperCase()}'
        '${blue.toRadixString(16).padLeft(2, '0').toUpperCase()}';
  }
}

class FigmaImageResponse {
  final Map<String, String> images;

  FigmaImageResponse({required this.images});

  factory FigmaImageResponse.fromJson(Map<String, dynamic> json) {
    final imagesJson = json['images'] as Map<String, dynamic>? ?? {};
    final images = <String, String>{};

    for (final entry in imagesJson.entries) {
      if (entry.value is String) {
        images[entry.key] = entry.value as String;
      }
    }

    return FigmaImageResponse(images: images);
  }
}
