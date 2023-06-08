import 'package:beatcoin/polar/polar.dart';
import 'package:beatcoin/widgets/gauge_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WorkoutPage extends StatelessWidget {
  WorkoutPage({super.key});

  PolarController polarController = Get.find();

  @override
  Widget build(BuildContext context) {
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
