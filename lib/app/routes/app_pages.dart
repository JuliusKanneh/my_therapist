import 'package:get/get.dart';
import 'package:my_therapist/app/bindings/auth_bindings.dart';
import 'package:my_therapist/app/bindings/chat_bindings.dart';
import '../ui/pages/auth/login_page.dart';
import '../ui/pages/auth/register_page.dart';
import '../ui/pages/home/home_page.dart';
import '../ui/pages/chat/chat_page.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static final pages = [
    GetPage(
      name: Routes.LOGIN,
      page: () => LoginPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.REGISTER,
      page: () => RegisterPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.HOME,
      page: () => HomePage(),
      bindings: [
        AuthBinding(),
        ChatBinding(),
      ],
    ),
    GetPage(
      name: Routes.CHAT,
      page: () => ChatPage(),
      binding: ChatBinding(),
    ),
  ];
}
