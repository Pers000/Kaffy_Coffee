import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../models/sale.dart'; // FIXED: Added for Sale class
import '../services/inventory_service.dart';
import '../services/recipe_service.dart';
import '../services/sales_service.dart'; // FIXED: Added for SalesService

class BillingScreen extends StatefulWidget {
  final String userRole;
  const BillingScreen({Key? key, required this.userRole}) : super(key: key);

  @override
  _BillingScreenState createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final InventoryService _inventoryService = InventoryService.instance;
  List<Product> products = RecipeService.recipes.keys
      .map((name) =>
          Product(name: name, price: _getPrice(name), category: 'Coffee'))
      .toList();
  List<CartItem> cart = [];
  double total = 0.0;

  static double _getPrice(String name) {
    // FIXED: Defined _getPrice
    const prices = {
      'Espresso': 45.0,
      'Cappuccino': 65.0,
      'Latte': 75.0,
      'Americano': 55.0,
      'Croissant': 35.0,
      // Add more prices for new products as needed
    };
    return prices[name] ?? 50.0; // Default price
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8E1),
      appBar: AppBar(
        title: Text('Kaffy Quick Bill', style: GoogleFonts.poppins()),
        backgroundColor: Colors.amber[600],
        foregroundColor: Colors.white,
        actions: [
          Container(
            padding: EdgeInsets.all(8),
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20)),
            child: Text('Items: ${cart.length}',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTotalBar(),
          Expanded(child: _buildCartList()),
          _buildProductGrid(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: total > 0 ? _generateInvoice : null,
        backgroundColor: Colors.green,
        icon: Icon(Icons.receipt_long),
        label: Text('INVOICE ₱${total.toStringAsFixed(0)}',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTotalBar() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.amber[600],
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total',
                  style:
                      GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
              Text('₱${total.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          FutureBuilder<int>(
            future: _getLowStockCount(),
            builder: (context, snapshot) {
              final lowStock = snapshot.data ?? 0;
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: lowStock > 0 ? Colors.red : Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inventory_2, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      lowStock > 0 ? 'LOW STOCK!' : 'OK',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<int> _getLowStockCount() async {
    final inventory = await _inventoryService.getInventory();
    return inventory.where((i) => i.quantity < 100).length;
  }

  Widget _buildCartList() {
    return cart.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_shopping_cart, size: 64, color: Colors.grey),
                Text('Add coffee items ☕',
                    style: GoogleFonts.poppins(fontSize: 18)),
              ],
            ),
          )
        : ListView.builder(
            itemCount: cart.length,
            itemBuilder: (context, index) {
              final item = cart[index];
              final itemTotal = item.product.price * item.quantity;
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.amber[600],
                    child: Text('${item.quantity}',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(item.product.name,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  subtitle:
                      Text('₱${item.product.price.toStringAsFixed(2)} each'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline,
                            color: Colors.red),
                        onPressed: () => _removeFromCart(item),
                      ),
                      Text('₱${itemTotal.toStringAsFixed(2)}',
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget _buildProductGrid() {
    return Container(
      height: 240,
      child: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return FutureBuilder<bool>(
            future: _canMakeProduct(product.name),
            builder: (context, snapshot) {
              final canMake = snapshot.data ?? true;
              return GestureDetector(
                onTap: canMake ? () => _addToCart(product) : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: canMake ? Colors.white : Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 8)
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_cafe,
                          size: 48,
                          color: canMake ? Colors.amber[700] : Colors.grey),
                      SizedBox(height: 12),
                      Text(product.name,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600, fontSize: 14),
                          textAlign: TextAlign.center),
                      SizedBox(height: 4),
                      Text('₱${product.price.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: canMake ? Colors.amber[700] : Colors.grey,
                              fontWeight: FontWeight.bold)),
                      if (!canMake) ...[
                        SizedBox(height: 4),
                        Text('OUT OF STOCK',
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.red,
                                fontWeight: FontWeight.bold)),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<bool> _canMakeProduct(String productName) async {
    try {
      final usage = RecipeService.getIngredientsForProduct(productName, 1);
      return await _inventoryService.checkStock(usage);
    } catch (e) {
      return false;
    }
  }

  void _addToCart(Product product) async {
    try {
      final usage = RecipeService.getIngredientsForProduct(product.name, 1);
      final hasStock = await _inventoryService.checkStock(usage);

      if (hasStock) {
        await _inventoryService.deductIngredients(usage);
        setState(() {
          final existing = cart.firstWhere(
            (item) => item.product.name == product.name,
            orElse: () => CartItem(product: product, quantity: 0),
          );
          if (existing.quantity > 0) {
            existing.quantity++;
          } else {
            cart.add(CartItem(product: product, quantity: 1));
          }
          _calculateTotal();
        });
        _showSnackBar('✅ Added ${product.name}! ☕');
      } else {
        _showSnackBar('❌ Not enough ingredients!', Colors.red);
      }
    } catch (e) {
      _showSnackBar('❌ Error adding item', Colors.red);
    }
  }

  void _removeFromCart(CartItem item) async {
    try {
      final usage = RecipeService.getIngredientsForProduct(
          item.product.name, -1); // Add back to stock
      await _inventoryService.deductIngredients(usage);

      setState(() {
        if (item.quantity > 1) {
          item.quantity--;
        } else {
          cart.remove(item);
        }
        _calculateTotal();
      });
    } catch (e) {
      _showSnackBar('Error removing item', Colors.red);
    }
  }

  void _calculateTotal() {
    total = cart.fold(
        0.0, (sum, item) => sum + (item.product.price * item.quantity));
  }

  void _showSnackBar(String message, [Color? color]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color ?? Colors.green),
    );
  }

  Future<void> _generateInvoice() async {
    if (cart.isEmpty) return;

    // ✅ SAVE EACH SALE TO DATABASE
    for (var item in cart) {
      final sale = Sale(
        productName: item.product.name,
        quantity: item.quantity,
        totalPrice: item.product.price * item.quantity,
        date: DateTime.now(),
        cashierRole: widget.userRole,
      );
      await SalesService.instance.saveSale(sale);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order Complete! ☕', style: GoogleFonts.poppins()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('✅ Saved to sales report!',
                style: GoogleFonts.poppins(color: Colors.green)),
            Text('Total: ₱${total.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => cart.clear());
              _calculateTotal();
            },
            child: Text('CLEAR'),
          ),
        ],
      ),
    );
  }
}

class CartItem {
  Product product;
  int quantity;
  CartItem({required this.product, required this.quantity});
}
