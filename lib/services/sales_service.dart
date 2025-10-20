import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/sale.dart';

class SalesService {
  static Database? _database;
  static SalesService? _instance;

  SalesService._privateConstructor();
  static SalesService get instance =>
      _instance ??= SalesService._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kaffy_sales.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        total_price REAL NOT NULL,
        date TEXT NOT NULL,
        cashier_role TEXT NOT NULL
      )
    ''');
  }

  Future<void> saveSale(Sale sale) async {
    final db = await database;
    await db.insert('sales', sale.toMap());
  }

  Future<List<Sale>> getSales({DateTime? startDate, DateTime? endDate}) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClause += 'date >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      if (startDate != null) whereClause += ' AND ';
      whereClause += 'date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final maps = await db.query('sales',
        where: whereClause.isNotEmpty ? whereClause : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'date DESC');
    return List.generate(maps.length, (i) => Sale.fromMap(maps[i]));
  }

  Future<Map<String, dynamic>> getReportSummary(
      {DateTime? startDate, DateTime? endDate}) async {
    final sales = await getSales(startDate: startDate, endDate: endDate);
    if (sales.isEmpty)
      return {
        'totalRevenue': 0.0,
        'totalItems': 0,
        'topProduct': 'None',
        'totalProducts': 0
      };

    final totalRevenue = sales.fold(0.0, (sum, sale) => sum + sale.totalPrice);
    final totalItems = sales.fold(0, (sum, sale) => sum + sale.quantity);
    final productCounts = <String, int>{};
    for (var sale in sales) {
      productCounts[sale.productName] =
          (productCounts[sale.productName] ?? 0) + sale.quantity;
    }
    final topProduct = productCounts.isNotEmpty
        ? productCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 'None';

    return {
      'totalRevenue': totalRevenue,
      'totalItems': totalItems,
      'topProduct': topProduct,
      'totalProducts': productCounts.length,
      'sales': sales,
      'productCounts': productCounts,
    };
  }

  Future<Map<String, dynamic>> getHourlyTrends(
      {DateTime? startDate, DateTime? endDate}) async {
    final sales = await getSales(startDate: startDate, endDate: endDate);
    Map<int, int> hourlyCounts = {};
    for (var i = 0; i < 24; i++) {
      hourlyCounts[i] = 0;
    }

    for (var sale in sales) {
      final hour = sale.date.hour;
      hourlyCounts[hour] = (hourlyCounts[hour] ?? 0) + sale.quantity;
    }

    return {
      'hours': List.generate(24, (i) => i),
      'sales': hourlyCounts.values.toList(),
    };
  }

  Future<Map<String, dynamic>> getDailyTrends(
      {DateTime? startDate, DateTime? endDate}) async {
    final sales = await getSales(startDate: startDate, endDate: endDate);
    Map<int, int> dailyCounts = {};
    for (var i = 1; i <= 7; i++) {
      dailyCounts[i] = 0;
    }

    for (var sale in sales) {
      final day = sale.date.weekday;
      dailyCounts[day] = (dailyCounts[day] ?? 0) + sale.quantity;
    }

    return {
      'days': List.generate(7, (i) => i + 1),
      'sales': dailyCounts.values.toList(),
    };
  }

  Future<Map<String, dynamic>> getProductTrends(
      {DateTime? startDate, DateTime? endDate}) async {
    final sales = await getSales(startDate: startDate, endDate: endDate);
    Map<String, List<int>> productHourly = {};
    Map<String, int> productTotal = {};

    for (var sale in sales) {
      if (productHourly[sale.productName] == null) {
        productHourly[sale.productName] = List.filled(24, 0);
      }
      productHourly[sale.productName]![sale.date.hour] += sale.quantity;
      productTotal[sale.productName] =
          (productTotal[sale.productName] ?? 0) + sale.quantity;
    }

    // Sort by total sales
    final sortedProducts = productTotal.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topProducts =
        sortedProducts.take(5).map((e) => e.key).toList(); // Top 5 products

    return {
      'hours': List.generate(24, (i) => i),
      'products': {
        for (var product in topProducts) product: productHourly[product]
      },
      'days': List.generate(7, (i) => i + 1),
      'productDaily': _getProductDaily(sales),
    };
  }

  Map<String, List<int>> _getProductDaily(List<Sale> sales) {
    Map<String, List<int>> productDaily = {};
    for (var sale in sales) {
      if (productDaily[sale.productName] == null) {
        productDaily[sale.productName] = List.filled(7, 0);
      }
      final day = sale.date.weekday - 1; // 0=Mon, 6=Sun
      productDaily[sale.productName]![day] += sale.quantity;
    }
    return productDaily;
  }
}
