import 'package:get/state_manager.dart';
import 'package:polar/polar.dart';
import 'package:bluetooth_enable_fork/bluetooth_enable_fork.dart';

class PolarService extends GetxService {
  final polar = Polar();
  late final PolarDeviceInfo selectedDevice;
  final devices = <PolarDeviceInfo>[].obs;
  RxInt heartRate = 0.obs;
  RxBool isDeviceConnected = false.obs;
  RxString connectedDeviceId = ''.obs;
  RxInt batteryLevel = 0.obs;

  PolarService() {
    polar.batteryLevel.listen((e) => batteryLevel.value = e.level);
    polar.deviceConnected.listen((e) {
      isDeviceConnected.value = true;
      connectedDeviceId.value = e.deviceId;
    });
    polar.deviceDisconnected.listen((_) {
      isDeviceConnected.value = false;
      connectedDeviceId.value = '';
    });
  }

  void searchDevices() async {
    final enableBluetooth = await BluetoothEnable.enableBluetooth;
    if (enableBluetooth == "true") {
      print('ble enabled');
      polar.requestPermissions();
      polar.searchForDevice().listen((e) {
        devices.add(e);
      });
    } else {
      print('ble not enabled');
    }
  }

  void connect(String deviceId) async {
    await polar.disconnectFromDevice(deviceId);
    await polar.connectToDevice(deviceId);

    await polar.sdkFeatureReady.firstWhere(
      (e) =>
          e.identifier == deviceId &&
          e.feature == PolarSdkFeature.onlineStreaming,
    );
    final availabletypes =
        await polar.getAvailableOnlineStreamDataTypes(deviceId);

    if (availabletypes.contains(PolarDataType.hr)) {
      polar.startHrStreaming(deviceId).listen((e) {
        if (e.samples.isNotEmpty) {
          heartRate.value = e.samples[0].hr;
        }
      });
    }
  }

  void disconnect(String deviceId) async {
    await polar.disconnectFromDevice(deviceId);
  }
}
