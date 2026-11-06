import 'package:flutter/material.dart';

void main() {
  runApp(const ControlDeudasApp());
}

class ControlDeudasApp extends StatelessWidget {
  const ControlDeudasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Control de Deudas',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Deudas'),
      ),
      body: const Center(
        child: Text(
          '¡Mi aplicación de deudas está funcionando!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
