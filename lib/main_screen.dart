import 'package:flutter/material.dart';

import 'home_page.dart';
import 'inventory_page.dart';
import 'scanner_page.dart';
import 'recipe_page.dart';
import 'nutrition_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;

  final pages = const [
    HomePage(),
    InventoryPage(),
    ScannerPage(),
    RecipePage(),
    NutritionPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF2E7D32),
          unselectedItemColor: Colors.grey,
          elevation: 0,
          onTap: (index) {
            setState(() {
              selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.kitchen), label: "Fridge"),
            BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long), label: "Bill Scan"),
            BottomNavigationBarItem(
                icon: Icon(Icons.restaurant), label: "Recipes"),
            BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart), label: "Nutrition"),
          ],
        ),
      ),
    );
  }
}