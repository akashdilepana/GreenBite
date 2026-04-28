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
    'milk',
    'bread',
    'egg',
    'eggs',
    'rice',
    'banana',
    'apple',
    'orange',
    'chicken',
    'fish',
    'beef',
    'potato',
    'onion',
    'tomato',
    'carrot',
    'beans',
    'cheese',
    'yogurt',
    'butter',
    'flour',
    'sugar',
    'salt',
    'tea',
    'coffee',
    'noodles',
    'pasta',
    'oil',
    'cabbage',
    'leeks',
    'garlic',
    'ginger',
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
    setState(() {
      isScanning = true;
    });

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

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

    setState(() {
      isScanning = false;
    });
  }

  Future<void> addItemsToFridge() async {
    if (detectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No items to add")),
      );
      return;
    }

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

  void removeDetectedItem(String item) {
    setState(() {
      detectedItems.remove(item);
    });
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please login first")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3FFF4),
      appBar: AppBar(
        title: const Text("Bill Scanner 🧾"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.receipt_long,
                    size: 70,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Scan Your Grocery Bill",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Take a photo of your Food City bill and GreenBite will detect grocery items.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => pickBillImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text("Camera"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => pickBillImage(ImageSource.gallery),
                          icon: const Icon(Icons.image),
                          label: const Text("Gallery"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (billImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  billImage!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 20),

            if (isScanning)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text("Scanning bill..."),
                ],
              ),

            if (!isScanning && detectedItems.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Detected Grocery Items",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: detectedItems.map((item) {
                  return Chip(
                    label: Text(item),
                    backgroundColor: Colors.green.shade100,
                    deleteIcon: const Icon(Icons.close),
                    onDeleted: () => removeDetectedItem(item),
                  );
                }).toList(),
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: addItemsToFridge,
                  icon: const Icon(Icons.kitchen),
                  label: const Text("Add Items to Virtual Fridge"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}