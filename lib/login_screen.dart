import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';

  Future<void> _login() async {
    if (_usernameController.text == 'admin' && _passwordController.text == '1234') {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen()),
      );
    } else {
      setState(() {
        _errorMessage = 'Invalid username or password';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF15171E),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.water_drop, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 20),
            const Text('Water Meter IoT', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            TextField(
              controller: _usernameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Username', labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Password', labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
              ),
            ),
            const SizedBox(height: 10),
            Text(_errorMessage, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                child: const Text('LOGIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}