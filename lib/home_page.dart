import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

import 'scanner_page.dart';
import 'inventory_page.dart';
import 'recipe_page.dart';
import 'nutrition_page.dart';
import 'profile_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _goToPage(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  CollectionReference<Map<String, dynamic>> _itemsRef(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('items');
  }

  DocumentReference<Map<String, dynamic>> _userRef(String uid) {
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please login first")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6FFF2),
      appBar: AppBar(
        title: const Text(
          "GreenBite",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              backgroundColor: Color(0xFFDFF5D8),
              child: Icon(Icons.person, color: Color(0xFF1B5E20)),
            ),
            onPressed: () => _goToPage(context, const ProfilePage()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _userRef(user.uid).snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data();
                final name = data?['name'] ?? "GreenBite User";

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Your Daily AI Plan",
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Hi, $name 👋",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Use your fridge items before they expire and reduce food waste.",
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 22),

            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _itemsRef(user.uid).snapshots(),
              builder: (context, snapshot) {
                int itemCount = 0;
                int expiringSoon = 0;
                int expired = 0;

                if (snapshot.hasData) {
                  final items = snapshot.data!.docs;
                  itemCount = items.length;

                  final today = DateTime.now();

                  for (var doc in items) {
                    final data = doc.data();

                    if (data['expiryDate'] != null) {
                      final expiry =
                          (data['expiryDate'] as Timestamp).toDate();

                      final daysLeft = expiry
                          .difference(
                            DateTime(today.year, today.month, today.day),
                          )
                          .inDays;

                      if (daysLeft < 0) {
                        expired++;
                      } else if (daysLeft <= 3) {
                        expiringSoon++;
                      }
                    }
                  }
                }

                final wasteSaved = itemCount * 0.2;

                return _pantryPieChart(
                  itemCount: itemCount,
                  expiringSoon: expiringSoon,
                  expired: expired,
                  wasteSaved: wasteSaved,
                );
              },
            ),

            const SizedBox(height: 26),

            const Text(
              "Expiry Alerts",
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _itemsRef(user.uid)
                  .orderBy('expiryDate')
                  .limit(4)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _infoBox("Unable to load alerts", Icons.error);
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return _infoBox("No food items added yet", Icons.info);
                }

                return Column(
                  children: docs.map((doc) {
                    final data = doc.data();

                    final name = data['name'] ?? 'Unknown';
                    final quantity = data['quantity'] ?? '';
                    final expiry = (data['expiryDate'] as Timestamp).toDate();

                    final today = DateTime.now();
                    final daysLeft = expiry
                        .difference(
                          DateTime(today.year, today.month, today.day),
                        )
                        .inDays;

                    String text;
                    Color color;

                    if (daysLeft < 0) {
                      text = "Expired";
                      color = Colors.red;
                    } else if (daysLeft == 0) {
                      text = "Expires today";
                      color = Colors.red;
                    } else if (daysLeft <= 3) {
                      text = "Expires in $daysLeft days";
                      color = Colors.orange;
                    } else {
                      text = "$daysLeft days left";
                      color = Colors.green;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: color.withOpacity(0.15),
                            child: Icon(Icons.fastfood, color: color),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text("Qty: $quantity"),
                              ],
                            ),
                          ),
                          Text(
                            text,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 26),

            const Text(
              "Quick Actions",
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    "Bill Scan",
                    Icons.receipt_long,
                    () => _goToPage(context, const ScannerPage()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionButton(
                    "Fridge",
                    Icons.kitchen,
                    () => _goToPage(context, const InventoryPage()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    "Recipes",
                    Icons.restaurant,
                    () => _goToPage(context, const RecipePage()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionButton(
                    "Nutrition",
                    Icons.bar_chart,
                    () => _goToPage(context, const NutritionPage()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pantryPieChart({
    required int itemCount,
    required int expiringSoon,
    required int expired,
    required double wasteSaved,
  }) {
    final bool empty = itemCount == 0 && expiringSoon == 0 && expired == 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Text(
            "Pantry Summary",
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            height: 230,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 48,
                sectionsSpace: 3,
                sections: empty
                    ? [
                        PieChartSectionData(
                          value: 1,
                          title: "No Data",
                          color: Colors.grey.shade300,
                          radius: 65,
                          titleStyle: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ]
                    : [
                        PieChartSectionData(
                          value: itemCount == 0 ? 0.1 : itemCount.toDouble(),
                          title: "Items\n$itemCount",
                          color: const Color(0xFF2E7D32),
                          radius: 68,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        PieChartSectionData(
                          value: expiringSoon == 0
                              ? 0.1
                              : expiringSoon.toDouble(),
                          title: "Alerts\n$expiringSoon",
                          color: Colors.orange,
                          radius: 62,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        PieChartSectionData(
                          value: expired == 0 ? 0.1 : expired.toDouble(),
                          title: "Expired\n$expired",
                          color: Colors.red,
                          radius: 58,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        PieChartSectionData(
                          value: wasteSaved == 0 ? 0.1 : wasteSaved,
                          title: "Saved\n${wasteSaved.toStringAsFixed(1)}kg",
                          color: Colors.teal,
                          radius: 64,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          Wrap(
            spacing: 14,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _legend("Fridge Items", const Color(0xFF2E7D32)),
              _legend("Expiry Alerts", Colors.orange),
              _legend("Expired", Colors.red),
              _legend("Waste Saved", Colors.teal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(String title, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(title),
      ],
    );
  }

  Widget _actionButton(String text, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _infoBox(String text, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDFF5D8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2E7D32)),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}