import 'package:app_001_ad/models/products.dart';
import 'package:app_001_ad/services/products_service.dart';
import 'package:app_001_ad/utils/timed_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final descriptionController = TextEditingController();
  final imageUrlController = TextEditingController();
  final ProductsService productsService = ProductsService();

  bool isSaving = false;
  bool isActive = true;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product != null) {
      nameController.text = product.name;
      priceController.text = product.price.toStringAsFixed(2);
      stockController.text = product.stock.toString();
      descriptionController.text = product.description;
      imageUrlController.text = product.imageUrl;
      isActive = product.isActive;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    stockController.dispose();
    descriptionController.dispose();
    imageUrlController.dispose();
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
      description: descriptionController.text.trim(),
      imageUrl: imageUrlController.text.trim(),
      isActive: isActive,
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
            ? 'Producto actualizado correctamente.'
            : 'Producto creado correctamente.',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => isSaving = false);

      if (error is ProductsServiceException && error.isStaleData) {
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
        if (!mounted) return;
        Navigator.pop(context);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  String? validateName(String? value) {
    final name = value ?? '';
    if (name.trim().isEmpty) return 'El nombre es obligatorio.';
    if (RegExp(r'\s').hasMatch(name))
      return 'El nombre no puede tener espacios.';
    if (name.length < 2) return 'El nombre debe tener al menos 2 letras.';
    if (name.length > 200) return 'El nombre no puede superar 200 letras.';
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ]+$').hasMatch(name)) {
      return 'El nombre solo puede contener letras.';
    }
    return null;
  }

  String? validatePrice(String? value) {
    if (RegExp(r'\s').hasMatch(value ?? '')) {
      return 'El precio no puede tener espacios.';
    }
    final text = value?.trim().replaceAll(',', '.') ?? '';
    final price = double.tryParse(text);
    if (text.isEmpty) return 'El precio es obligatorio.';
    if (price == null) return 'Ingrese un precio válido.';
    if (price <= 0) return 'El precio debe ser mayor que cero.';
    if (price > 99999999.99) return 'El precio supera el máximo permitido.';

    final parts = text.split('.');
    if (parts.length > 2 || (parts.length == 2 && parts[1].length > 2)) {
      return 'El precio puede tener máximo 2 decimales.';
    }
    return null;
  }

  String? validateStock(String? value) {
    if (RegExp(r'\s').hasMatch(value ?? '')) {
      return 'El stock no puede tener espacios.';
    }
    final text = value?.trim() ?? '';
    final stock = int.tryParse(text);
    if (text.isEmpty) return 'El stock es obligatorio.';
    if (stock == null) return 'El stock debe ser un número entero.';
    if (stock < 0) return 'El stock no puede ser negativo.';
    return null;
  }

  String? validateDescription(String? value) {
    final description = value?.trim() ?? '';
    if (description.isEmpty) return 'La descripción es obligatoria.';
    if (description.length > 500) {
      return 'La descripción no puede superar 500 caracteres.';
    }
    return null;
  }

  String? validateImageUrl(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'La URL de la imagen es obligatoria.';
    if (text.length > 2048) return 'La URL no puede superar 2048 caracteres.';

    final uri = Uri.tryParse(text);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        RegExp(r'\s').hasMatch(text)) {
      return 'Ingrese una URL HTTP o HTTPS válida.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product != null ? 'Editar producto' : 'Nuevo producto',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            children: [
              TextFormField(
                controller: nameController,
                validator: validateName,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ]'),
                  ),
                ],
                textCapitalization: TextCapitalization.sentences,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: priceController,
                validator: validatePrice,
                inputFormatters: [
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    final isValid = RegExp(r'^$|^\d{1,8}([.,]\d{0,2})?$')
                        .hasMatch(newValue.text);
                    return isValid ? newValue : oldValue;
                  }),
                ],
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: stockController,
                validator: validateStock,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Existencias',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: descriptionController,
                validator: validateDescription,
                maxLength: 500,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: imageUrlController,
                validator: validateImageUrl,
                maxLength: 2048,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'URL de la imagen',
                  hintText: 'https://ejemplo.com/producto.png',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Producto activo'),
                subtitle: Text(isActive ? 'Sí' : 'No'),
                value: isActive,
                onChanged: isSaving
                    ? null
                    : (value) => setState(() => isActive = value),
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
                    : Text(widget.product != null ? 'Actualizar' : 'Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
