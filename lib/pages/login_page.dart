import 'package:flutter/material.dart';
import '../services/store_service.dart';
import '../services/product_service.dart';
import '../services/store_map_service.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  final StoreService storeService;
  final ProductService productService;
  final StoreMapService storeMapService;

  const LoginPage({
    super.key,
    required this.storeService,
    required this.productService,
    required this.storeMapService,
  });

  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset('images/img.png', width: 140, height: 140, fit: BoxFit.cover),
            ),
            const SizedBox(height: 40),
            const SizedBox(width: 280, child: TextField(decoration: InputDecoration(hintText: 'Username'))),
            const SizedBox(height: 15),
            const SizedBox(width: 280, child: TextField(obscureText: true, decoration: InputDecoration(hintText: 'Password'))),
            const SizedBox(height: 30),
            loading
                ? const CircularProgressIndicator()
                : FilledButton(
              onPressed: () async {
                setState(() => loading = true);
                await Future.delayed(const Duration(seconds: 2));
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomePage(
                        storeService: widget.storeService,
                        productService: widget.productService,
                        storeMapService: widget.storeMapService,
                      ),
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(220, 50),
                shape: const StadiumBorder(),
              ),
              child: const Text('Connexion', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}