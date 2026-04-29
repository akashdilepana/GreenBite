import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NutritionPage extends StatefulWidget {
  const NutritionPage({super.key});

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  final user = FirebaseAuth.instance.currentUser;

  final ageController = TextEditingController();
  final weightController = TextEditingController();
  final heightController = TextEditingController();

  String gender = "Male";
  String goal = "Maintain Weight";

  DocumentReference<Map<String, dynamic>> get nutritionRef {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('nutrition')
        .doc('plan');
  }

  int calculateCalories(int age, double weight, double height) {
    double bmr;

    if (gender == "Male") {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }

    if (goal == "Lose Weight") {
      bmr -= 400;
    } else if (goal == "Gain Weight") {
      bmr += 400;
    }

    return bmr.round();
  }

  Map<String, int> calculateMacros(int calories, double weight) {
    int protein = (weight * 1.6).round();
    int fat = ((calories * 0.25) / 9).round();
    int carbs = ((calories - (protein * 4) - (fat * 9)) / 4).round();

    return {
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  List<Map<String, String>> generateWeeklyMeals(int calories) {
    return [
      {
        'day': 'Monday',
        'breakfast': 'Oats with banana',
        'lunch': 'Chicken rice with vegetables',
        'dinner': 'Vegetable soup with bread',
      },
      {
        'day': 'Tuesday',
        'breakfast': 'Egg sandwich',
        'lunch': 'Fish curry with rice',
        'dinner': 'Fruit bowl with yogurt',
      },
      {
        'day': 'Wednesday',
        'breakfast': 'Banana smoothie',
        'lunch': 'Vegetable fried rice',
        'dinner': 'Chicken salad',
      },
      {
        'day': 'Thursday',
        'breakfast': 'Toast with eggs',
        'lunch': 'Rice with dhal and vegetables',
        'dinner': 'Pasta with vegetables',
      },
      {
        'day': 'Friday',
        'breakfast': 'Oats and milk',
        'lunch': 'Chicken wrap',
        'dinner': 'Vegetable noodles',
      },
      {
        'day': 'Saturday',
        'breakfast': 'Fruit smoothie',
        'lunch': 'Egg rice with vegetables',
        'dinner': 'Soup and salad',
      },
      {
        'day': 'Sunday',
        'breakfast': 'Milk rice with fruit',
        'lunch': 'Rice with fish and vegetables',
        'dinner': 'Light vegetable meal',
      },
    ];
  }

  Future<void> createNutritionPlan() async {
    if (ageController.text.isEmpty ||
        weightController.text.isEmpty ||
        heightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    final age = int.parse(ageController.text.trim());
    final weight = double.parse(weightController.text.trim());
    final height = double.parse(heightController.text.trim());

    final calories = calculateCalories(age, weight, height);
    final macros = calculateMacros(calories, weight);
    final meals = generateWeeklyMeals(calories);

    final now = DateTime.now();
    final validUntil = now.add(const Duration(days: 7));

    await nutritionRef.set({
      'age': age,
      'weight': weight,
      'height': height,
      'gender': gender,
      'goal': goal,
      'calories': calories,
      'protein': macros['protein'],
      'carbs': macros['carbs'],
      'fat': macros['fat'],
      'mealPlan': meals,
      'createdAt': Timestamp.fromDate(now),
      'validUntil': Timestamp.fromDate(validUntil),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Nutrition plan generated")),
    );
  }

  DocumentReference<Map<String, dynamic>> get newMethod => nutritionRef;

  Future<void> regeneratePlan(Map<String, dynamic> data) async {
    ageController.text = data['age'].toString();
    weightController.text = data['weight'].toString();
    heightController.text = data['height'].toString();
    gender = data['gender'] ?? "Male";
    goal = data['goal'] ?? "Maintain Weight";

    await createNutritionPlan();
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
        title: const Text("Nutrition Plan"),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: nutritionRef.snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();

          if (data == null) {
            return _buildCreatePlanForm();
          }

          final validUntil = (data['validUntil'] as Timestamp).toDate();
          final isExpired = DateTime.now().isAfter(validUntil);

          if (isExpired) {
            return _buildExpiredPlan(data);
          }

          return _buildNutritionDashboard(data, validUntil);
        },
      ),
    );
  }

  Widget _buildCreatePlanForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(Icons.health_and_safety, size: 80, color: Colors.green),
          const SizedBox(height: 12),
          const Text(
            "Create Your Nutrition Plan",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          TextField(
            controller: ageController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration("Age", Icons.cake),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: weightController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration("Weight (kg)", Icons.monitor_weight),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: heightController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration("Height (cm)", Icons.height),
          ),
          const SizedBox(height: 14),

          DropdownButtonFormField<String>(
            value: gender,
            decoration: _inputDecoration("Gender", Icons.person),
            items: const [
              DropdownMenuItem(value: "Male", child: Text("Male")),
              DropdownMenuItem(value: "Female", child: Text("Female")),
            ],
            onChanged: (value) {
              setState(() {
                gender = value!;
              });
            },
          ),
          const SizedBox(height: 14),

          DropdownButtonFormField<String>(
            value: goal,
            decoration: _inputDecoration("Goal", Icons.flag),
            items: const [
              DropdownMenuItem(
                value: "Lose Weight",
                child: Text("Lose Weight"),
              ),
              DropdownMenuItem(
                value: "Maintain Weight",
                child: Text("Maintain Weight"),
              ),
              DropdownMenuItem(
                value: "Gain Weight",
                child: Text("Gain Weight"),
              ),
            ],
            onChanged: (value) {
              setState(() {
                goal = value!;
              });
            },
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: createNutritionPlan,
              icon: const Icon(Icons.auto_awesome),
              label: const Text("Generate Weekly Meal Plan"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiredPlan(Map<String, dynamic> data) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.refresh, size: 70, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  "Your weekly meal plan has expired",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Generate a new plan for the next 7 days.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => regeneratePlan(data),
                  child: const Text("Generate New Week Plan"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionDashboard(
    Map<String, dynamic> data,
    DateTime validUntil,
  ) {
    final meals = List<Map<String, dynamic>>.from(data['mealPlan']);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Plan valid until: ${validUntil.day}/${validUntil.month}/${validUntil.year}",
            style: const TextStyle(color: Colors.black54),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _nutritionCard(
                  "Calories",
                  data['calories'].toString(),
                  "kcal",
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _nutritionCard(
                  "Protein",
                  data['protein'].toString(),
                  "g",
                  Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _nutritionCard(
                  "Carbs",
                  data['carbs'].toString(),
                  "g",
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _nutritionCard(
                  "Fat",
                  data['fat'].toString(),
                  "g",
                  Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          const Text(
            "Weekly Meal Plan",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          ...meals.map((meal) {
            return _mealTile(
              meal['day'],
              meal['breakfast'],
              meal['lunch'],
              meal['dinner'],
            );
          }).toList(),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => nutritionRef.delete(),
              icon: const Icon(Icons.edit),
              label: const Text("Edit My Details"),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  Widget _nutritionCard(
    String title,
    String value,
    String unit,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(unit),
        ],
      ),
    );
  }

  Widget _mealTile(
    String day,
    String breakfast,
    String lunch,
    String dinner,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: const Icon(Icons.calendar_today, color: Colors.green),
        title: Text(
          day,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text("Tap to view meals"),
        children: [
          ListTile(
            leading: const Icon(Icons.free_breakfast),
            title: const Text("Breakfast"),
            subtitle: Text(breakfast),
          ),
          ListTile(
            leading: const Icon(Icons.lunch_dining),
            title: const Text("Lunch"),
            subtitle: Text(lunch),
          ),
          ListTile(
            leading: const Icon(Icons.dinner_dining),
            title: const Text("Dinner"),
            subtitle: Text(dinner),
          ),
        ],
      ),
    );
  }
}