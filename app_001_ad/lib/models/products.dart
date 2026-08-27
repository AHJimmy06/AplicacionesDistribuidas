class Products {
  final int id;
  final String name;
  final double price;
  final int stock;
  final int version;

  Products({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.version = 0,
  });

  factory Products.fromJson(Map<String, dynamic> json) {
    return Products(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      version: (json['version'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'stock': stock,
      'version': version,
    };
  }
}
