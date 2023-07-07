import 'package:beatcoin/services/rewards.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final rewardService = Get.find<RewardsService>();

    return SingleChildScrollView(
      child: Obx(
        () => Column(
          mainAxisSize: MainAxisSize.max,
          children: rewardService.workoutHistory
              .map(
                (e) => Card(
                  child: ListTile(
                    title: Text(
                      'Sats Earned: ${e.satsEarned}',
                    ),
                    subtitle: Text(
                      DateFormat('yyyy-MM-dd').format(e.date),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
