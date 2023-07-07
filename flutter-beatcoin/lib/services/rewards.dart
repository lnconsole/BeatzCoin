import 'package:beatcoin/services/models.dart';
import 'package:get/get.dart';

class RewardsService extends GetxService {
  final satsEarnedFormatted = '0'.obs;
  int _satsEarned = 0;
  final workoutHistory = <WorkoutDetails>[].obs;

  void setSatsEarned(int sats) {
    if (sats < 0) {
      return;
    }

    _satsEarned = sats;
    satsEarnedFormatted.value = _satsEarned.toString();
  }

  void setWorkoutHistory(List<WorkoutDetails> workout) {
    if (workout.isNotEmpty) {
      workout.sort((a, b) => a.date.compareTo(b.date));
      final now = DateTime.now().toUtc();
      final first = workout.first.date;

      if (first.year == now.year &&
          first.month == now.month &&
          first.day == now.day) {
        _satsEarned = workout.first.satsEarned;
        satsEarnedFormatted.value = _satsEarned.toString();
      }

      workoutHistory.value = workout;
    }
  }
}
