import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/ingredient.dart';

class InventoryService {
  static Database? _database;
  static InventoryService? _instance;

  InventoryService._privateConstructor();
  static InventoryService get instance {
    _instance ??= InventoryService._privateConstructor();
    return _instance!;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kaffy_inventory.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ingredients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        unit TEXT NOT NULL,
        quantity REAL NOT NULL,
        pricePerUnit REAL NOT NULL,
        category TEXT NOT NULL
      )
    ''');

    await _seedInventory(db);
  }

  Future _seedInventory(Database db) async {
    List<Map<String, dynamic>> initialStock = [
      {
        'name': 'Coffee Beans',
        'unit': 'g',
        'quantity': 5000.0,
        'pricePerUnit': 0.15,
        'category': 'Coffee'
      },
      {
        'name': 'Whole Milk',
        'unit': 'ml',
        'quantity': 20000.0,
        'pricePerUnit': 0.04,
        'category': 'Milk'
      },
      {
        'name': 'Sugar',
        'unit': 'g',
        'quantity': 3000.0,
        'pricePerUnit': 0.02,
        'category': 'Sweetener'
      },
      {
        'name': 'Paper Cups',
        'unit': 'pc',
        'quantity': 1000.0,
        'pricePerUnit': 1.5,
        'category': 'Packaging'
      },
      {
        'name': 'Croissant',
        'unit': 'pc',
        'quantity': 50.0,
        'pricePerUnit': 15.0,
        'category': 'Pastry'
      },
    ];

    for (var item in initialStock) {
      await db.insert('ingredients', item);
    }
  }

  Future<List<Ingredient>> getInventory() async {
    final db = await database;
    final maps = await db.query('ingredients', orderBy: 'category, name');
    return List.generate(maps.length, (i) => Ingredient.fromMap(maps[i]));
  }

  Future<bool> checkStock(Map<String, double> usage) async {
    final inventory = await getInventory();

    for (var entry in usage.entries) {
      final ingredientName = entry.key;
      final requiredQty = entry.value;

      final ingredient = inventory.firstWhere(
        (ing) => ing.name.toLowerCase() == ingredientName.toLowerCase(),
        orElse: () => Ingredient(
            name: '', unit: '', quantity: 0, pricePerUnit: 0, category: ''),
      );

      if (ingredient.quantity < requiredQty) {
        return false;
      }
    }
    return true;
  }

  Future<void> deductIngredients(Map<String, double> usage) async {
    final db = await database;

    for (var entry in usage.entries) {
      final ingredientName = entry.key;
      final deductQty = entry.value;

      await db.rawUpdate(
        'UPDATE ingredients SET quantity = quantity - ? WHERE name = ?',
        [deductQty, ingredientName],
      );
    }
  }

  Future<int> addIngredient(Ingredient ingredient) async {
    final db = await database;
    return await db.insert('ingredients', ingredient.toMap());
  }

  Future<void> updateIngredient(
      int id, double quantity, double pricePerUnit) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE ingredients SET quantity = ?, pricePerUnit = ? WHERE id = ?',
      [quantity, pricePerUnit, id],
    );
  }

  Future<void> deleteIngredient(int id) async {
    final db = await database;
    await db.delete('ingredients', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> restock(
      String name, double quantity, double pricePerUnit) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE ingredients SET quantity = quantity + ?, pricePerUnit = ? WHERE name = ?',
      [quantity, pricePerUnit, name],
    );
  }
}
