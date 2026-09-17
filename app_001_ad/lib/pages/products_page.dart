import 'dart:async';

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
  static const refreshInterval = Duration(seconds: 3);

  final ProductsService productsService = ProductsService();
  final Set<int> changingStatus = {};
  final List<Products> products = [];
  ProductStatusFilter selectedFilter = ProductStatusFilter.all;
  Timer? refreshTimer;
  Object? loadError;
  bool isInitialLoading = true;
  bool isRefreshing = false;
  bool hasPendingRefresh = false;

  @override
  void initState() {
    super.initState();
    refreshProducts();
    refreshTimer = Timer.periodic(refreshInterval, (_) => refreshProducts());
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> refreshProducts() async {
    if (isRefreshing) {
      hasPendingRefresh = true;
      return;
    }
    isRefreshing = true;

    try {
      final updatedProducts = await productsService.getProducts();
      if (!mounted) return;
      setState(() {
        products
          ..clear()
          ..addAll(updatedProducts);
        loadError = null;
        isInitialLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        if (products.isEmpty) loadError = error;
        isInitialLoading = false;
      });
    } finally {
      isRefreshing = false;
      if (hasPendingRefresh && mounted) {
        hasPendingRefresh = false;
        unawaited(refreshProducts());
      }
    }
  }

  void changeFilter(Set<ProductStatusFilter> selection) {
    setState(() => selectedFilter = selection.first);
    refreshProducts();
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
      onRefresh: refreshProducts,
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

  List<Products> get filteredProducts {
    return switch (selectedFilter) {
      ProductStatusFilter.all => List.of(products),
      ProductStatusFilter.active =>
        products.where((product) => product.isActive).toList(),
      ProductStatusFilter.inactive =>
        products.where((product) => !product.isActive).toList(),
    };
  }

  String get emptyMessage {
    return switch (selectedFilter) {
      ProductStatusFilter.all => 'No se encontraron productos.',
      ProductStatusFilter.active => 'No se encontraron productos activos.',
      ProductStatusFilter.inactive => 'No se encontraron productos inactivos.',
    };
  }

  Widget buildFilterSelector({required bool isCompact}) {
    if (isCompact) {
      return DropdownButton<ProductStatusFilter>(
        value: selectedFilter,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        items: const [
          DropdownMenuItem(
            value: ProductStatusFilter.all,
            child: Text('Todos'),
          ),
          DropdownMenuItem(
            value: ProductStatusFilter.active,
            child: Text('Activos'),
          ),
          DropdownMenuItem(
            value: ProductStatusFilter.inactive,
            child: Text('Inactivos'),
          ),
        ],
        onChanged: (value) {
          if (value != null) changeFilter({value});
        },
      );
    }

    return SegmentedButton<ProductStatusFilter>(
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
    );
  }

  Widget buildProductCards(List<Products> products) {
    return RefreshIndicator(
      onRefresh: refreshProducts,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: products.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final product = products[index];
          final isChanging = changingStatus.contains(product.id);

          return Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildProductImage(product),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.attach_money, size: 18),
                        label: Text(product.price.toStringAsFixed(2)),
                      ),
                      Chip(
                        avatar: const Icon(
                          Icons.inventory_2_outlined,
                          size: 18,
                        ),
                        label: Text('Existencias: ${product.stock}'),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    children: [
                      const Text('Activo'),
                      Switch(
                        value: product.isActive,
                        onChanged: isChanging
                            ? null
                            : (value) => changeProductStatus(product, value),
                      ),
                      const Spacer(),
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildProductsContent({required bool isCompact}) {
    if (isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (loadError != null && products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(loadError.toString(), textAlign: TextAlign.center),
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

    final visibleProducts = filteredProducts;
    if (visibleProducts.isEmpty) {
      return RefreshIndicator(
        onRefresh: refreshProducts,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: 280, child: Center(child: Text(emptyMessage))),
          ],
        ),
      );
    }

    return isCompact
        ? buildProductCards(visibleProducts)
        : buildProductsTable(visibleProducts);
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 700;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: isCompact
                    ? InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Mostrar productos',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: buildFilterSelector(isCompact: true),
                      )
                    : buildFilterSelector(isCompact: false),
              ),
              Expanded(child: buildProductsContent(isCompact: isCompact)),
            ],
          );
        },
      ),
    );
  }
}
