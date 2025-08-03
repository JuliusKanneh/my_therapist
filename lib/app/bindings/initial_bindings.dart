import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Put AuthController as permanent to persist across routes
    Get.put<AuthController>(AuthController(), permanent: true);
  }
}
