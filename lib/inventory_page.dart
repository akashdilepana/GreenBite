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
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login first")),
      );
      return;
    }

    final nameController = TextEditingController();
    final qtyController = TextEditingController();
    DateTime selectedDate = DateTime.now();

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
              TextField(
                controller: qtyController,
                decoration: const InputDecoration(labelText: "Quantity"),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: dialogContext,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );

                  if (picked != null) {
                    selectedDate = picked;
                  }
                },
                child: const Text("Select Expiry Date"),
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
                try {
                  if (nameController.text.trim().isEmpty ||
                      qtyController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fill all fields")),
                    );
                    return;
                  }

                  await itemsRef.add({
                    'name': nameController.text.trim(),
                    'quantity': qtyController.text.trim(),
                    'expiryDate': Timestamp.fromDate(selectedDate),
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  Navigator.pop(dialogContext);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Item added successfully")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Add failed: $e")),
                  );
                }
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
          title: const Text("Edit Item"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController),
              TextField(controller: qtyController),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                await itemsRef.doc(id).update({
                  'name': nameController.text.trim(),
                  'quantity': qtyController.text.trim(),
                });

                Navigator.pop(dialogContext);
              },
              child: const Text("Update"),
            )
          ],
        );
      },
    );
  }

  Color _getColor(DateTime expiry) {
    final days = expiry.difference(DateTime.now()).inDays;

    if (days <= 1) return Colors.red;
    if (days <= 3) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please login first")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Virtual Fridge 🧊"),
        backgroundColor: Colors.green,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: itemsRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!.docs;

          if (items.isEmpty) {
            return const Center(child: Text("No items yet. Tap + to add."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final data = item.data();

              final expiry =
                  (data['expiryDate'] as Timestamp).toDate();

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getColor(expiry),
                  ),
                  title: Text(data['name'] ?? ''),
                  subtitle: Text(
                    "Qty: ${data['quantity']} | Exp: ${expiry.day}/${expiry.month}/${expiry.year}",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _updateItem(item.id, data),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteItem(item.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}