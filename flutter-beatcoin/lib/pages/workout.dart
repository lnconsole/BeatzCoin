import 'package:beatcoin/polar/polar.dart';
import 'package:beatcoin/widgets/gauge_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WorkoutPage extends StatelessWidget {
  const WorkoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    PolarController polarController = Get.find();

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Text('Workout View'),
          buildDistanceTrackerExample(138),
        ],
      ),
    );
  }
}
