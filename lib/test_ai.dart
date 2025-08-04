// lib/test_ai.dart - Quick test file
import 'dart:developer';

import 'package:google_generative_ai/google_generative_ai.dart';

Future<void> testGeminiAPI() async {
  // Replace with your actual API key
  const apiKey = 'API_KEY_HERE';

  try {
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );

    final prompt = "I'm feeling sad today. Can you help me?";
    final response = await model.generateContent([Content.text(prompt)]);

    log('✅ AI Response: ${response.text}');
  } catch (e) {
    log('❌ AI Error: $e');
  }
}

// Call this in your main.dart temporarily to test
// testGeminiAPI();
