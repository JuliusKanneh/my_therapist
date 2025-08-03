// lib/test_firebase.dart
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

Future<void> testFirebaseConnection() async {
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    log('✅ Firebase initialized successfully');

    // Test Firestore
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('test').doc('connection').set({
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'connected',
      'message': 'AI Therapist Chat App Firebase Test'
    });

    log('✅ Firestore connection successful - test document created');

    // Test Auth
    final auth = FirebaseAuth.instance;
    log('✅ Firebase Auth initialized: ${auth.currentUser?.uid ?? 'No user signed in'}');

    // Test reading the document we just created
    final doc = await firestore.collection('test').doc('connection').get();
    if (doc.exists) {
      log('✅ Firestore read test successful: ${doc.data()}');
    }
  } catch (e) {
    log('❌ Firebase connection failed: $e');
  }
}
