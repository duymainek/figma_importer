# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2025-08-27

### Added
- Added banner image to README.md for better visual presentation
- Smart Change Detection system to optimize build times and avoid unnecessary downloads
- Manifest tracking system (.figma_manifest.json) for intelligent file change detection
- Clean mode option (--clean flag) to force re-download all assets

### Changed
- Package renamed from `figma_importer` to `figma_puller` for better naming consistency
- Updated README with GitHub-hosted banner image URL
- Improved documentation with Smart Change Detection details
- Enhanced CLI with additional options and better help messages

### Fixed
- Fixed color variable naming issues with special characters and numbers
- Improved error handling for network timeouts and API failures
- Fixed duplicate icon detection and processing


## [1.0.0] - 2025-08-27

### Added
- Initial release of Figma Importer
- Extract colors from Figma color styles
- Extract icons from Figma components
- Generate Flutter-compatible Dart code
- CLI tool `figma_pull` with comprehensive options
- Support for categorized output files
- Flutter theme extension generation
- Icon widget helpers generation
- Comprehensive documentation and examples
- Error handling and validation
- Support for SVG and PNG icon formats
- Automatic asset management
- String utilities for proper Dart naming conventions

### Features
- **Color Extraction**: Pull color styles from Figma and generate Flutter Color constants
- **Icon Extraction**: Download SVG/PNG icons and generate asset references
- **Code Generation**: Automatically generate organized Dart files
- **CLI Interface**: Easy-to-use command-line tool
- **Flutter Integration**: Theme extensions and widget helpers
- **Categorization**: Organize colors and icons logically
- **Programmatic API**: Use the package directly in Dart code