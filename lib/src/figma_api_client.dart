import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/figma_response.dart';

/// Client for interacting with Figma API
class FigmaApiClient {
  final String apiToken;
  final http.Client _httpClient;

  static const String _baseUrl = 'https://api.figma.com/v1';

  FigmaApiClient({
    required this.apiToken,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// Get headers for Figma API requests
  Map<String, String> get _headers => {
        'X-Figma-Token': apiToken,
        'Content-Type': 'application/json',
      };

  /// Get a Figma file by file key
  Future<FigmaFile> getFile(String fileKey) async {
    final url = Uri.parse('$_baseUrl/files/$fileKey');

    try {
      final response = await _httpClient.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return FigmaFile.fromJson(jsonData);
      } else {
        throw FigmaApiException(
          'Failed to load Figma file: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      if (e is FigmaApiException) rethrow;
      throw FigmaApiException('Network error: $e', null);
    }
  }

  /// Get images for specific nodes
  Future<FigmaImageResponse> getImages({
    required String fileKey,
    required List<String> nodeIds,
    String format = 'svg',
    double scale = 1.0,
  }) async {
    final nodeIdsParam = nodeIds.join(',');
    final url = Uri.parse(
        '$_baseUrl/images/$fileKey?ids=$nodeIdsParam&format=$format&scale=$scale');

    try {
      final response = await _httpClient.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return FigmaImageResponse.fromJson(jsonData);
      } else {
        throw FigmaApiException(
          'Failed to get images: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      if (e is FigmaApiException) rethrow;
      throw FigmaApiException('Network error: $e', null);
    }
  }

  /// Download an image from URL
  Future<List<int>> downloadImage(String imageUrl) async {
    try {
      final response = await _httpClient.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw FigmaApiException(
          'Failed to download image: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      if (e is FigmaApiException) rethrow;
      throw FigmaApiException(
          'Network error while downloading image: $e', null);
    }
  }

  /// Dispose the HTTP client
  void dispose() {
    _httpClient.close();
  }
}

/// Exception thrown by Figma API operations
class FigmaApiException implements Exception {
  final String message;
  final String? responseBody;

  FigmaApiException(this.message, this.responseBody);

  @override
  String toString() {
    if (responseBody != null) {
      return 'FigmaApiException: $message\nResponse: $responseBody';
    }
    return 'FigmaApiException: $message';
  }
}
