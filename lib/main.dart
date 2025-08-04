import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:get/get.dart';
import 'package:my_therapist/app/bindings/initial_bindings.dart';
import 'package:my_therapist/app/controllers/auth_controller.dart';
import 'package:my_therapist/app/data/services/ai_therapy_service.dart';
import 'firebase_options.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables FIRST
  try {
    await dotenv.load(fileName: ".env");
    log('✅ Environment variables loaded');

    // Verify API key is loaded (without printing the actual key)
    final hasApiKey = dotenv.env['GEMINI_API_KEY']?.isNotEmpty ?? false;
    log('🔐 API key loaded: $hasApiKey');
  } catch (e) {
    log('⚠️ Warning: Could not load .env file: $e');
    log('📝 Make sure .env file exists in project root');
  }

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Future.delayed(Duration(seconds: 2), () {
  //   log("AI Therapist Chat App started successfully!");
  //   testGeminiAPI();
  // });

// FORCE REGISTER SERVICES BEFORE GetX APP STARTS
  log('🔧 FORCE registering services in main()...');

  try {
    // Force register AuthController
    Get.put<AuthController>(AuthController(), permanent: true);
    log('✅ AuthController force-registered: ${Get.isRegistered<AuthController>()}');

    // Force register AI service
    Get.put<AiTherapyService>(AiTherapyService(), permanent: true);
    log('✅ AiTherapyService force-registered: ${Get.isRegistered<AiTherapyService>()}');

    // Verify they're accessible
    final authTest = Get.find<AuthController>();
    final aiTest = Get.find<AiTherapyService>();
    log('✅ Services verified - Auth: ${authTest.hashCode}, AI: ${aiTest.hashCode}');
  } catch (e) {
    log('❌ Error force-registering services: $e');
  }

  log('🎯 About to run app...');

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
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: Colors.black),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.blue,
            side: BorderSide(color: Colors.blue),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Colors.blue,
      ),
      themeMode: ThemeMode.system,
      initialRoute: Routes.LOGIN,
      getPages: AppPages.pages,
      initialBinding: InitialBinding(),
      debugShowCheckedModeBanner: false,
      // Add lifecycle callbacks to track GetX state
      routingCallback: (routing) {
        log('🔄 Route changed to: ${routing?.current}');

        // Check service registration after each route change
        Future.delayed(Duration(milliseconds: 100), () {
          log('📊 SERVICE STATUS CHECK:');
          log('🔍 AuthController registered? ${Get.isRegistered<AuthController>()}');
          log('🔍 AiTherapyService registered? ${Get.isRegistered<AiTherapyService>()}');

          if (Get.isRegistered<AiTherapyService>()) {
            try {
              final service = Get.find<AiTherapyService>();
              log('✅ AiTherapyService accessible: ${service.hashCode}');
            } catch (e) {
              log('❌ AiTherapyService not accessible: $e');
            }
          }
        });
      },
    );
  }
}
