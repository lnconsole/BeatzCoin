import 'package:get/state_manager.dart';
import 'package:polar/polar.dart';
import 'package:bluetooth_enable_fork/bluetooth_enable_fork.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PolarService extends GetxService {
  final polar = Polar();
  late final PolarDeviceInfo selectedDevice;
  final devices = <PolarDeviceInfo>[].obs;
  RxInt heartRate = 0.obs;
  RxBool isDeviceConnected = false.obs;
  RxString connectedDeviceId = ''.obs;
  RxInt batteryLevel = 0.obs;
  final _prefsDeviceIdKey = 'LAST_CONNECTED_DEVICE_ID';
  final SharedPreferences _prefs;

  PolarService(
    this._prefs,
  ) {
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

  Future searchDevices() async {
    await polar.requestPermissions();
    final enableBluetooth = await BluetoothEnable.enableBluetooth;
    if (enableBluetooth == "true") {
      devices.clear();
      polar.searchForDevice().listen((e) {
        devices.add(e);
        final lastConnectedDeviceId = _prefs.getString(_prefsDeviceIdKey);
        if (lastConnectedDeviceId != null &&
            e.deviceId == lastConnectedDeviceId) {
          connect(e.deviceId);
        }
      });
    }
  }

  void connect(String deviceId) async {
    await polar.disconnectFromDevice(deviceId);
    await polar.connectToDevice(deviceId);

    await _prefs.setString(_prefsDeviceIdKey, deviceId);

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
