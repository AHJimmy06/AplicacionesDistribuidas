import 'package:app_001_ad/models/products.dart';
import 'package:app_001_ad/services/products_service.dart';
import 'package:flutter/material.dart';

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key, this.product});

  final Products? product;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  final ProductsService productsService = ProductsService();

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product != null) {
      nameController.text = product.name;
      priceController.text = product.price.toStringAsFixed(2);
      stockController.text = product.stock.toString();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    stockController.dispose();
    super.dispose();
  }

  Future<void> saveProduct() async {
    if (!formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => isSaving = true);

    final product = Products(
      id: widget.product?.id ?? 0,
      name: nameController.text.trim(),
      price: double.parse(priceController.text.trim().replaceAll(',', '.')),
      stock: int.parse(stockController.text.trim()),
      version: widget.product?.version ?? 0,
    );

    try {
      if (widget.product != null) {
        await productsService.updateProduct(product);
      } else {
        await productsService.createProduct(product);
      }

      if (!mounted) return;
      Navigator.pop(
        context,
        widget.product != null
            ? 'Product updated successfully.'
            : 'Product created successfully.',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString()), backgroundColor: Colors.red),
      );
    }
  }

  String? validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Name is required.';
    if (name.length < 2) return 'Name must have at least 2 characters.';
    if (name.length > 200) return 'Name cannot exceed 200 characters.';
    return null;
  }

  String? validatePrice(String? value) {
    final text = value?.trim().replaceAll(',', '.') ?? '';
    final price = double.tryParse(text);
    if (text.isEmpty) return 'Price is required.';
    if (price == null) return 'Enter a valid price.';
    if (price <= 0) return 'Price must be greater than zero.';
    if (price > 99999999.99) return 'Price exceeds the allowed maximum.';

    final parts = text.split('.');
    if (parts.length > 2 || (parts.length == 2 && parts[1].length > 2)) {
      return 'Price can have at most 2 decimal places.';
    }
    return null;
  }

  String? validateStock(String? value) {
    final text = value?.trim() ?? '';
    final stock = int.tryParse(text);
    if (text.isEmpty) return 'Stock is required.';
    if (stock == null) return 'Stock must be a whole number.';
    if (stock < 0) return 'Stock cannot be negative.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product != null ? 'Edit Product' : 'New Product'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nameController,
                validator: validateName,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: priceController,
                validator: validatePrice,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: stockController,
                validator: validateStock,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stock',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isSaving ? null : saveProduct,
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.product != null ? 'Update' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
