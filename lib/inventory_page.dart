import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  User? get user => FirebaseAuth.instance.currentUser;

  CollectionReference<Map<String, dynamic>> get itemsRef {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('items');
  }

  Future<void> _addItem() async {
    final nameController = TextEditingController();
    final qtyController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Add Food Item"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Item name"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyController,
                decoration: const InputDecoration(labelText: "Quantity"),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: dialogContext,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );

                  if (picked != null) {
                    selectedDate = picked;
                  }
                },
                icon: const Icon(Icons.calendar_month),
                label: const Text("Select Expiry Date"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty ||
                    qtyController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Fill all fields")),
                  );
                  return;
                }

                await itemsRef.add({
                  'name': nameController.text.trim(),
                  'quantity': qtyController.text.trim(),
                  'expiryDate': Timestamp.fromDate(selectedDate),
                  'createdAt': Timestamp.now(),
                });

                Navigator.pop(dialogContext);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteItem(String id) async {
    await itemsRef.doc(id).delete();
  }

  void _updateItem(String id, Map<String, dynamic> data) {
    final nameController = TextEditingController(text: data['name']);
    final qtyController = TextEditingController(text: data['quantity']);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Update Item"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Item name"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyController,
                decoration: const InputDecoration(labelText: "Quantity"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                await itemsRef.doc(id).update({
                  'name': nameController.text.trim(),
                  'quantity': qtyController.text.trim(),
                });

                Navigator.pop(dialogContext);
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  Color _statusColor(DateTime expiry) {
    final today = DateTime.now();
    final days = expiry
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;

    if (days < 0) return Colors.red;
    if (days <= 3) return Colors.orange;
    return const Color(0xFF2E7D32);
  }

  String _statusText(DateTime expiry) {
    final today = DateTime.now();
    final days = expiry
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;

    if (days < 0) return "Expired";
    if (days == 0) return "Today";
    if (days <= 3) return "$days days";
    return "$days days left";
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please login first")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6FFF2),
      appBar: AppBar(
        title: const Text(
          "Virtual Fridge",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2E7D32),
        onPressed: _addItem,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: itemsRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!.docs;

          if (items.isEmpty) {
            return const Center(
              child: Text("No items yet. Tap + to add food."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final doc = items[index];
              final data = doc.data();

              final expiry = (data['expiryDate'] as Timestamp).toDate();
              final color = _statusColor(expiry);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: color.withOpacity(0.15),
                      child: Icon(Icons.fastfood, color: color),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text("Qty: ${data['quantity']}"),
                          const SizedBox(height: 4),
                          Text(
                            "Expiry: ${expiry.day}/${expiry.month}/${expiry.year}",
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),

                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _statusText(expiry),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _updateItem(doc.id, data),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () => _deleteItem(doc.id),
                            ),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}