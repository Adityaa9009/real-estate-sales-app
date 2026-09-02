import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0B0F1A),
      child: const Center(
        child: Icon(Icons.home_work_outlined, color: Colors.white24, size: 96),
      ),
    );
  }
}
