import 'package:beatcoin/services/polar.dart';
import 'package:beatcoin/services/rewards.dart';
import 'package:beatcoin/services/workout.dart';
import 'package:beatcoin/widgets/gauge_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WorkoutPage extends StatelessWidget {
  const WorkoutPage({super.key});

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
                    leading: Icon(
                      Icons.bolt_outlined,
                    ),
                    title: Text(
                      rewardService.satsEarnedFormatted.value,
                      style: TextStyle(
                        fontSize: 24,
                      ),
                    ),
                    subtitle: Text('sats earned'),
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
                    leading: Icon(
                      Icons.timer_outlined,
                    ),
                    title: Text(
                      workoutService.duration.string,
                      style: TextStyle(
                        fontSize: 24,
                      ),
                    ),
                    subtitle: Text('workout duration'),
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
