import 'package:test/test.dart';
import 'package:figma_puller/figma_puller.dart';

void main() {
  group('StringUtils', () {
    test('toCamelCase converts strings correctly', () {
      expect(StringUtils.toCamelCase('Primary/Blue-500'),
          equals('primaryBlue500'));
      expect(
          StringUtils.toCamelCase('Secondary Gray'), equals('secondaryGray'));
      expect(StringUtils.toCamelCase('background-color-light'),
          equals('backgroundColorLight'));
      expect(StringUtils.toCamelCase('Icon/Arrow Right'),
          equals('iconArrowRight'));
      expect(
          StringUtils.toCamelCase('text_color_dark'), equals('textColorDark'));
    });

    test('toPascalCase converts strings correctly', () {
      expect(StringUtils.toPascalCase('Primary/Blue-500'),
          equals('PrimaryBlue500'));
      expect(
          StringUtils.toPascalCase('Secondary Gray'), equals('SecondaryGray'));
      expect(StringUtils.toPascalCase('background-color-light'),
          equals('BackgroundColorLight'));
      expect(StringUtils.toPascalCase('Icon/Arrow Right'),
          equals('IconArrowRight'));
      expect(
          StringUtils.toPascalCase('text_color_dark'), equals('TextColorDark'));
    });

    test('toSnakeCase converts strings correctly', () {
      expect(StringUtils.toSnakeCase('Primary/Blue-500'),
          equals('primary_blue_500'));
      expect(
          StringUtils.toSnakeCase('Secondary Gray'), equals('secondary_gray'));
      expect(StringUtils.toSnakeCase('background-color-light'),
          equals('background_color_light'));
      expect(StringUtils.toSnakeCase('Icon/Arrow Right'),
          equals('icon_arrow_right'));
      expect(StringUtils.toSnakeCase('text_color_dark'),
          equals('text_color_dark'));
    });

    test('toDartVariableName creates valid Dart variable names', () {
      expect(StringUtils.toDartVariableName('Primary/Blue-500'),
          equals('primaryBlue500'));
      expect(StringUtils.toDartVariableName('123Invalid'),
          equals('var123invalid'));
      expect(StringUtils.toDartVariableName('Valid-Name'), equals('validName'));
      expect(StringUtils.toDartVariableName(''), equals('unnamed'));
      expect(StringUtils.toDartVariableName('#000000'), equals('var000000'));
      expect(StringUtils.toDartVariableName('#FF-500'), equals('varFf500'));
    });

    test('toDartClassName creates valid Dart class names', () {
      expect(StringUtils.toDartClassName('Primary/Blue-500'),
          equals('PrimaryBlue500'));
      expect(
          StringUtils.toDartClassName('123Invalid'), equals('Class123invalid'));
      expect(StringUtils.toDartClassName('Valid-Name'), equals('ValidName'));
      expect(StringUtils.toDartClassName(''), equals(''));
    });

    test('toDescription creates readable descriptions', () {
      expect(StringUtils.toDescription('Primary/Blue-500'),
          equals('Primary Blue 500'));
      expect(StringUtils.toDescription('Secondary_Gray'),
          equals('Secondary Gray'));
      expect(StringUtils.toDescription('background-color-light'),
          equals('Background Color Light'));
    });
  });

  group('FigmaColor', () {
    test('toHex converts RGBA to hex correctly', () {
      final color = FigmaColor(r: 1.0, g: 0.0, b: 0.0, a: 1.0);
      expect(color.toHex(), equals('0xFFFF0000'));
    });

    test('toHex handles alpha correctly', () {
      final color = FigmaColor(r: 1.0, g: 1.0, b: 1.0, a: 0.5);
      expect(color.toHex(), equals('0x80FFFFFF'));
    });

    test('fromJson creates FigmaColor correctly', () {
      final json = {'r': 0.5, 'g': 0.25, 'b': 0.75, 'a': 0.8};
      final color = FigmaColor.fromJson(json);

      expect(color.r, equals(0.5));
      expect(color.g, equals(0.25));
      expect(color.b, equals(0.75));
      expect(color.a, equals(0.8));
    });
  });

  group('FigmaNode', () {
    test('findNodesByType finds nodes correctly', () {
      final child1 = FigmaNode(
        id: '1',
        name: 'Child1',
        type: 'COMPONENT',
        children: [],
      );
      final child2 = FigmaNode(
        id: '2',
        name: 'Child2',
        type: 'FRAME',
        children: [],
      );
      final parent = FigmaNode(
        id: '0',
        name: 'Parent',
        type: 'FRAME',
        children: [child1, child2],
      );

      final components = parent.findNodesByType('COMPONENT');
      expect(components.length, equals(1));
      expect(components.first.id, equals('1'));
    });

    test('findNodesByName finds nodes correctly', () {
      final child1 = FigmaNode(
        id: '1',
        name: 'Icon Home',
        type: 'COMPONENT',
        children: [],
      );
      final child2 = FigmaNode(
        id: '2',
        name: 'Button',
        type: 'FRAME',
        children: [],
      );
      final parent = FigmaNode(
        id: '0',
        name: 'Parent',
        type: 'FRAME',
        children: [child1, child2],
      );

      final icons = parent.findNodesByName('icon');
      expect(icons.length, equals(1));
      expect(icons.first.id, equals('1'));
    });
  });

  group('FigmaApiException', () {
    test('toString includes message and response body', () {
      final exception = FigmaApiException('Test error', 'Response body');
      expect(exception.toString(), contains('Test error'));
      expect(exception.toString(), contains('Response body'));
    });

    test('toString handles null response body', () {
      final exception = FigmaApiException('Test error', null);
      expect(exception.toString(), equals('FigmaApiException: Test error'));
    });
  });
}
