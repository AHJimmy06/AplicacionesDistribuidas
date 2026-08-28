class Products {
  final int id;
  final String name;
  final double price;
  final int stock;
  final String description;
  final String imageUrl;
  final bool isActive;
  final int version;

  Products({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.description,
    required this.imageUrl,
    this.isActive = true,
    this.version = 0,
  });

  factory Products.fromJson(Map<String, dynamic> json) {
    return Products(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      version: (json['version'] as num?)?.toInt() ?? 0,
    );
  }

  Products copyWith({bool? isActive}) {
    return Products(
      id: id,
      name: name,
      price: price,
      stock: stock,
      description: description,
      imageUrl: imageUrl,
      isActive: isActive ?? this.isActive,
      version: version,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'stock': stock,
      'description': description,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'version': version,
    };
  }
}
