import 'package:flutter/material.dart';

class RecipePage extends StatelessWidget {
  const RecipePage({super.key});

  final List<Map<String, String>> recipes = const [
    {
      'title': 'Vegetable Fried Rice',
      'time': '20 min',
      'items': 'Rice, Carrot, Beans',
    },
    {
      'title': 'Banana Smoothie',
      'time': '5 min',
      'items': 'Banana, Milk',
    },
    {
      'title': 'Egg Sandwich',
      'time': '10 min',
      'items': 'Egg, Bread, Tomato',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Waste-Free Recipes 🍲"),
        backgroundColor: Colors.green,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final recipe = recipes[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange.shade100,
                child: const Icon(Icons.restaurant, color: Colors.orange),
              ),
              title: Text(
                recipe['title']!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "Uses: ${recipe['items']}\nTime: ${recipe['time']}",
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(recipe['title']!),
                    content: Text(
                      "Suggested ingredients:\n${recipe['items']}\n\nThis recipe helps reduce food waste by using items you may already have.",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Close"),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}