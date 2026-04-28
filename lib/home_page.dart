import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'scanner_page.dart';
import 'inventory_page.dart';
import 'recipe_page.dart';
import 'nutrition_page.dart';

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
      backgroundColor: const Color(0xFFF3FFF4),
      appBar: AppBar(
        title: const Text("GreenBite 🌱"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _userRef(user.uid).snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data();
                final name = data?['name'] ?? "GreenBite User";
                final profileImage = data?['profileImage'];

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF2E7D32),
                        Color(0xFF43A047),
                        Color(0xFF81C784),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: Colors.white,
                        backgroundImage:
                            profileImage != null && profileImage != ""
                                ? NetworkImage(profileImage)
                                : null,
                        child: profileImage == null || profileImage == ""
                            ? const Icon(
                                Icons.person,
                                size: 38,
                                color: Colors.green,
                              )
                            : null,
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Welcome back 👋",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Eat smart. Waste less. Live better.",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
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
                          .difference(DateTime(
                            today.year,
                            today.month,
                            today.day,
                          ))
                          .inDays;

                      if (daysLeft < 0) {
                        expired++;
                      } else if (daysLeft <= 3) {
                        expiringSoon++;
                      }
                    }
                  }
                }

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.25,
                  children: [
                    _dashboardCard(
                      "Items",
                      "$itemCount",
                      Icons.kitchen,
                      const Color(0xFF4CAF50),
                    ),
                    _dashboardCard(
                      "Expiring Soon",
                      "$expiringSoon",
                      Icons.warning_amber_rounded,
                      const Color(0xFFFF9800),
                    ),
                    _dashboardCard(
                      "Expired",
                      "$expired",
                      Icons.delete_forever,
                      const Color(0xFFE53935),
                    ),
                    _dashboardCard(
                      "Waste Saved",
                      "${itemCount * 0.2}kg",
                      Icons.eco,
                      const Color(0xFF00ACC1),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            Row(
              children: const [
                Icon(Icons.notifications_active, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  "Expiry Notifications",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _itemsRef(user.uid)
                  .orderBy('expiryDate')
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _messageBox(
                    "Error loading expiry notifications",
                    Icons.error,
                    Colors.red,
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return _messageBox(
                    "No food items added yet",
                    Icons.info,
                    Colors.blue,
                  );
                }

                return Column(
                  children: docs.map((doc) {
                    final data = doc.data();
                    final name = data['name'] ?? 'Unknown item';
                    final quantity = data['quantity'] ?? '';
                    final expiry = (data['expiryDate'] as Timestamp).toDate();

                    final today = DateTime.now();
                    final daysLeft = expiry
                        .difference(DateTime(
                          today.year,
                          today.month,
                          today.day,
                        ))
                        .inDays;

                    Color color;
                    String status;

                    if (daysLeft < 0) {
                      color = Colors.red;
                      status = "Expired";
                    } else if (daysLeft == 0) {
                      color = Colors.red;
                      status = "Expires today";
                    } else if (daysLeft <= 3) {
                      color = Colors.orange;
                      status = "Expires in $daysLeft days";
                    } else {
                      color = Colors.green;
                      status = "Fresh - $daysLeft days left";
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: color,
                            child: const Icon(
                              Icons.fastfood,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text("Qty: $quantity"),
                                Text(
                                  status,
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.warning_amber_rounded, color: color),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Quick Actions",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    "Scan Food",
                    Icons.camera_alt,
                    Colors.green,
                    () => _goToPage(context, const ScannerPage()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _actionButton(
                    "Recipes",
                    Icons.restaurant,
                    Colors.orange,
                    () => _goToPage(context, const RecipePage()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    "Fridge",
                    Icons.kitchen,
                    Colors.blue,
                    () => _goToPage(context, const InventoryPage()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _actionButton(
                    "Nutrition",
                    Icons.bar_chart,
                    Colors.purple,
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

  Widget _dashboardCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 34, color: Colors.white),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(text),
    );
  }

  Widget _messageBox(String text, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}