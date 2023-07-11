import 'package:beatcoin/services/nostr.dart';
import 'package:beatcoin/services/polar.dart';
import 'package:beatcoin/services/rewards.dart';
import 'package:beatcoin/services/workout.dart';
import 'package:beatcoin/widgets/gauge_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage>
    with SingleTickerProviderStateMixin {
  final polarController = Get.find<PolarService>();
  final workoutService = Get.find<WorkoutService>();
  final rewardService = Get.find<RewardsService>();

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

  Widget _readyToStartWidgets() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('You are ready to sweat for some sats'),
        ),
        FilledButton(
          onPressed: () {
            workoutService.startWorkout();
          },
          style: ButtonStyle(
            shape: MaterialStateProperty.all(const CircleBorder()),
            padding: MaterialStateProperty.all(const EdgeInsets.all(20)),
          ),
          child: const Icon(
            Icons.play_arrow,
            size: 50,
          ),
        ),
      ],
    );
  }

  Widget _notReadyToStartWidgets(
    bool loggedIn,
    bool hasLud16,
    bool heartRateConnected,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
              'You need to setup some things before picking up some Sats!'),
          Card(
            child: ListTile(
              leading: Icon(
                loggedIn
                    ? Icons.check_box_outlined
                    : Icons.check_box_outline_blank_outlined,
                color: loggedIn ? Colors.green[400] : Colors.grey,
              ),
              title: const Text(
                'Go to the Profile page and login with your Nostr Profile.',
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(
                hasLud16
                    ? Icons.check_box_outlined
                    : Icons.check_box_outline_blank_outlined,
                color: hasLud16 ? Colors.green[400] : Colors.grey,
              ),
              title: const Text(
                'Make sure your Nostr Profile has a Lightning Address setup. You can do this in the profile page as well.',
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(
                heartRateConnected
                    ? Icons.check_box_outlined
                    : Icons.check_box_outline_blank_outlined,
                color: heartRateConnected ? Colors.green[400] : Colors.grey,
              ),
              title: const Text(
                'Connect your polar device using the connect button above.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _workoutColumnWidgets() {
    return Column(
      children: [
        Obx(
          () => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
            ),
            child: Card(
              child: buildGaugeChart(
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
                    color: Color.fromARGB(255, 255, 234, 0),
                    size: 40,
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
                    size: 40,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final nostrService = Get.find<NostrService>();
    final polarService = Get.find<PolarService>();

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            alignment: Alignment.centerLeft,
            child: const Text(
              'Drop the Beatz',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24.0,
              ),
            ),
          ),
          GetX<WorkoutService>(
            builder: (controller) {
              if (!controller.readyToWorkout) {
                return _notReadyToStartWidgets(
                  nostrService.loggedIn.value,
                  nostrService.isProfileReady,
                  polarService.isDeviceConnected.value,
                );
              } else if (controller.readyToWorkout &&
                  !controller.running.value) {
                return _readyToStartWidgets();
              }

              return _workoutColumnWidgets();
            },
          ),
        ],
      ),
    );
  }
}
