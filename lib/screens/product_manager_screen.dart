import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/recipe_service.dart';
import '../services/inventory_service.dart';

class ProductManagerScreen extends StatefulWidget {
  @override
  _ProductManagerScreenState createState() => _ProductManagerScreenState();
}

class _ProductManagerScreenState extends State<ProductManagerScreen> {
  final InventoryService _inventoryService = InventoryService.instance;
  List<String> products = [];
  Map<String, Map<String, double>> recipes = {};
  final _newProductController = TextEditingController();
  final _newPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      products = RecipeService.recipes.keys.toList();
      recipes = Map.from(RecipeService.recipes);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Product Manager 👑', style: GoogleFonts.poppins()),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ADD NEW PRODUCT
          _buildAddProductSection(),
          SizedBox(height: 16),
          // PRODUCTS LIST
          Expanded(child: _buildProductsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadProducts,
        child: Icon(Icons.refresh),
        backgroundColor: Colors.amber[600],
      ),
    );
  }

  Widget _buildAddProductSection() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        children: [
          Text('Add New Product',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newProductController,
                  decoration: InputDecoration(
                    labelText: 'Product Name',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: Icon(Icons.add),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _newPriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Price ₱',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _addNewProduct,
            icon: Icon(Icons.add_circle_outline),
            label: Text('ADD PRODUCT'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final productName = products[index];
        final recipe = recipes[productName] ?? {};
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Colors.amber[600],
              child: Icon(Icons.local_cafe, color: Colors.white),
            ),
            title: Text(productName,
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            subtitle: Text('Ingredients: ${recipe.length}',
                style: GoogleFonts.poppins()),
            children: [
              // Recipe Ingredients
              ...recipe.entries
                  .map((entry) => ListTile(
                        dense: true,
                        leading: Icon(Icons.inventory_2, size: 20),
                        title: Text(
                            '${entry.value.toStringAsFixed(1)}g ${entry.key}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, size: 20),
                              onPressed: () => _editIngredient(
                                  productName, entry.key, entry.value),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete,
                                  size: 20, color: Colors.red),
                              onPressed: () =>
                                  _removeIngredient(productName, entry.key),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
              // ADD INGREDIENT BUTTON
              ListTile(
                dense: true,
                leading: Icon(Icons.add, color: Colors.green),
                title: Text('Add Ingredient',
                    style: GoogleFonts.poppins(color: Colors.green)),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _addIngredientToProduct(productName),
              ),
              // DELETE PRODUCT
              ListTile(
                dense: true,
                tileColor: Colors.red[50],
                leading: Icon(Icons.delete_forever, color: Colors.red),
                title: Text('Delete Product',
                    style: GoogleFonts.poppins(color: Colors.red)),
                onTap: () => _deleteProduct(productName),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addNewProduct() {
    final name = _newProductController.text.trim();
    final priceText = _newPriceController.text.trim();

    if (name.isEmpty || priceText.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Enter name & price')));
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Invalid price')));
      return;
    }

    setState(() {
      products.add(name);
      recipes[name] = {};
      RecipeService.recipes[name] = {};
    });

    _newProductController.clear();
    _newPriceController.clear();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('✅ $name added!')));
  }

  void _editIngredient(String product, String ingredient, double quantity) {
    final controller = TextEditingController(text: quantity.toStringAsFixed(1));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $ingredient', style: GoogleFonts.poppins()),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Quantity (g/ml/pc)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newQty = double.tryParse(controller.text);
              if (newQty != null && newQty > 0) {
                setState(() {
                  recipes[product]![ingredient] = newQty;
                  RecipeService.recipes[product]![ingredient] = newQty;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('✅ Updated!')));
              }
            },
            child: Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _addIngredientToProduct(String product) async {
    final inventory = await _inventoryService.getInventory();
    final ingredientNames = inventory.map((i) => i.name).toList();

    String? selectedIngredient;
    double? quantity;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Ingredient to $product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Ingredient'),
              items: ingredientNames
                  .map((name) =>
                      DropdownMenuItem(value: name, child: Text(name)))
                  .toList(),
              onChanged: (value) => selectedIngredient = value,
            ),
            SizedBox(height: 16),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Quantity (g/ml/pc)'),
              onChanged: (value) => quantity = double.tryParse(value),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed:
                selectedIngredient != null && quantity != null && quantity! > 0
                    ? () {
                        setState(() {
                          recipes[product]![selectedIngredient!] = quantity!;
                          RecipeService.recipes[product]![selectedIngredient!] =
                              quantity!;
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('✅ Added ingredient!')));
                      }
                    : null,
            child: Text('ADD'),
          ),
        ],
      ),
    );
  }

  void _removeIngredient(String product, String ingredient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove $ingredient?'),
        content: Text('This will remove $ingredient from $product recipe.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                recipes[product]!.remove(ingredient);
                RecipeService.recipes[product]!.remove(ingredient);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('✅ Removed!')));
            },
            child: Text('REMOVE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteProduct(String product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $product?'),
        content: Text('This will permanently delete $product and its recipe.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                products.remove(product);
                recipes.remove(product);
                RecipeService.recipes.remove(product);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('✅ Deleted $product!')));
            },
            child: Text('DELETE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
