class Product {
  String id;
  String name;
  int amount;
  String category;
  String? expireDate; // Başlangıçta boş olabilir

  Product({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    this.expireDate,
  });

  // Firestore'dan gelen veriyi modele çevirmek için
  factory Product.fromMap(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      name: data['name'] ?? '',
      amount: data['amount'] ?? 0,
      category: data['category'] ?? 'Genel',
      expireDate: data['expireDate'],
    );
  }

  // Modeli Firestore'a göndermek için
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
      'category': category,
      'expireDate': expireDate,
    };
  }
}