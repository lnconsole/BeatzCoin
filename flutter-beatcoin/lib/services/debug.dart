import 'package:get/get.dart';

class DebugService extends GetxController {
  final messages = <String>[].obs;

  void log(String msg) {
    messages.insert(0, msg);
    print(msg);
  }
}
