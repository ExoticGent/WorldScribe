import 'package:flutter/material.dart';

void main() {
  runApp(const WorldScribeApp());
}

class WorldScribeApp extends StatelessWidget {
  const WorldScribeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WorldScribe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: const Scaffold(
        body: Center(child: Text('WorldScribe')),
      ),
    );
  }
}
