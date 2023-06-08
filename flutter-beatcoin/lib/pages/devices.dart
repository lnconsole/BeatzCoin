import 'package:beatcoin/polar/polar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    PolarController polarController = Get.find();

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Center(
            child: FilledButton.icon(
              onPressed: () {
                polarController.searchDevices();
              },
              icon: Icon(
                Icons.search,
              ),
              label: Text('Scan for Devices'),
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
                          polarController.connectedDeviceId == device.deviceId
                              ? Icons.heart_broken
                              : Icons.heart_broken_outlined,
                          color: Colors.red[400],
                        ),
                        title: Text(device.name),
                        subtitle: Text(device.address),
                        trailing: FilledButton(
                          onPressed: () {
                            polarController.connectedDeviceId == device.deviceId
                                ? polarController.disconnect(device.deviceId)
                                : polarController.connect(device.deviceId);
                          },
                          child: Text(
                            polarController.connectedDeviceId == device.deviceId
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
