import 'dart:async';
import 'dart:convert';

import 'package:app_001_ad/models/products.dart';
import 'package:http/http.dart' as http;

class ProductsService {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5050',
  );

  final String url;

  ProductsService({String baseUrl = _baseUrl})
    : url = '${baseUrl.replaceFirst(RegExp(r'/$'), '')}/api/Products';

  Future<List<Products>> getProducts() async {
    final response = await _send(http.get(Uri.parse(url)));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Products.fromJson(item)).toList();
    }

    throw ProductsServiceException(
      _errorMessage(response, 'Could not load products.'),
    );
  }

  Future<void> createProduct(Products product) async {
    final response = await _send(
      http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(product.toJson()),
      ),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw ProductsServiceException(
        _errorMessage(response, 'Could not create the product.'),
      );
    }
  }

  Future<void> updateProduct(Products product) async {
    final response = await _send(
      http.put(
        Uri.parse('$url/${product.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(product.toJson()),
      ),
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw ProductsServiceException(
        _errorMessage(response, 'Could not update the product.'),
      );
    }
  }

  Future<void> deleteProduct(int id) async {
    final response = await _send(http.delete(Uri.parse('$url/$id')));

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw ProductsServiceException(
        _errorMessage(response, 'Could not delete the product.'),
      );
    }
  }

  Future<http.Response> _send(Future<http.Response> request) async {
    try {
      return await request.timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const ProductsServiceException('The API did not respond in time.');
    } on http.ClientException {
      throw const ProductsServiceException(
        'Could not connect to the API. Check the server address and network.',
      );
    }
  }

  String _errorMessage(http.Response response, String fallback) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final message = body['message'] ?? body['detail'] ?? body['title'];
        if (message is String && message.isNotEmpty) return message;

        final errors = body['errors'];
        if (errors is Map<String, dynamic>) {
          final messages = errors.values
              .whereType<List>()
              .expand((items) => items)
              .whereType<String>()
              .toList();
          if (messages.isNotEmpty) return messages.join('\n');
        }
      }
    } on FormatException {
      // Some server errors do not return JSON.
    }

    return '$fallback (HTTP ${response.statusCode})';
  }
}

class ProductsServiceException implements Exception {
  final String message;

  const ProductsServiceException(this.message);

  @override
  String toString() => message;
}
