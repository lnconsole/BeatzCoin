import 'package:get/get.dart';
import 'package:logger/logger.dart';

class DebugService extends GetxController {
  final messages = <String>[].obs;
  final Logger _logger;

  DebugService(this._logger);

  void log(String msg) {
    messages.insert(0, msg);
    _logger.i(msg);
  }
}
