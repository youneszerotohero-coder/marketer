class CartItemModel {
  String id;
  final String brand;
  final String title;
  String variantSku;
  double price;
  double commission;
  final String imageUrl;
  int quantity;
  final List<dynamic>? availableVariants;

  CartItemModel({
    required this.id,
    required this.brand,
    required this.title,
    this.variantSku = '',
    required this.price,
    required this.commission,
    required this.imageUrl,
    this.quantity = 1,
    this.availableVariants,
  });
}
