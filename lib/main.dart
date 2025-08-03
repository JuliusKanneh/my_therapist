// lib/main.dart - Temporary test version
import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
// import 'firebase_options.dart';
import 'test_firebase.dart'; // Remove this after testing

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Test Firebase connection
  await testFirebaseConnection();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'AI Therapist Chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: TestHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TestHomePage extends StatelessWidget {
  const TestHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Therapist Chat - Firebase Test'),
        backgroundColor: Colors.blue.shade100,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology,
              size: 80,
              color: Colors.blue,
            ),
            SizedBox(height: 20),
            Text(
              'AI Therapist Chat',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Firebase connection test completed!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Check the console for Firebase test results',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
