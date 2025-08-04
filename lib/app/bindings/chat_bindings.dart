// lib/app/bindings/chat_binding.dart
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../controllers/auth_controller.dart';
import '../data/services/ai_therapy_service.dart';

class ChatBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure AI service is available
    if (!Get.isRegistered<AiTherapyService>()) {
      Get.put<AiTherapyService>(AiTherapyService(), permanent: true);
    }

    // Ensure AuthController is available
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(AuthController());
    }

    Get.lazyPut<ChatController>(() => ChatController());
  }
}
