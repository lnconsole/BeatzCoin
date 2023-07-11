import 'package:beatcoin/services/debug.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DebugPage extends StatelessWidget {
  const DebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    final debugService = Get.find<DebugService>();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Debug',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24.0,
                ),
              ),
            ),
            Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...debugService.messages
                      .map(
                        (msg) => Text(
                          msg,
                          style: const TextStyle(
                            color: Color(0xFFFFB871),
                          ),
                        ),
                      )
                      .toList(),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
