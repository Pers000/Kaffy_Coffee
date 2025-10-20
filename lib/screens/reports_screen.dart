import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../services/sales_service.dart';
import '../models/sale.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final SalesService _salesService = SalesService.instance;
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  String selectedPeriod = 'Today';
  String selectedChart = 'hourly'; // hourly, daily, products
  Map<String, dynamic> reportData = {};

  @override
  void initState() {
    super.initState();
    _loadTodayReport();
  }

  Future<void> _loadTodayReport() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await _loadReport(today);
  }

  Future<void> _loadPeriodReport(String period) async {
    DateTime now = DateTime.now();
    DateTime startDate;

    switch (period) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'Week':
        final firstDayOfWeek = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(
            firstDayOfWeek.year, firstDayOfWeek.month, firstDayOfWeek.day);
        break;
      case 'Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, now.day);
    }

    await _loadReport(startDate);
    setState(() {
      selectedPeriod = period;
      selectedStartDate = startDate;
    });
  }

  Future<void> _loadReport(DateTime startDate, [DateTime? endDate]) async {
    final end = endDate ?? DateTime.now();
    final summary = await _salesService.getReportSummary(
        startDate: startDate, endDate: end);
    final hourlyTrends =
        await _salesService.getHourlyTrends(startDate: startDate, endDate: end);
    final dailyTrends =
        await _salesService.getDailyTrends(startDate: startDate, endDate: end);
    final productTrends = await _salesService.getProductTrends(
        startDate: startDate, endDate: end);

    setState(() {
      reportData = {
        ...summary,
        'hourlyTrends': hourlyTrends,
        'dailyTrends': dailyTrends,
        'productTrends': productTrends,
        'startDate': startDate,
        'endDate': end,
      };
    });
  }

  Future<void> _selectDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: selectedStartDate ?? DateTime.now().subtract(Duration(days: 7)),
        end: DateTime.now(),
      ),
    );

    if (picked != null) {
      await _loadReport(picked.start, picked.end);
      setState(() {
        selectedStartDate = picked.start;
        selectedEndDate = picked.end;
        selectedPeriod = 'Custom';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Analytics 📈', style: GoogleFonts.poppins()),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: Icon(Icons.picture_as_pdf),
              onPressed: _exportPDF,
              tooltip: 'PDF'),
          IconButton(
              icon: Icon(Icons.table_chart),
              onPressed: _exportCSV,
              tooltip: 'CSV'),
        ],
      ),
      body: Column(
        children: [
          // PERIOD & CHART SELECTOR
          _buildSelectors(),
          SizedBox(height: 16),

          // SUMMARY CARDS
          _buildSummaryCards(),

          // TRENDY CHARTS
          Expanded(child: _buildCharts()),
        ],
      ),
    );
  }

  Widget _buildSelectors() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['Today', 'Week', 'Month', 'Year']
                  .map((period) => ChoiceChip(
                        label: Text(period),
                        selected: selectedPeriod == period,
                        selectedColor: Colors.blue[100],
                        onSelected: (selected) =>
                            selected ? _loadPeriodReport(period) : null,
                      ))
                  .toList(),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['⏰ Hourly', '📅 Daily', '🔥 Products']
                  .map((chart) => ChoiceChip(
                        label: Text(chart),
                        selected: selectedChart ==
                            chart.toLowerCase().replaceAll(' ', ''),
                        selectedColor: Colors.green[100],
                        onSelected: (selected) => setState(() => selectedChart =
                            chart.toLowerCase().replaceAll(' ', '')),
                      ))
                  .toList(),
            ),
            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _selectDateRange,
              icon: Icon(Icons.calendar_today),
              label: Text('Custom Range'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final data = reportData['summary'] ?? {};
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Card(
              color: Colors.green[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.attach_money,
                        color: Colors.green[700], size: 32),
                    Text('₱${data['totalRevenue']?.toStringAsFixed(0) ?? '0'}',
                        style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700])),
                    Text('Revenue', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Card(
              color: Colors.blue[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.shopping_cart,
                        color: Colors.blue[700], size: 32),
                    Text('${data['totalItems'] ?? 0}',
                        style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700])),
                    Text('Items', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Card(
              color: Colors.orange[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.trending_up,
                        color: Colors.orange[700], size: 32),
                    Text('${data['topProduct'] ?? 'None'}',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700])),
                    Text('Top Seller',
                        style: GoogleFonts.poppins(fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharts() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // MAIN TREND CHART
            Container(
              height: 300,
              padding: EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedChart == 'hourly'
                            ? '⏰ Hourly Sales Trends'
                            : selectedChart == 'daily'
                                ? '📅 Weekly Day Trends'
                                : '🔥 Product Popularity by Hour',
                        style: GoogleFonts.poppins(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      Expanded(child: _buildMainChart()),
                    ],
                  ),
                ),
              ),
            ),

            // RECENT SALES LIST
            SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: Icon(Icons.list, color: Colors.blue),
                title: Text('Recent Sales',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                subtitle: Text('Tap for full list'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () => _showSalesList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainChart() {
    final data = reportData;

    switch (selectedChart) {
      case 'hourly':
        final hourly = data['hourlyTrends'] as Map<String, dynamic>? ?? {};
        return _buildBarChart(
          hourly['hours']?.cast<int>() ?? [],
          hourly['sales']?.cast<int>() ?? [],
          'Hour of Day',
          ['12AM', '3AM', '6AM', '9AM', '12PM', '3PM', '6PM', '9PM'],
        );

      case 'daily':
        final daily = data['dailyTrends'] as Map<String, dynamic>? ?? {};
        return _buildBarChart(
          List.generate(7, (i) => i),
          daily['sales']?.cast<int>() ?? [],
          'Day of Week',
          ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        );

      case 'products':
        final productData =
            data['productTrends'] as Map<String, dynamic>? ?? {};
        return _buildProductLineChart(productData);

      default:
        return Center(child: Text('Select a chart type'));
    }
  }

  Widget _buildBarChart(List<int> labels, List<int> values, String title,
      List<String>? customLabels) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: values.isNotEmpty
            ? values.reduce((a, b) => a > b ? a : b) * 1.2
            : 10,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          // FIXED: Changed from titleData to titlesData
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < customLabels!.length) {
                  return Text(customLabels[index % customLabels.length],
                      style: TextStyle(fontSize: 10));
                }
                return Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: true),
        barGroups: List.generate(labels.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: values[index].toDouble(),
                color: Colors.blue,
                width: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildProductLineChart(Map<String, dynamic> productData) {
    final hours = productData['hours'] as List<int>? ?? [];
    final products = productData['products'] as Map<String, List<int>>? ?? {};

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          // FIXED: Changed from titleData to titlesData
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < 24 && index % 3 == 0) {
                  return Text('$index', style: TextStyle(fontSize: 10));
                }
                return Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: products.entries.map((entry) {
          return LineChartBarData(
            spots: List.generate(hours.length,
                (i) => FlSpot(i.toDouble(), entry.value[i].toDouble())),
            isCurved: true,
            color: _getProductColor(entry.key),
            barWidth: 2,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          );
        }).toList(),
      ),
    );
  }

  Color _getProductColor(String product) {
    final colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
    ];
    return colors[product.hashCode % colors.length];
  }

  void _showSalesList() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Recent Sales', style: GoogleFonts.poppins()),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: (reportData['sales'] as List?)?.length.clamp(0, 20) ?? 0,
            itemBuilder: (context, index) {
              // FIXED: Added index parameter
              final sale = (reportData['sales'] as List)[index] as Sale;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.amber[100],
                  child: Text(sale.quantity.toString()),
                ),
                title: Text(sale.productName),
                subtitle: Text(
                    '${sale.date.toLocal().toString().split(' ')[0]} ${sale.date.hour}:${sale.date.minute.toString().padLeft(2, '0')}'),
                trailing: Text('₱${sale.totalPrice.toStringAsFixed(2)}'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('Close')),
        ],
      ),
    );
  }

  Future<void> _exportPDF() async {
    // FIXED: Added missing method
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Header(
                level: 0,
                child: pw.Text('Kaffy Coffee Report',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(height: 20),
            pw.Text('Period: $selectedPeriod',
                style: pw.TextStyle(fontSize: 16)),
            if (selectedStartDate != null && selectedEndDate != null)
              pw.Text(
                  '${selectedStartDate!.toLocal()} - ${selectedEndDate!.toLocal()}'),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(color: PdfColors.amber100),
              child: pw.Column(
                children: [
                  pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                            'Total Revenue: ₱${reportData['totalRevenue']?.toStringAsFixed(2) ?? '0'}'),
                        pw.Text('Items Sold: ${reportData['totalItems'] ?? 0}'),
                      ]),
                  pw.Text('Top Product: ${reportData['topProduct'] ?? 'None'}'),
                  pw.Text('Products: ${reportData['totalProducts'] ?? 0}'),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Sales Details:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Table.fromTextArray(
              headers: ['Product', 'Qty', 'Price', 'Date'],
              data: (reportData['sales'] as List<Sale>?)
                      ?.map((sale) => [
                            sale.productName,
                            sale.quantity.toString(),
                            '₱${sale.totalPrice.toStringAsFixed(2)}',
                            sale.date.toLocal().toString().split(' ')[0],
                          ])
                      ?.toList() ??
                  [],
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _exportCSV() async {
    // FIXED: Added missing method
    final sales = reportData['sales'] as List<Sale>? ?? [];
    List<List<dynamic>> csvData = [
      ['Product', 'Quantity', 'Total Price', 'Date', 'Cashier'],
      ...sales.map((sale) => [
            sale.productName,
            sale.quantity,
            sale.totalPrice,
            sale.date.toLocal().toString().split(' ')[0],
            sale.cashierRole,
          ]),
    ];

    String csv = const ListToCsvConverter().convert(csvData);
    final directory = await Directory.systemTemp.createTemp();
    final path =
        '${directory.path}/kaffy_report_${DateTime.now().millisecondsSinceEpoch}.csv';

    final file = File(path);
    await file.writeAsString(csv);

    Share.shareXFiles([XFile(path)], text: 'Kaffy Coffee Report');
  }
}
