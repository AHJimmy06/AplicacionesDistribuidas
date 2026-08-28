import 'package:app_001_ad/models/products.dart';
import 'package:app_001_ad/pages/products_form_pages.dart';
import 'package:app_001_ad/services/products_service.dart';
import 'package:flutter/material.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final ProductsService productsService = ProductsService();
  late Future<List<Products>> futureProducts;

  @override
  void initState() {
    super.initState();
    futureProducts = productsService.getProducts();
  }

  void refreshProducts() {
    setState(() {
      futureProducts = productsService.getProducts();
    });
  }

  void showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> openProductForm({Products? product}) async {
    final message = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormPage(product: product),
      ),
    );

    if (!mounted) return;
    refreshProducts();
    if (message != null) showMessage(message);
  }

  Future<void> confirmDelete(Products product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar producto?'),
        content: Text(
          '¿Está seguro de que desea eliminar "${product.name}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await productsService.deleteProduct(product.id);
      if (!mounted) return;
      refreshProducts();
      showMessage('Producto eliminado correctamente.');
    } catch (error) {
      if (!mounted) return;

      if (error is ProductsServiceException && error.isStaleData) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Producto desactualizado'),
            content: Text(error.message),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
        if (!mounted) return;
        refreshProducts();
        return;
      }

      showMessage(error.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Productos JA')),
      floatingActionButton: FloatingActionButton(
        onPressed: openProductForm,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Products>>(
        future: futureProducts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: refreshProducts,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const Center(child: Text('No se encontraron productos.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              refreshProducts();
              await futureProducts;
            },
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(product.name),
                    subtitle: Text(
                      'Precio: \$${product.price.toStringAsFixed(2)}\n'
                      'Existencias: ${product.stock}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Editar',
                          icon: const Icon(Icons.edit),
                          onPressed: () => openProductForm(product: product),
                        ),
                        IconButton(
                          tooltip: 'Eliminar',
                          icon: const Icon(Icons.delete),
                          onPressed: () => confirmDelete(product),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
