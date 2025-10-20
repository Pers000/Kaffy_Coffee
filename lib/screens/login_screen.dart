import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: Duration(milliseconds: 1200), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final userRole = await _authService.login(
            _usernameController.text.trim(), _passwordController.text);
        if (userRole != null) {
          Navigator.pushReplacementNamed(context, '/dashboard',
              arguments: userRole);
        } else {
          _showSnackBar('❌ Invalid credentials', Colors.red);
        }
      } catch (e) {
        _showSnackBar('❌ Login failed', Colors.red);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF8B4513),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              children: [
                _buildHeader(),
                SizedBox(height: 48),
                _buildLoginForm(),
                SizedBox(height: 24),
                _buildLoginButton(),
                SizedBox(height: 16),
                _buildDemoInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.local_cafe, size: 60, color: Colors.amber[800]),
        ),
        SizedBox(height: 16),
        Text(
          'Kaffy Coffee',
          style: GoogleFonts.poppins(
              fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        Text('Smart POS & Inventory',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70)),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)
            ],
          ),
          child: TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Username',
              prefixIcon: Icon(Icons.person_outline, color: Colors.amber[800]),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
              filled: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'Please enter username';
              return null;
            },
          ),
        ),
        SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)
            ],
          ),
          child: TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline, color: Colors.amber[800]),
              suffixIcon: IconButton(
                icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.amber[800]),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
              filled: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            validator: (String? value) {
              if (value == null || value.isEmpty)
                return 'Please enter password';
              if (value.length < 4)
                return 'Password must be at least 4 characters';
              return null;
            },
            onFieldSubmitted: (_) => _login(),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient:
            LinearGradient(colors: [Colors.amber[600]!, Colors.amber[800]!]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 20)
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isLoading ? null : _login,
          child: Center(
            child: _isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : Text('LOGIN ☕',
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text('Demo:',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
          Text('admin/admin123\ncashier/1234',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 11),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
