import 'dart:async';
import 'dart:convert';
import 'package:beatcoin/services/polar.dart';
import 'package:wakelock/wakelock.dart';
import 'package:beatcoin/services/nostr.dart';
import 'package:beatcoin/env.dart';
import 'package:get/get.dart';

class WorkoutService extends GetxService {
  final _heartRateThreshold = 160;
  final start = DateTime.now().obs;
  final end = DateTime.now().obs;
  final duration = '00:00:00'.obs;
  final running = false.obs;
  late Timer _workoutDurationTimer;
  late Timer _workoutRewardsTimer;
  final NostrService _nostrService;
  final PolarService _polarService;

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

    _workoutRewardsTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_polarService.heartRate.value >= _heartRateThreshold) {
        final message = WorkoutBpmEventContent(
          Env.serverSecret,
          _polarService.heartRate.value,
        );
        _nostrService.sendEncryptedDM(
          Env.serverPubkey,
          jsonEncode(message.toJSON()),
        );
      }
    });
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
