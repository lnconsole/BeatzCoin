import 'dart:async';
import 'dart:convert';
import 'package:beatcoin/services/polar.dart';
import 'package:wakelock/wakelock.dart';
import 'package:beatcoin/services/nostr.dart';
import 'package:get/get.dart';

class WorkoutService extends GetxService {
  final start = DateTime.now().obs;
  final end = DateTime.now().obs;
  final duration = '00:00:00'.obs;
  final running = false.obs;
  late Timer _workoutDurationTimer;
  late Timer _workoutRewardsTimer;
  NostrService _nostrService;
  PolarService _polarService;

  WorkoutService(
    this._nostrService,
    this._polarService,
  );

  void startWorkout() {
    Wakelock.enable();
    running.value = true;
    start.value = DateTime.now();

    _workoutDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _formatWorkoutTime();
    });

    final message = {
      'beatzcoin_secret': 'secret',
      'bpm': 181,
    };
    _nostrService.sendEncryptedDM(
      '4076e3081853a23cb5b826b0501a93d3c74a4db6a3d3faad5b421dfe01fd9bf1',
      jsonEncode(message),
    );

    // _workoutRewardsTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
    //   final message = {
    //     'beatzcoin_secret': 'JEFFREY_EPSTEIN_DID_NOT_KILL_HIMSELF',
    //     'bpm': 181,
    //   };
    //   _nostrService.sendEncryptedDM(
    //     '4076e3081853a23cb5b826b0501a93d3c74a4db6a3d3faad5b421dfe01fd9bf1',
    //     jsonEncode(message),
    //   );
    // });
  }

  void _formatWorkoutTime() {
    end.value = DateTime.now();
    final diff = end.value.difference(start.value);
    final hh = (diff.inHours).toString().padLeft(2, '0');
    final mm = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (diff.inSeconds % 60).toString().padLeft(2, '0');
    duration.value = '$hh:$mm:$ss';
  }

  void stopWorkout() {
    Wakelock.disable();
    running.value = false;
    _workoutDurationTimer.cancel();
    _workoutRewardsTimer.cancel();
  }
}

class WorkoutBpmEventContent {
  String secret;
  int bpm;

  WorkoutBpmEventContent(this.secret, this.bpm);

  Map<String, dynamic> toJSON() {
    return {
      'beatzcoin_secret': secret,
      'bpm': bpm,
    };
  }
}
