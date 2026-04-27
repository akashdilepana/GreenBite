import 'package:flutter/material.dart';

class NutritionPage extends StatelessWidget {
  const NutritionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nutrition Plan 📊"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Today's Nutrition Summary",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(child: _nutritionCard("Calories", "1800", "kcal")),
                const SizedBox(width: 12),
                Expanded(child: _nutritionCard("Protein", "75", "g")),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(child: _nutritionCard("Carbs", "220", "g")),
                const SizedBox(width: 12),
                Expanded(child: _nutritionCard("Fat", "55", "g")),
              ],
            ),

            const SizedBox(height: 30),

            const Text(
              "Weekly Meal Plan",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            _mealTile("Monday", "Oats + Vegetable Rice + Soup"),
            _mealTile("Tuesday", "Egg Sandwich + Pasta + Fruit Bowl"),
            _mealTile("Wednesday", "Smoothie + Chicken Rice + Salad"),
            _mealTile("Thursday", "Toast + Fried Rice + Soup"),
            _mealTile("Friday", "Oats + Noodles + Banana Smoothie"),
          ],
        ),
      ),
    );
  }

  Widget _nutritionCard(String title, String value, String unit) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(unit),
        ],
      ),
    );
  }

  Widget _mealTile(String day, String meals) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_today, color: Colors.green),
        title: Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(meals),
      ),
    );
  }
}