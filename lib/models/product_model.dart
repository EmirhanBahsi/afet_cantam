class Product {
  final String id;
  final String name;
  final String category;
  final int amount;
  final String? expiryDate;

  /* Modele son kullanma tarihini ekledim
  eğer db den çekeceksen orada da eklemelisin yoksa
  null olarak gözükecektir.
   */

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.amount,
    this.expiryDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'amount': amount,
      'expiryDate': expiryDate,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      amount: map['amount'] ?? 0,
      expiryDate: map['expiryDate'],
    );
  }
}