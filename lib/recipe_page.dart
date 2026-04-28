import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecipePage extends StatefulWidget {
  const RecipePage({super.key});

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  final user = FirebaseAuth.instance.currentUser;

  CollectionReference<Map<String, dynamic>> get recipesRef {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('recipes');
  }

  CollectionReference<Map<String, dynamic>> get itemsRef {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('items');
  }

  Future<void> generateRecipesFromFridge() async {
    final itemSnapshot = await itemsRef.get();

    if (itemSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No fridge items found")),
      );
      return;
    }

    final foods = itemSnapshot.docs
        .map((doc) => (doc.data()['name'] ?? '').toString().toLowerCase())
        .toList();

    final generatedRecipes = <Map<String, dynamic>>[];

    bool has(String food) {
      return foods.any((item) => item.contains(food));
    }

    if (has('banana') && has('milk')) {
      generatedRecipes.add({
        'title': 'Banana Smoothie',
        'time': '5 min',
        'items': 'Banana, Milk',
        'steps': 'Blend banana with milk. Serve chilled.',
      });
    }

    if (has('rice') && has('egg')) {
      generatedRecipes.add({
        'title': 'Egg Fried Rice',
        'time': '20 min',
        'items': 'Rice, Egg',
        'steps': 'Fry egg, add rice, mix well with spices.',
      });
    }

    if (has('bread') && has('egg')) {
      generatedRecipes.add({
        'title': 'Egg Sandwich',
        'time': '10 min',
        'items': 'Bread, Egg',
        'steps': 'Boil or fry egg. Place inside bread and serve.',
      });
    }

    if (has('rice') && (has('carrot') || has('beans') || has('vegetable'))) {
      generatedRecipes.add({
        'title': 'Vegetable Fried Rice',
        'time': '25 min',
        'items': 'Rice, Vegetables',
        'steps': 'Cook vegetables, add rice, season and stir fry.',
      });
    }

    if (has('tomato') && has('onion')) {
      generatedRecipes.add({
        'title': 'Tomato Onion Salad',
        'time': '8 min',
        'items': 'Tomato, Onion',
        'steps': 'Slice tomato and onion. Mix with salt and pepper.',
      });
    }

    if (has('potato')) {
      generatedRecipes.add({
        'title': 'Potato Curry',
        'time': '30 min',
        'items': 'Potato',
        'steps': 'Cook potatoes with curry powder, onion, and spices.',
      });
    }

    if (generatedRecipes.isEmpty) {
      generatedRecipes.add({
        'title': 'Mixed Fridge Meal',
        'time': '20 min',
        'items': foods.join(', '),
        'steps':
            'Use your available ingredients to prepare a simple stir fry, salad, or rice bowl.',
      });
    }

    for (final recipe in generatedRecipes) {
      await recipesRef.add({
        ...recipe,
        'generated': true,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${generatedRecipes.length} recipes generated")),
    );
  }

  void _showRecipeDialog({String? docId, Map<String, dynamic>? data}) {
    final titleController = TextEditingController(text: data?['title'] ?? '');
    final timeController = TextEditingController(text: data?['time'] ?? '');
    final itemsController = TextEditingController(text: data?['items'] ?? '');
    final stepsController = TextEditingController(text: data?['steps'] ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(docId == null ? "Add Recipe" : "Update Recipe"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Recipe Title"),
                ),
                TextField(
                  controller: timeController,
                  decoration: const InputDecoration(labelText: "Time"),
                ),
                TextField(
                  controller: itemsController,
                  decoration: const InputDecoration(
                    labelText: "Ingredients",
                    hintText: "Rice, carrot, egg",
                  ),
                ),
                TextField(
                  controller: stepsController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: "Steps"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty ||
                    timeController.text.trim().isEmpty ||
                    itemsController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please fill required fields")),
                  );
                  return;
                }

                final recipeData = {
                  'title': titleController.text.trim(),
                  'time': timeController.text.trim(),
                  'items': itemsController.text.trim(),
                  'steps': stepsController.text.trim(),
                  'generated': data?['generated'] ?? false,
                  'updatedAt': Timestamp.now(),
                };

                if (docId == null) {
                  await recipesRef.add({
                    ...recipeData,
                    'createdAt': Timestamp.now(),
                  });
                } else {
                  await recipesRef.doc(docId).update(recipeData);
                }

                Navigator.pop(dialogContext);
              },
              child: Text(docId == null ? "Save" : "Update"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteRecipe(String docId) async {
    await recipesRef.doc(docId).delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Recipe deleted")),
    );
  }

  void _viewRecipe(Map<String, dynamic> recipe) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(recipe['title'] ?? ''),
        content: Text(
          "Ingredients:\n${recipe['items'] ?? ''}\n\n"
          "Time: ${recipe['time'] ?? ''}\n\n"
          "Steps:\n${recipe['steps'] ?? 'No steps added'}\n\n"
          "${recipe['generated'] == true ? 'Generated from your Virtual Fridge.' : 'Custom recipe.'}",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please login first")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF4),
      appBar: AppBar(
        title: const Text("Waste-Free Recipes 🍲"),
        backgroundColor: Colors.green,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () => _showRecipeDialog(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.orange, size: 40),
                const SizedBox(height: 8),
                const Text(
                  "Generate Recipes From Virtual Fridge",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "GreenBite will suggest meals using your current food items.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: generateRecipesFromFridge,
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text("Generate Recipes"),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream:
                  recipesRef.orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final recipes = snapshot.data?.docs ?? [];

                if (recipes.isEmpty) {
                  return const Center(
                    child: Text("No recipes yet. Generate or add one."),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    final doc = recipes[index];
                    final recipe = doc.data();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: recipe['generated'] == true
                              ? Colors.green.shade100
                              : Colors.orange.shade100,
                          child: Icon(
                            recipe['generated'] == true
                                ? Icons.auto_awesome
                                : Icons.restaurant,
                            color: recipe['generated'] == true
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                        title: Text(
                          recipe['title'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Uses: ${recipe['items'] ?? ''}\nTime: ${recipe['time'] ?? ''}",
                        ),
                        isThreeLine: true,
                        onTap: () => _viewRecipe(recipe),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showRecipeDialog(docId: doc.id, data: recipe);
                            } else if (value == 'delete') {
                              _deleteRecipe(doc.id);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text("Edit"),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text("Delete"),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}