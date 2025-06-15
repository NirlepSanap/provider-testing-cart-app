import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';
import 'firebase_options.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(create: (_) => CartProvider(), child: const MyApp()),
  );
}

// -------------------- MODELS --------------------

class Product {
  final String id;
  final String title;
  final double price;
  final String imageUrl;

  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.imageUrl,
  });

  factory Product.fromMap(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      title: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? "https://imgs.search.brave.com/ryLjSMzLbf9Wp4DFVe7ypYSTNs64GqPN3W6BNPwzn6c/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly9tZWRp/YS5pc3RvY2twaG90/by5jb20vaWQvMTMy/MDI5NTUyNy9waG90/by93b21hbi1zbmVh/a2VyLW9uLWEtbGln/aHQtZ3JheS1ncmFk/aWVudC1iYWNrZ3Jv/dW5kLXdvbWFucy1m/YXNoaW9uLXNwb3J0/LXNob2Utc25lYWtl/cnMtY29uY2VwdC5q/cGc_cz02MTJ4NjEy/Jnc9MCZrPTIwJmM9/UlA1SkxxNHV2a1dn/MTd3eE9oSlRkdTFF/WTJlWGcwZGZlOE9h/dHlWLTQwYz0",
    );
  }
}

// -------------------- PROVIDER --------------------

class CartProvider with ChangeNotifier {
  final List<Product> _items = [];

  List<Product> get items => _items;

  double get totalPrice => _items.fold(0, (sum, item) => sum + item.price);

  int get count => _items.length;

  void addToCart(Product product) {
    _items.add(product);
    notifyListeners();
  }

  void removeFromCart(Product product) {
    _items.remove(product);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}

// -------------------- MAIN APP --------------------

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shopping App',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return const ProductListScreen();
          }
          return const AuthPage();
        },
      ),
    );
  }
}

// -------------------- FIREBASE UTILS --------------------

final FirebaseAuth _auth = FirebaseAuth.instance;
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

Future<List<Product>> fetchProducts() async {
  final snapshot = await _firestore.collection('products').get();
  return snapshot.docs
      .map((doc) => Product.fromMap(doc.data(), doc.id))
      .toList();
}

// -------------------- PRODUCT LIST SCREEN --------------------

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const CartScreen()));
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.red,
                  child: Consumer<CartProvider>(
                    builder: (_, cart, __) => Text(
                      cart.count.toString(),
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<Product>>(
        future: fetchProducts(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: \${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No products found.'));
          }

          final products = snapshot.data!;
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (ctx, i) => ProductItem(product: products[i]),
          );
        },
      ),
    );
  }
}

// -------------------- PRODUCT ITEM WIDGET --------------------

class ProductItem extends StatelessWidget {
  final Product product;
  const ProductItem({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: ListTile(
        leading: Image.network(product.imageUrl, width: 50, fit: BoxFit.cover),
        title: Text(product.title),
        subtitle: Text('Best selling item'),
        trailing: IconButton(
          icon: const Icon(Icons.add_shopping_cart),
          onPressed: () {
            cart.addToCart(product);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('\${product.title} added to cart')),
            );
          },
        ),
      ),
    );
  }
}

// -------------------- CART SCREEN --------------------

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: Column(
        children: [
          Expanded(
            child: cart.items.isEmpty
                ? const Center(child: Text("Cart is Empty"))
                : ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (ctx, i) {
                      final item = cart.items[i];
                      return ListTile(
                        title: Text(item.title),
                        trailing: Text('₹\${item.price.toStringAsFixed(2)}'),
                        leading: IconButton(
                          icon: const Icon(Icons.remove_circle),
                          onPressed: () {
                            cart.removeFromCart(item);
                          },
                        ),
                      );
                    },
                  ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Total'),
            trailing: Text(
              '₹\${cart.totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: cart.clearCart,
              child: const Text('Clear Cart'),
            ),
          ),
        ],
      ),
    );
  }
}
