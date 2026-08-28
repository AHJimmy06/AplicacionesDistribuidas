import 'package:app_001_ad/models/products.dart';
import 'package:app_001_ad/pages/products_form_pages.dart';
import 'package:app_001_ad/services/products_service.dart';
import 'package:app_001_ad/utils/timed_dialog.dart';
import 'package:flutter/material.dart';

enum ProductStatusFilter { all, active, inactive }

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final ProductsService productsService = ProductsService();
  final Set<int> changingStatus = {};
  late Future<List<Products>> futureProducts;
  ProductStatusFilter selectedFilter = ProductStatusFilter.all;

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

  void changeFilter(Set<ProductStatusFilter> selection) {
    setState(() {
      selectedFilter = selection.first;
      futureProducts = productsService.getProducts();
    });
  }

  void showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  Future<void> showStaleProductDialog(ProductsServiceException error) async {
    await showTimedDialog<void>(
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
  }

  Future<void> handleOperationError(Object error) async {
    if (error is ProductsServiceException && error.isStaleData) {
      await showStaleProductDialog(error);
      if (mounted) refreshProducts();
      return;
    }

    if (mounted) showMessage(error.toString(), isError: true);
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
    final confirmed = await showTimedDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar producto?'),
        content: Text(
          '¿Está seguro de que desea eliminar "${product.name}"? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await productsService.deleteProduct(product);
      if (!mounted) return;
      refreshProducts();
      showMessage('Producto eliminado correctamente.');
    } catch (error) {
      if (!mounted) return;
      await handleOperationError(error);
    }
  }

  Future<void> changeProductStatus(Products product, bool isActive) async {
    setState(() => changingStatus.add(product.id));

    try {
      await productsService.updateProduct(product.copyWith(isActive: isActive));
      if (!mounted) return;
      refreshProducts();
      showMessage(
        isActive
            ? 'Producto activado correctamente.'
            : 'Producto desactivado correctamente.',
      );
    } catch (error) {
      if (!mounted) return;
      await handleOperationError(error);
    } finally {
      if (mounted) setState(() => changingStatus.remove(product.id));
    }
  }

  Widget buildProductImage(Products product) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        product.imageUrl,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 56,
          height: 56,
          color: Colors.grey.shade200,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }

  Widget buildProductsTable(List<Products> products) {
    return RefreshIndicator(
      onRefresh: () async {
        refreshProducts();
        await futureProducts;
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Imagen')),
                    DataColumn(label: Text('Nombre')),
                    DataColumn(label: Text('Descripción')),
                    DataColumn(label: Text('Precio'), numeric: true),
                    DataColumn(label: Text('Existencias'), numeric: true),
                    DataColumn(label: Text('Activo')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: products.map((product) {
                    final isChanging = changingStatus.contains(product.id);
                    return DataRow(
                      color: WidgetStateProperty.resolveWith(
                        (states) => product.isActive
                            ? null
                            : Colors.grey.withValues(alpha: 0.08),
                      ),
                      cells: [
                        DataCell(buildProductImage(product)),
                        DataCell(Text(product.name)),
                        DataCell(
                          SizedBox(
                            width: 220,
                            child: Text(
                              product.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(Text('\$${product.price.toStringAsFixed(2)}')),
                        DataCell(Text(product.stock.toString())),
                        DataCell(
                          Row(
                            children: [
                              Switch(
                                value: product.isActive,
                                onChanged: isChanging
                                    ? null
                                    : (value) =>
                                          changeProductStatus(product, value),
                              ),
                              Text(product.isActive ? 'Sí' : 'No'),
                            ],
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Editar',
                                icon: const Icon(Icons.edit),
                                onPressed: () =>
                                    openProductForm(product: product),
                              ),
                              IconButton(
                                tooltip: 'Eliminar',
                                icon: const Icon(Icons.delete),
                                onPressed: () => confirmDelete(product),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Productos JA')),
      floatingActionButton: FloatingActionButton(
        onPressed: openProductForm,
        tooltip: 'Nuevo producto',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: SegmentedButton<ProductStatusFilter>(
              segments: const [
                ButtonSegment(
                  value: ProductStatusFilter.all,
                  label: Text('Todos'),
                  icon: Icon(Icons.list_alt),
                ),
                ButtonSegment(
                  value: ProductStatusFilter.active,
                  label: Text('Activos'),
                  icon: Icon(Icons.check_circle_outline),
                ),
                ButtonSegment(
                  value: ProductStatusFilter.inactive,
                  label: Text('Inactivos'),
                  icon: Icon(Icons.pause_circle_outline),
                ),
              ],
              selected: {selectedFilter},
              onSelectionChanged: changeFilter,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Products>>(
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

                final products = switch (selectedFilter) {
                  ProductStatusFilter.all => snapshot.data ?? [],
                  ProductStatusFilter.active =>
                    (snapshot.data ?? [])
                        .where((product) => product.isActive)
                        .toList(),
                  ProductStatusFilter.inactive =>
                    (snapshot.data ?? [])
                        .where((product) => !product.isActive)
                        .toList(),
                };

                if (products.isEmpty) {
                  return Center(
                    child: Text(switch (selectedFilter) {
                      ProductStatusFilter.all => 'No se encontraron productos.',
                      ProductStatusFilter.active =>
                        'No se encontraron productos activos.',
                      ProductStatusFilter.inactive =>
                        'No se encontraron productos inactivos.',
                    }),
                  );
                }

                return buildProductsTable(products);
              },
            ),
          ),
        ],
      ),
    );
  }
}
