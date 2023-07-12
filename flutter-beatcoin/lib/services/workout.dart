import 'dart:async';
import 'dart:convert';
import 'package:beatcoin/services/polar.dart';
import 'package:beatcoin/services/nostr.dart';
import 'package:beatcoin/env.dart';
import 'package:get/get.dart';

class WorkoutService extends GetxService {
  final heartRateThreshold = 160;
  final start = DateTime.now().obs;
  final end = DateTime.now().obs;
  final duration = '00:00:00'.obs;
  final running = false.obs;
  late Timer _workoutDurationTimer;
  late Timer _workoutRewardsTimer;
  final NostrService _nostrService;
  final PolarService _polarService;
  final _oneSecondTimerDuration = const Duration(seconds: 1);
  final _workoutRewardTimerDuration = const Duration(seconds: 5);

  bool get readyToWorkout =>
      _polarService.isDeviceConnected.value && _nostrService.isProfileReady;

  WorkoutService(
    this._nostrService,
    this._polarService,
  );

  void startWorkout() {
    running.value = true;
    start.value = DateTime.now();

    _workoutDurationTimer = Timer.periodic(_oneSecondTimerDuration, (timer) {
      _formatWorkoutTime();
    });

    _workoutRewardsTimer = Timer.periodic(_workoutRewardTimerDuration, (timer) {
      if (_polarService.heartRate.value >= heartRateThreshold) {
        final message = WorkoutBpmEventContent(
          Env.serverSecret,
          _polarService.heartRate.value,
        );
        _nostrService.sendEncryptedDM(
          Env.serverPubkey,
          jsonEncode(message.toJSON()),
        );
      }

      // CODE FOR TESTING ONLY
      final message = WorkoutBpmEventContent(
        Env.serverSecret,
        180,
      );
      _nostrService.sendEncryptedDM(
        Env.serverPubkey,
        jsonEncode(message.toJSON()),
      );
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
