import 'package:get/get.dart';

class RewardsService extends GetxService {
  final satsEarnedFormatted = '0'.obs;
  int _satsEarned = 0;

  void addReward(int sats) {
    if (sats <= 0) {
      return;
    }

    _satsEarned += sats;
    satsEarnedFormatted.value = _satsEarned.toString();
  }
}
