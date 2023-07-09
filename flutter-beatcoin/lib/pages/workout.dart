import 'package:beatcoin/services/polar.dart';
import 'package:beatcoin/services/rewards.dart';
import 'package:beatcoin/services/workout.dart';
import 'package:beatcoin/widgets/gauge_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animate_gradient/animate_gradient.dart';

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

  late AnimationController _animationController;

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1500,
      ),
    );
    ever(rewardService.satsEarnedFormatted, (_) {
      final animationFuture = _animationController.forward();
      animationFuture.whenCompleteOrCancel(() {
        _animationController.reverse();
      });
    });
    super.initState();
  }

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

  Widget _workoutColumnWidgets() {
    return GetX<WorkoutService>(
      builder: (controller) {
        if (workoutService.readyToWorkout) {
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
                    child: AnimateGradient(
                      controller: _animationController,
                      primaryColors: const [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.transparent,
                      ],
                      secondaryColors: [
                        Colors.yellow,
                        Colors.yellow[300]!,
                        Colors.yellow[700]!,
                      ],
                      primaryBegin: Alignment.bottomLeft,
                      primaryEnd: Alignment.topRight,
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

        return const Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'You need to setup some things before picking up some Sats!'),
              Card(
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text(
                    'Go to the Profile page and login with your Nostr Profile.',
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: Icon(Icons.alternate_email),
                  title: Text(
                    'Make sure your Nostr Profile has a Lightning Address setup. You can do this in the profile page as well.',
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: Icon(Icons.heart_broken_outlined),
                  title: Text(
                    'Connect your polar device using the connect button above.',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
          _workoutColumnWidgets(),
        ],
      ),
    );
  }
}
