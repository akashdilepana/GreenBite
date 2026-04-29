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

    bool has(String food) => foods.any((item) => item.contains(food));

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

    if (generatedRecipes.isEmpty) {
      generatedRecipes.add({
        'title': 'Mixed Fridge Meal',
        'time': '20 min',
        'items': foods.join(', '),
        'steps': 'Use available ingredients to prepare a simple healthy meal.',
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
                const SizedBox(height: 12),
                TextField(
                  controller: timeController,
                  decoration: const InputDecoration(labelText: "Time"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: itemsController,
                  decoration: const InputDecoration(labelText: "Ingredients"),
                ),
                const SizedBox(height: 12),
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
  }

  void _viewRecipe(Map<String, dynamic> recipe) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(recipe['title'] ?? ''),
        content: Text(
          "Ingredients:\n${recipe['items'] ?? ''}\n\n"
          "Time: ${recipe['time'] ?? ''}\n\n"
          "Steps:\n${recipe['steps'] ?? 'No steps added'}",
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
      return const Scaffold(body: Center(child: Text("Please login first")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6FFF2),
      appBar: AppBar(
        title: const Text(
          "Recipes",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2E7D32),
        onPressed: () => _showRecipeDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(18),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 46),
                const SizedBox(height: 10),
                const Text(
                  "Generate From Fridge",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Create recipes using your available fridge items.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(
                  width: double.infinity, // 🔥 makes button full width
                  height: 55, // optional (increase height)
                  child: ElevatedButton.icon(
                    onPressed: generateRecipesFromFridge,
                    icon: const Icon(Icons.restaurant_menu),
                    label: const Text("Generate Recipes"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA9F579),
                      foregroundColor: const Color(0xFF1B5E20),
                    ),
                  ),
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

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final recipes = snapshot.data!.docs;

                if (recipes.isEmpty) {
                  return const Center(
                    child: Text("No recipes yet. Generate or add one."),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 90),
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    final doc = recipes[index];
                    final recipe = doc.data();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFDFF5D8),
                          child: Icon(
                            recipe['generated'] == true
                                ? Icons.auto_awesome
                                : Icons.restaurant,
                            color: const Color(0xFF2E7D32),
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
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text("Edit")),
                            PopupMenuItem(
                                value: 'delete', child: Text("Delete")),
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