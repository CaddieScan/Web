import 'package:flutter/material.dart';

import '../services/store_service.dart';
import '../services/product_service.dart';
import 'home_page.dart';

class LoginPage extends StatelessWidget {
  final StoreService storeService;
  final ProductService productService;

  const LoginPage({
    super.key,
    required this.storeService,
    required this.productService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.teal.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'images/img.png',
                      fit: BoxFit.cover,
                    ),
                ),
              ),
              const SizedBox(height: 40),
              _inputField(icon: Icons.person, hint: 'Username'),
              const SizedBox(height: 15),
              _inputField(icon: Icons.lock, hint: 'Password', obscure: true),
              const SizedBox(height: 30),
              SizedBox(
                width: 220,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HomePage(
                          storeService: storeService,
                          productService: productService,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Connexion', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required IconData icon,
    required String hint,
    bool obscure = false,
  }) {
    return SizedBox(
      width: 280,
      child: TextField(
        obscureText: obscure,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          hintText: hint,
          filled: true,
          fillColor: Colors.grey.shade200,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
