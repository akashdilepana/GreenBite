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

  final List<Widget> pages = const [
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.kitchen),
            label: "Fridge",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: "Bill Scan",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: "Recipes",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Nutrition",
          ),
        ],
      ),
    );
  }
}