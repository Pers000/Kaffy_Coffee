import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'billing_screen.dart';
import 'inventory_screen.dart';
import 'product_manager_screen.dart';
import 'reports_screen.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String? userRole =
        ModalRoute.of(context)?.settings.arguments as String?;

    return Scaffold(
      backgroundColor: Color(0xFFFFF8E1),
      appBar: AppBar(
        title: Text('Kaffy Dashboard', style: GoogleFonts.poppins()),
        backgroundColor: Colors.amber[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_cafe, size: 100, color: Colors.amber[800]),
            SizedBox(height: 32),
            Text(
              'Welcome to Kaffy Coffee!',
              style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.amber[800]),
            ),
            SizedBox(height: 8),
            Text('Role: $userRole',
                style:
                    GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600])),
            SizedBox(height: 48),
            // START BILLING
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            BillingScreen(userRole: userRole ?? 'cashier'))),
                icon: Icon(Icons.add_shopping_cart),
                label: Text('START BILLING ☕',
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[600],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 8),
              ),
            ),
            if (userRole == 'admin') ...[
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => InventoryScreen())),
                  icon: Icon(Icons.inventory_2),
                  label: Text('INVENTORY 📦', style: GoogleFonts.poppins()),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 8),
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ProductManagerScreen())),
                  icon: Icon(Icons.edit),
                  label:
                      Text('PRODUCT MANAGER 👑', style: GoogleFonts.poppins()),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 8),
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (context) => ReportsScreen())),
                  icon: Icon(Icons.analytics),
                  label: Text('REPORTS 📊', style: GoogleFonts.poppins()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
