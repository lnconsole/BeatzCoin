import 'package:beatcoin/services/polar.dart';
import 'package:beatcoin/services/rewards.dart';
import 'package:beatcoin/services/workout.dart';
import 'package:beatcoin/widgets/gauge_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WorkoutPage extends StatelessWidget {
  const WorkoutPage({super.key});

  Color? _chartColor(
    int bpm,
    WorkoutService workoutService,
  ) {
    if (bpm >= workoutService.heartRateThreshold) {
      return const Color.fromARGB(255, 255, 238, 56);
    }

    final value = bpm / workoutService.heartRateThreshold;

    return Color.lerp(
      const Color.fromARGB(255, 146, 255, 87),
      const Color.fromARGB(255, 255, 87, 87),
      value,
    );
  }

  @override
  Widget build(BuildContext context) {
    final polarController = Get.find<PolarService>();
    final workoutService = Get.find<WorkoutService>();
    final rewardService = Get.find<RewardsService>();

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Obx(
            () => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
              ),
              child: Card(
                child: buildDistanceTrackerExample(
                  polarController.heartRate.value,
                  _chartColor(
                    polarController.heartRate.value,
                    workoutService,
                  ),
                ),
              ),
            ),
          ),
          Obx(
            () => Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
              ),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.bolt_outlined,
                    ),
                    title: Text(
                      rewardService.satsEarnedFormatted.value,
                      style: const TextStyle(
                        fontSize: 24,
                      ),
                    ),
                    subtitle: const Text('sats earned today'),
                  ),
                ),
              ),
            ),
          ),
          Obx(
            () => Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
              ),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.timer_outlined,
                    ),
                    title: Text(
                      workoutService.duration.string,
                      style: const TextStyle(
                        fontSize: 24,
                      ),
                    ),
                    subtitle: const Text('workout duration'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
