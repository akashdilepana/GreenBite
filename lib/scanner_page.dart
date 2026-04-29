import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final user = FirebaseAuth.instance.currentUser;

  File? billImage;
  bool isScanning = false;
  List<String> detectedItems = [];

  final List<String> groceryKeywords = [
    'milk', 'bread', 'egg', 'eggs', 'rice', 'banana', 'apple', 'orange',
    'chicken', 'fish', 'beef', 'potato', 'onion', 'tomato', 'carrot',
    'beans', 'cheese', 'yogurt', 'butter', 'flour', 'sugar', 'salt',
    'tea', 'coffee', 'noodles', 'pasta', 'oil', 'cabbage', 'leeks',
    'garlic', 'ginger',
  ];

  CollectionReference<Map<String, dynamic>> get itemsRef {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('items');
  }

  Future<void> pickBillImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile == null) return;

    setState(() {
      billImage = File(pickedFile.path);
      detectedItems.clear();
    });

    await scanBillText(File(pickedFile.path));
  }

  Future<void> scanBillText(File imageFile) async {
    setState(() => isScanning = true);

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      final text = recognizedText.text.toLowerCase();
      final foundItems = <String>{};

      for (final keyword in groceryKeywords) {
        if (text.contains(keyword)) {
          foundItems.add(_capitalize(keyword));
        }
      }

      setState(() {
        detectedItems = foundItems.toList();
      });

      if (detectedItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No grocery items detected")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Scan failed: $e")),
      );
    }

    setState(() => isScanning = false);
  }

  Future<void> addItemsToFridge() async {
    if (detectedItems.isEmpty) return;

    final expiryDate = DateTime.now().add(const Duration(days: 7));

    for (final item in detectedItems) {
      await itemsRef.add({
        'name': item,
        'quantity': '1',
        'expiryDate': Timestamp.fromDate(expiryDate),
        'createdAt': Timestamp.now(),
        'source': 'Bill Scanner',
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Items added to Virtual Fridge")),
    );

    setState(() {
      detectedItems.clear();
      billImage = null;
    });
  }

  String _capitalize(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please login first")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6FFF2),
      appBar: AppBar(
        title: const Text(
          "Bill Scanner",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Column(
                children: [
                  Icon(Icons.receipt_long, size: 70, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    "Scan Grocery Bill",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Take a photo of your bill and add detected items to your fridge.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _scanButton(
                    "Camera",
                    Icons.camera_alt,
                    () => pickBillImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _scanButton(
                    "Gallery",
                    Icons.image,
                    () => pickBillImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            if (billImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.file(
                  billImage!,
                  height: 230,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            if (isScanning) ...[
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              const SizedBox(height: 10),
              const Text("Scanning bill..."),
            ],

            if (!isScanning && detectedItems.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Detected Items",
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: detectedItems.map((item) {
                    return Chip(
                      label: Text(item),
                      backgroundColor: const Color(0xFFDFF5D8),
                      deleteIcon: const Icon(Icons.close),
                      onDeleted: () {
                        setState(() => detectedItems.remove(item));
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: addItemsToFridge,
                  icon: const Icon(Icons.kitchen),
                  label: const Text("Add Items to Fridge"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _scanButton(String text, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}