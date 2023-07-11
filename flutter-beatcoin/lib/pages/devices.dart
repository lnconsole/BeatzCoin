import 'package:beatcoin/services/polar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    PolarService polarController = Get.find();

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            alignment: Alignment.centerLeft,
            child: const Text(
              'Devices',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24.0,
              ),
            ),
          ),
          Obx(
            () => Column(
              mainAxisSize: MainAxisSize.min,
              children: polarController.devices
                  .map(
                    (device) => Card(
                      child: ListTile(
                        leading: Icon(
                          polarController.connectedDeviceId.value ==
                                  device.deviceId
                              ? Icons.heart_broken
                              : Icons.heart_broken_outlined,
                          color: Colors.red[400],
                        ),
                        title: Text(device.name),
                        subtitle: Text(device.address),
                        trailing: FilledButton(
                          onPressed: () {
                            polarController.connectedDeviceId.value ==
                                    device.deviceId
                                ? polarController.disconnect(device.deviceId)
                                : polarController.connect(device.deviceId);
                          },
                          child: Text(
                            polarController.connectedDeviceId.value ==
                                    device.deviceId
                                ? 'disconnect'
                                : 'connect',
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
