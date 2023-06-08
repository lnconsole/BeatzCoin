import 'package:get/state_manager.dart';
import 'package:polar/polar.dart';

class PolarController extends GetxController {
  final polar = Polar();
  late final PolarDeviceInfo selectedDevice;
  final devices = <PolarDeviceInfo>[].obs;
  RxInt heartRate = 0.obs;
  RxBool isDeviceConnected = false.obs;
  RxString connectedDeviceId = ''.obs;

  PolarController() {
    polar.batteryLevel.listen((e) => print('Battery: ${e.level}'));
    polar.deviceConnecting.listen((_) => print('Device connecting'));
    polar.deviceConnected.listen((_) => print('Device connected'));
    polar.deviceDisconnected.listen((_) => print('Device disconnected'));
  }

  void searchDevices() async {
    polar.requestPermissions();
    polar.searchForDevice().listen((e) {
      devices.add(e);
    });
  }

  void connect(String deviceId) async {
    await polar.disconnectFromDevice(deviceId);
    await polar.connectToDevice(deviceId);

    isDeviceConnected.value = true;
    connectedDeviceId.value = deviceId;

    await polar.sdkFeatureReady.firstWhere(
      (e) =>
          e.identifier == deviceId &&
          e.feature == PolarSdkFeature.onlineStreaming,
    );
    final availabletypes =
        await polar.getAvailableOnlineStreamDataTypes(deviceId);

    print('available types: $availabletypes');

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
    isDeviceConnected.value = false;
    connectedDeviceId.value = '';
  }
}
