import 'package:beatcoin/polar/polar.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:get/state_manager.dart';
import 'package:polar/polar.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const MyApp());
}

/// Example app
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final polarController = PolarController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('BeatCoin'),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  polarController.searchDevices();
                },
              ),
            ],
          ),
          body: Center(
            child: Obx(
              () => ListView(
                children: polarController.devices
                    .map(
                      (e) => Card(
                        child: ListTile(
                          leading: Text(e.name),
                          title: Row(
                            children: [
                              Icon(
                                Icons.monitor_heart,
                                color: Colors.red[300],
                              ),
                              Obx(
                                () => Text(
                                  polarController.heartRate.string,
                                ),
                              ),
                            ],
                          ),
                          trailing: FilledButton(
                            onPressed: () {
                              if (polarController.isDeviceConnected.isTrue) {
                                polarController.disconnect(e.deviceId);
                              } else {
                                polarController.connect(e.deviceId);
                              }
                            },
                            child: Obx(
                              () => Text(
                                polarController.isDeviceConnected.isTrue
                                    ? 'disconnect'
                                    : 'connect',
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          )),
    );
  }
}
