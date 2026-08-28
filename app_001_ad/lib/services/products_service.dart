import 'dart:async';
import 'dart:convert';

import 'package:app_001_ad/models/products.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ProductsService {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get _baseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:5050'
        : 'http://localhost:5050';
  }

  final String url;

  ProductsService({String? baseUrl})
    : url =
          '${(baseUrl ?? _baseUrl).replaceFirst(RegExp(r'/$'), '')}/api/Products';

  Future<List<Products>> getProducts() async {
    final response = await _send(http.get(Uri.parse(url)));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Products.fromJson(item)).toList();
    }

    throw ProductsServiceException(
      _errorMessage(response, 'No se pudieron cargar los productos.'),
      statusCode: response.statusCode,
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
        _errorMessage(response, 'No se pudo crear el producto.'),
        statusCode: response.statusCode,
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
        _errorMessage(response, 'No se pudo actualizar el producto.'),
        statusCode: response.statusCode,
      );
    }
  }

  Future<void> deleteProduct(int id) async {
    final response = await _send(http.delete(Uri.parse('$url/$id')));

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw ProductsServiceException(
        _errorMessage(response, 'No se pudo eliminar el producto.'),
        statusCode: response.statusCode,
      );
    }
  }

  Future<http.Response> _send(Future<http.Response> request) async {
    try {
      return await request.timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const ProductsServiceException(
        'La API no respondió dentro del tiempo esperado.',
      );
    } on http.ClientException {
      throw const ProductsServiceException(
        'No se pudo conectar con la API. Verifique la dirección del servidor '
        'y la red.',
      );
    }
  }

  String _errorMessage(http.Response response, String fallback) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final message = body['message'];
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

        final detail = body['detail'] ?? body['title'];
        if (detail is String && detail.isNotEmpty) return detail;
      }
    } on FormatException {
      // Some server errors do not return JSON.
    }

    return '$fallback (HTTP ${response.statusCode})';
  }
}

class ProductsServiceException implements Exception {
  final String message;
  final int? statusCode;

  const ProductsServiceException(this.message, {this.statusCode});

  bool get isStaleData => statusCode == 404 || statusCode == 409;

  @override
  String toString() => message;
}
