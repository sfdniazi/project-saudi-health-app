import 'package:flutter/material.dart';

class MealDetailScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final String kcal;
  final String imageUrl;
  const MealDetailScreen({super.key, required this.title, required this.subtitle, required this.kcal, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(imageUrl, height: 220, width: double.infinity, fit: BoxFit.cover)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(subtitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text(kcal, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          const Text('Ingredients:\n• Item 1\n• Item 2\n• Item 3', style: TextStyle(height: 1.4)),
        ]),
      ),
    );
  }
}
