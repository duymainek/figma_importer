![Figma Puller Banner](https://github.com/duymainek/figma_importer/blob/main/banner/Gemini_Generated_Image_23oo8j23oo8j23oo.png?raw=true)

# Figma Puller

A Dart package to import design tokens and assets from Figma files. This package allows you to automatically extract colors, icons, and other design elements from your Figma designs and generate Dart code for use in your Flutter applications.

## Features

- 🎨 **Extract Colors**: Pull color styles from Figma and generate Flutter-compatible color constants
- 🔍 **Extract Icons**: Download SVG/PNG icons from Figma components and generate asset references
- 🧠 **Smart Change Detection**: Only download changed assets, skip unchanged files for faster builds
- 📱 **Flutter Integration**: Generate theme extensions and widget helpers for seamless Flutter integration
- 🏗️ **Code Generation**: Automatically generate organized Dart files with proper naming conventions
- 📂 **Categorization**: Organize colors and icons into logical categories
- 🧹 **Clean Mode**: Option to clean directories before generating new files
- 🛠️ **CLI Tool**: Easy-to-use command-line interface with comprehensive options

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dev_dependencies:
  figma_puller: ^1.0.1
```

Then run:

```bash
dart pub get
```

## Setup

### 1. Get Your Figma API Token

1. Go to [Figma Settings](https://www.figma.com/settings)
2. Navigate to "Personal access tokens"
3. Create a new token
4. Copy and save the token securely

### 2. Get Your Figma File Key

1. Open your Figma file
2. Look at the URL: `https://www.figma.com/file/ABC123XYZ/My-Design-System`
3. The file key is the part between `/file/` and the file name (`ABC123XYZ` in this example)

## Usage

### Command Line Interface

The package provides a `figma_pull` command:

```bash
# Basic usage
figma_pull --file-key YOUR_FILE_KEY --token YOUR_API_TOKEN

# Custom output directories
figma_pull -k YOUR_FILE_KEY -t YOUR_TOKEN -o lib/design -a assets/images

# Only extract colors
figma_pull -k YOUR_FILE_KEY -t YOUR_TOKEN --colors-only

# Generate categorized files with theme extension
figma_pull -k YOUR_FILE_KEY -t YOUR_TOKEN --categorized --theme-extension

# Extract icons with widget helpers
figma_pull -k YOUR_FILE_KEY -t YOUR_TOKEN --icon-widgets --icon-format svg

# Clean directories before generating (force re-download)
figma_pull -k YOUR_FILE_KEY -t YOUR_TOKEN --clean

# Smart update mode (default - skip unchanged files)
figma_pull -k YOUR_FILE_KEY -t YOUR_TOKEN
```

### Command Options

| Option | Description | Default |
|--------|-------------|---------|
| `--file-key`, `-k` | Figma file key (required) | - |
| `--token`, `-t` | Figma API token (required) | - |
| `--output-dir`, `-o` | Output directory for generated files | `lib/generated` |
| `--assets-dir`, `-a` | Assets directory for downloaded icons | `assets/icons` |
| `--icons-frame`, `-f` | Name of the frame containing icons | `Icons` |
| `--icon-format` | Format for downloaded icons (svg, png) | `svg` |
| `--colors-only` | Only extract colors, skip icons | `false` |
| `--icons-only` | Only extract icons, skip colors | `false` |
| `--categorized` | Generate categorized output files | `false` |
| `--theme-extension` | Generate Flutter theme extension | `false` |
| `--icon-widgets` | Generate Flutter widget helpers | `false` |
| `--clean` | Clean output directories before generating | `false` |
| `--verbose`, `-v` | Enable verbose logging | `false` |
| `--help`, `-h` | Show help message | `false` |

## Smart Change Detection

The package includes intelligent change detection to optimize build times and avoid unnecessary downloads:

### How It Works

1. **Manifest Tracking**: Creates a `.figma_manifest.json` file to track:
   - File hashes for each downloaded icon
   - Color values and metadata
   - Figma node IDs and image URLs
   - Last modification timestamps

2. **Smart Updates**: On subsequent runs:
   - ✅ **Skip unchanged files**: Files with matching hashes are not re-downloaded
   - 🔄 **Update changed content**: Only downloads files that have actually changed
   - 🆕 **Detect new assets**: Automatically downloads newly added icons/colors
   - 🗑️ **Clean up removed items**: Removes assets no longer in Figma

3. **Force Clean Mode**: Use `--clean` to bypass detection and force full re-download

### Example Output

```bash
📊 Smart detection: 45 unchanged, 3 updated
✓ Downloaded vuesax_linear_setting.svg
✓ Downloaded new_icon.svg  
✓ Downloaded updated_logo.svg
⏭️ Skipping existing file: home.svg
⏭️ Skipping existing file: profile.svg
```

### Manifest File

The `.figma_manifest.json` contains:

```json
{
  "version": "1.0.0",
  "figmaFileKey": "UIVGNiHdzfETwuT4Dny64S",
  "lastUpdated": "2024-01-15T10:30:00Z",
  "icons": {
    "1234:5678": {
      "nodeId": "1234:5678",
      "fileName": "home.svg",
      "imageUrl": "https://...",
      "fileHash": "abc123...",
      "lastModified": "2024-01-15T10:25:00Z"
    }
  },
  "colors": {
    "primaryBlue": {
      "name": "primaryBlue", 
      "hexValue": "0xFF007AFF",
      "originalName": "Primary/Blue"
    }
  }
}
```

## Generated Files

### Colors

The package generates color files based on your Figma color styles:

```dart
// lib/generated/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  /// Primary Blue
  static const Color primaryBlue = Color(0xFF007AFF);
  
  /// Secondary Gray
  static const Color secondaryGray = Color(0xFF8E8E93);
  
  // ... more colors
}
```

### Theme Extension (Optional)

When using `--theme-extension`, a theme extension is generated:

```dart
// lib/generated/app_color_theme.dart
@immutable
class AppColorTheme extends ThemeExtension<AppColorTheme> {
  const AppColorTheme({
    required this.primaryBlue,
    required this.secondaryGray,
    // ... more colors
  });

  final Color primaryBlue;
  final Color secondaryGray;
  // ... implementation
}
```

### Icons

Icon assets and references are generated:

```dart
// lib/generated/app_icons.dart
class AppIcons {
  AppIcons._();

  /// Home icon
  static const String home = 'assets/icons/home.svg';
  
  /// Profile icon
  static const String profile = 'assets/icons/profile.svg';
  
  // ... more icons
}
```

### Icon Widgets (Optional)

When using `--icon-widgets`, widget helpers are generated:

```dart
// lib/generated/app_icon_widgets.dart
class AppIconWidgets {
  AppIconWidgets._();

  /// Home icon widget
  static Widget home({
    double? width,
    double? height,
    Color? color,
    BoxFit fit = BoxFit.contain,
  }) {
    return SvgPicture.asset(
      'assets/icons/home.svg',
      width: width,
      height: height,
      colorFilter: color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null,
      fit: fit,
    );
  }
  
  // ... more icon widgets
}
```

## Figma Setup Requirements

### For Colors

Colors are extracted from Figma **Color Styles**. Make sure to:

1. Create color styles in Figma (not just random colored shapes)
2. Give your color styles descriptive names (e.g., "Primary/Blue-500", "Secondary/Gray-200")
3. The names will be converted to valid Dart variable names automatically

### For Icons

Icons should be organized as **Components** within a frame. The default setup expects:

1. A frame named "Icons" (customizable with `--icons-frame`)
2. Each icon as a separate Component within this frame
3. Components should have descriptive names (e.g., "home", "user-profile", "arrow-right")

Alternative setup:
- If no "Icons" frame is found, all Components in the file will be treated as potential icons

## Flutter Integration

### 1. Add Assets to pubspec.yaml

After running the tool, add the generated assets to your `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/icons/
```

The tool will also print the exact assets list you need to add.

### 2. Add Dependencies

For SVG icons, add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_svg: ^2.0.0
```

### 3. Use Generated Code

```dart
import 'package:your_app/generated/app_colors.dart';
import 'package:your_app/generated/app_icon_widgets.dart';

// Use colors
Container(
  color: AppColors.primaryBlue,
  child: Text(
    'Hello World',
    style: TextStyle(color: AppColors.secondaryGray),
  ),
)

// Use icons
AppIconWidgets.home(
  width: 24,
  height: 24,
  color: AppColors.primaryBlue,
)
```

## Programmatic Usage

You can also use the package programmatically:

```dart
import 'package:figma_puller/figma_puller.dart';

void main() async {
  final apiClient = FigmaApiClient(apiToken: 'your_token');
  
  try {
    // Fetch Figma file
    final figmaFile = await apiClient.getFile('your_file_key');
    
    // Extract colors
    final colors = ColorExtractor.extractColors(figmaFile);
    await ColorGenerator.generateColorFile(colors, 'lib/generated');
    
    // Extract icons
    final iconExtractor = IconExtractor(apiClient: apiClient);
    final icons = await iconExtractor.extractIcons(figmaFile, 'your_file_key');
    await iconExtractor.downloadIcons(icons, 'assets/icons');
    await IconGenerator.generateIconFile(icons, 'lib/generated');
    
  } finally {
    apiClient.dispose();
  }
}
```

## Troubleshooting

### Common Issues

1. **"No colors found"**: Make sure you're using Color Styles in Figma, not just colored shapes
2. **"No icons found"**: Check that your icons are Components and the frame name matches `--icons-frame`
3. **"Failed to load Figma file"**: Verify your API token and file key are correct
4. **"Permission denied"**: Make sure your API token has access to the Figma file
5. **"Download timeout"**: Some icons may timeout during download - the tool will retry and continue
6. **"Duplicate icons skipped"**: Multiple Figma nodes with the same name - only the first one is processed
7. **"Color generation errors"**: Check that color names don't contain invalid characters

### Smart Change Detection Issues

- **Manifest corrupted**: Delete `.figma_manifest.json` and run again
- **Files not updating**: Use `--clean` flag to force re-download
- **Wrong change detection**: Verify file permissions in output directories

### Debug Mode

Use the `--verbose` flag to see detailed information about what the tool is processing:

```bash
figma_pull -k YOUR_FILE_KEY -t YOUR_TOKEN --verbose
```

This will show:
- Detailed API responses
- File hash calculations  
- Change detection decisions
- Download progress and failures

## Performance & Best Practices

### Optimization Tips

1. **Use Smart Change Detection**: Let the tool skip unchanged files automatically
2. **Organize Figma Files**: Keep icons in dedicated frames for faster processing
3. **Consistent Naming**: Use clear, consistent naming conventions in Figma
4. **Batch Updates**: Run the tool periodically rather than after every small change
5. **Clean When Needed**: Use `--clean` only when you suspect cache issues

### CI/CD Integration

For automated builds, consider:

```yaml
# GitHub Actions example
- name: Update Design Tokens
  run: |
    dart pub get
    figma_pull -k ${{ secrets.FIGMA_FILE_KEY }} -t ${{ secrets.FIGMA_TOKEN }} --verbose
    
# Only commit if files changed
- name: Commit changes
  run: |
    git add lib/generated/ assets/icons/
    git diff --staged --quiet || git commit -m "Update design tokens from Figma"
```

### File Organization

Recommended project structure:

```
your_app/
├── lib/
│   ├── generated/          # Generated Dart files
│   │   ├── app_colors.dart
│   │   ├── app_icons.dart
│   │   └── .figma_manifest.json
├── assets/
│   └── icons/             # Downloaded icon assets
│       ├── home.svg
│       └── profile.svg
└── pubspec.yaml
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.