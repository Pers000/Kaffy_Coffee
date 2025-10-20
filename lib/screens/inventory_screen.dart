import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/inventory_service.dart';
import '../models/ingredient.dart';

class InventoryScreen extends StatefulWidget {
  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final InventoryService _inventoryService = InventoryService.instance;
  final _nameController = TextEditingController();
  final _unitController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();
  List<Ingredient> inventory = [];

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    final items = await _inventoryService.getInventory();
    setState(() => inventory = items);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Inventory 📦', style: GoogleFonts.poppins()),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: inventory.length,
              itemBuilder: (context, index) {
                final item = inventory[index];
                return Dismissible(
                  key: Key(item.id.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) => _deleteItem(item),
                  confirmDismiss: (direction) => showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Delete ${item.name}?'),
                      content: Text('This cannot be undone.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Cancel')),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('Delete',
                                style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  ),
                  child: Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    color: item.isLowStock ? Colors.red[50] : Colors.white,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            item.isLowStock ? Colors.red : Colors.green,
                        child: Text(
                            '${((item.quantity / 5000) * 100).toInt()}%',
                            style: TextStyle(color: Colors.white)),
                      ),
                      title: Text(item.name,
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${item.quantity.toStringAsFixed(0)} ${item.unit}'),
                          Text(
                              'Price/Unit: ₱${item.pricePerUnit.toStringAsFixed(2)}'),
                          Text(
                              'Total Cost: ₱${item.totalCost.toStringAsFixed(2)}'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editItem(item),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          _buildAddStockButton(),
        ],
      ),
    );
  }

  Widget _buildAddStockButton() {
    return Container(
      padding: EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: _showAddDialog,
        icon: Icon(Icons.add),
        label: Text('Add New Stock', style: GoogleFonts.poppins(fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          minimumSize: Size(double.infinity, 56),
        ),
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Ingredient', style: GoogleFonts.poppins()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name')),
              TextField(
                  controller: _unitController,
                  decoration: InputDecoration(labelText: 'Unit (g/ml/pc)')),
              TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Quantity')),
              TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Price per Unit')),
              TextField(
                  controller: _categoryController,
                  decoration: InputDecoration(labelText: 'Category')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: _addItem,
            child: Text('ADD'),
          ),
        ],
      ),
    );
  }

  Future<void> _addItem() async {
    final name = _nameController.text.trim();
    final unit = _unitController.text.trim();
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    final category = _categoryController.text.trim();

    if (name.isEmpty ||
        unit.isEmpty ||
        quantity <= 0 ||
        price <= 0 ||
        category.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please fill all fields')));
      return;
    }

    final ingredient = Ingredient(
      name: name,
      unit: unit,
      quantity: quantity,
      pricePerUnit: price,
      category: category,
    );

    await _inventoryService.addIngredient(ingredient);
    Navigator.pop(context);
    _clearControllers();
    _loadInventory();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('✅ Added $name!')));
  }

  void _editItem(Ingredient item) {
    _quantityController.text = item.quantity.toString();
    _priceController.text = item.pricePerUnit.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${item.name}', style: GoogleFonts.poppins()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Quantity')),
            TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Price per Unit')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () => _saveEdit(item),
            child: Text('SAVE'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveEdit(Ingredient item) async {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;

    if (quantity <= 0 || price <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Invalid values')));
      return;
    }

    await _inventoryService.updateIngredient(item.id!, quantity, price);
    Navigator.pop(context);
    _clearControllers();
    _loadInventory();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('✅ Updated ${item.name}!')));
  }

  Future<void> _deleteItem(Ingredient item) async {
    await _inventoryService.deleteIngredient(item.id!);
    _loadInventory();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('🗑️ Deleted ${item.name}!')));
  }

  void _clearControllers() {
    _nameController.clear();
    _unitController.clear();
    _quantityController.clear();
    _priceController.clear();
    _categoryController.clear();
  }
}
