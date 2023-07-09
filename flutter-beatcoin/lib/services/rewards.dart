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

    _setSatsEarned(sats);
  }

  void setWorkoutHistory(List<WorkoutDetails> workout) {
    if (workout.isNotEmpty) {
      workout.sort((a, b) => b.date.compareTo(a.date));
      final now = DateTime.now().toUtc();
      final first = workout.first.date;

      if (first.year == now.year &&
          first.month == now.month &&
          first.day == now.day) {
        _setSatsEarned(workout.first.satsEarned);
      }

      workoutHistory.value = workout;
    }
  }

  void clearWorkoutHistory() {
    workoutHistory.value = [];
    _setSatsEarned(0);
  }

  void _setSatsEarned(int satsEarned) {
    _satsEarned = satsEarned;
    satsEarnedFormatted.value = _satsEarned.toString();
  }
}
