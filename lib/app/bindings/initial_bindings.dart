import 'dart:developer';

import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../data/services/ai_therapy_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    log('🔧 InitialBinding: Registering services...');

    // Put AuthController as permanent to persist across routes
    Get.put<AuthController>(AuthController(), permanent: true);
    log('✅ AuthController registered');

    // Initialize AI service early and make it permanent
    Get.put<AiTherapyService>(AiTherapyService(), permanent: true);
    log('✅ AiTherapyService registered');
  }
}
