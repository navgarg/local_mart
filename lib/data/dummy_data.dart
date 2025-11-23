class Product {
  final String id;
  final String name;
  final String image;
  final double price;
  final String category;

  Product({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.category,
  });
}

final List<Product> dummyProducts = [
  Product(
    id: 'p1',
    name: 'Tomato',
    image: 'https://via.placeholder.com/150',
    price: 50,
    category: 'Groceries',
  ),
  Product(
    id: 'p2',
    name: 'Speakers',
    image: 'https://via.placeholder.com/150',
    price: 4560,
    category: 'Electronics',
  ),
  Product(
    id: 'p3',
    name: 'Carrot',
    image: 'https://via.placeholder.com/150',
    price: 40,
    category: 'Groceries',
  ),
  Product(
    id: 'p4',
    name: 'Sofa',
    image: 'https://via.placeholder.com/150',
    price: 1500,
    category: 'Home Goods',
  ),
  Product(
    id: 'p5',
    name: 'Charger',
    image: 'https://via.placeholder.com/150',
    price: 500,
    category: 'Electronics',
  ),
];