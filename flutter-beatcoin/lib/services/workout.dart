import 'dart:async';

import 'package:get/get.dart';

class WorkoutService extends GetxService {
  final start = DateTime.now().obs;
  final end = DateTime.now().obs;
  final duration = '00:00:00'.obs;
  final running = false.obs;
  late Timer _timer;

  void startWorkout() {
    running.value = true;
    start.value = DateTime.now();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      end.value = DateTime.now();
      final diff = end.value.difference(start.value);
      final hh = (diff.inHours).toString().padLeft(2, '0');
      final mm = (diff.inMinutes % 60).toString().padLeft(2, '0');
      final ss = (diff.inSeconds % 60).toString().padLeft(2, '0');
      duration.value = '$hh:$mm:$ss';
    });
  }

  void stopWorkout() {
    running.value = false;
    _timer.cancel();
  }
}
