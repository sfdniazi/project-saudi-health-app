import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        const CircleAvatar(radius: 48, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=3')),
        const SizedBox(height: 12),
        const Text('Taqi Naqvi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text('Software & Fitness', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 18),
        Card(child: ListTile(title: const Text('Daily Goal'), subtitle: const Text('2000 kcal'), trailing: Icon(Icons.edit))),
        Card(child: ListTile(title: const Text('Units'), subtitle: const Text('Metric (kg, cm)'), trailing: Icon(Icons.chevron_right))),
        Card(child: ListTile(title: const Text('Logout'), leading: Icon(Icons.logout), onTap: () {})),
      ])),
    );
  }
}
