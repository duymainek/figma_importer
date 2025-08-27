/// Utility functions for string manipulation
class StringUtils {
  /// Convert a string to camelCase
  static String toCamelCase(String input) {
    if (input.isEmpty) return input;

    // Split by common separators
    final words = input
        .split(RegExp(r'[/\-_\s\.]+'))
        .where((word) => word.isNotEmpty)
        .map((word) => word.toLowerCase())
        .toList();

    if (words.isEmpty) return '';

    // First word stays lowercase, subsequent words are capitalized
    final result = StringBuffer(words.first);
    for (int i = 1; i < words.length; i++) {
      result.write(_capitalize(words[i]));
    }

    return result.toString();
  }

  /// Convert a string to PascalCase
  static String toPascalCase(String input) {
    if (input.isEmpty) return input;

    final words = input
        .split(RegExp(r'[/\-_\s\.]+'))
        .where((word) => word.isNotEmpty)
        .map((word) => _capitalize(word.toLowerCase()))
        .toList();

    return words.join('');
  }

  /// Convert a string to snake_case
  static String toSnakeCase(String input) {
    if (input.isEmpty) return input;

    return input
        .split(RegExp(r'[/\-\s\.]+'))
        .where((word) => word.isNotEmpty)
        .map((word) => word.toLowerCase())
        .join('_');
  }

  /// Capitalize first letter of a string
  static String _capitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }

  /// Clean a string to be a valid Dart variable name
  static String toDartVariableName(String input) {
    if (input.isEmpty) return 'unnamed';

    // Remove special characters and clean the input first
    String cleaned = input
        .replaceAll(RegExp(r'[#%&*+=<>!@$^|~`()\[\]{}:;".,?/\\-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (cleaned.isEmpty) return 'unnamed';

    final camelCase = toCamelCase(cleaned);

    if (camelCase.isEmpty) return 'unnamed';

    // Ensure it starts with a letter or underscore
    if (!RegExp(r'^[a-zA-Z_]').hasMatch(camelCase)) {
      return 'var$camelCase';
    }

    // Remove any remaining invalid characters
    final result = camelCase.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');

    return result.isEmpty ? 'unnamed' : result;
  }

  /// Clean a string to be a valid Dart class name
  static String toDartClassName(String input) {
    final pascalCase = toPascalCase(input);

    // Ensure it starts with a letter
    if (pascalCase.isNotEmpty && !RegExp(r'^[a-zA-Z]').hasMatch(pascalCase)) {
      return 'Class$pascalCase';
    }

    // Remove any remaining invalid characters
    return pascalCase.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
  }

  /// Convert Figma layer name to a readable description
  static String toDescription(String figmaName) {
    return figmaName
        .split(RegExp(r'[/\-_]+'))
        .where((word) => word.isNotEmpty)
        .map((word) => _capitalize(word.toLowerCase()))
        .join(' ');
  }
}
