import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lighthouse_pm/lighthouseProvider/backEnd/fake/FakeBluetoothDevice.dart';
import 'package:lighthouse_pm/lighthouseProvider/deviceProviders/LighthouseV2DeviceProvider.dart';
import 'package:lighthouse_pm/lighthouseProvider/deviceProviders/ViveBaseStationDeviceProvider.dart';
import 'package:lighthouse_pm/platformSpecific/mobile/LocalPlatform.dart';

void main() {
  LocalPlatform.overridePlatform = PlatformOverride.android;

  test('Should create FakeBluetoothDevice', () async {
    final device = FakeBluetoothDevice([], 0, 'TEST-DEVICE');

    final services = await device.discoverServices();

    expect(device.name, 'TEST-DEVICE');
    expect(device.id.toString(), '00:00:00:00:00:00');
    expect(services.length, 1);
    expect(services[0].characteristics, []);
    expect(services[0].uuid.toString(), "00000000-0000-0000-0000-000000000001");
  });

  test('Should create FakeLighthouseV2Device', () async {
    final device = FakeLighthouseV2Device(0xFF, 0);

    final services = await device.discoverServices();

    expect(device.name, 'LHB-000000FF');
    expect(device.id.toString(), '00:00:00:00:00:00');
    expect(services.length, 1);
  });

  test('FakeLighthouseV2Device should contain characteristics', () async {
    final device = FakeLighthouseV2Device(0xFF, 0);

    final services = await device.discoverServices();

    expect(device.id.toString(), '00:00:00:00:00:00');
    expect(services.length, 1);
    final characteristics = services[0].characteristics;

    final provider = LighthouseV2DeviceProvider.instance;
    final expectedCharacteristics = provider.characteristics;

    expect(characteristics.length, expectedCharacteristics.length,
        reason:
            "should have the same amount of characteristics as the expected "
            "amount of characteristics.");

    for (final characteristic in expectedCharacteristics) {
      final index = characteristics
          .indexWhere((element) => element.uuid == characteristic);
      expect(index, isNot(-1),
          reason: 'Should have "${characteristic.toString()}" characteristic');
    }
  });

  test('Should create FakeViveBaseStationDevice', () async {
    final device = FakeViveBaseStationDevice(0xFF, 0);

    final services = await device.discoverServices();

    expect(device.name, 'HTC BS 0000FF');
    expect(device.id.toString(), '00:00:00:00:00:00');
    expect(services.length, 1);
  });

  test('FakeViveBaseStationDevice should contain characteristics', () async {
    final device = FakeViveBaseStationDevice(0xFF, 0);

    final services = await device.discoverServices();

    expect(device.id.toString(), '00:00:00:00:00:00');
    expect(services.length, 1);
    final characteristics = services[0].characteristics;

    final provider = ViveBaseStationDeviceProvider.instance;
    final expectedCharacteristics = provider.characteristics;

    expect(characteristics.length, expectedCharacteristics.length,
        reason:
            "should have the same amount of characteristics as the expected "
            "amount of characteristics.");

    for (final characteristic in expectedCharacteristics) {
      final index = characteristics
          .indexWhere((element) => element.uuid == characteristic);
      expect(index, isNot(-1),
          reason: 'Should have "${characteristic.toString()}" characteristic');
    }
  });

  test(
      'Should be able to go from off to on, FakeLighthouseV2PowerCharacteristic',
      () async {
    final power = FakeLighthouseV2PowerCharacteristic();

    // First turn the device off
    power.write([0x00]);
    expect(await power.read(), [0x00]);

    // Now boot it
    power.write([0x01]);

    // Get the next states in order. This should take around 10ms + 1200ms = 1210ms = 1.21s. But just in case I added a timeout.
    final first = await getNextPowerState(power, 0x00, Duration(seconds: 1));
    final second = await getNextPowerState(power, first, Duration(seconds: 1));
    final third = await getNextPowerState(power, second, Duration(seconds: 3));

    expect(first, 0x01, reason: "Should first switch to on command");
    expect(second, 0x09, reason: "Should then switch to booting");
    expect(third, 0x0b, reason: "Should then switch to on");
  });

  test(
      'Should be able to go from off to standby, FakeLighthouseV2PowerCharacteristic',
      () async {
    final power = FakeLighthouseV2PowerCharacteristic();

    // First turn the device off
    power.write([0x00]);
    expect(await power.read(), [0x00]);

    // Now set it to standby
    power.write([0x02]);

    // Get the next states in order. This should take around 10ms + 1200ms = 1210ms = 1.21s. But just in case I added a timeout.
    final first = await getNextPowerState(power, 0x00, Duration(seconds: 1));
    final second = await getNextPowerState(power, first, Duration(seconds: 1));
    final third = await getNextPowerState(power, second, Duration(seconds: 3));

    expect(first, 0x02, reason: "Should first switch to standby command");
    expect(second, 0x09, reason: "Should then switch to booting");
    expect(third, 0x02, reason: "Should then switch to standby");
  });

  test(
      'Should be able to go from on to sleep, FakeLighthouseV2PowerCharacteristic',
      () async {
    final power = FakeLighthouseV2PowerCharacteristic();

    // First turn it off to get a consistent state.
    power.write([0x00]);
    expect(await power.read(), [0x00]);

    // First turn the device on
    power.write([0x01]);
    // Get the next states in order. This should take around 10ms + 1200ms = 1210ms = 1.21s. But just in case I added a timeout.
    final first = await getNextPowerState(power, 0x00, Duration(seconds: 1));
    final second = await getNextPowerState(power, first, Duration(seconds: 1));
    final third = await getNextPowerState(power, second, Duration(seconds: 3));
    expect(first, 0x01, reason: "Should first switch to on command");
    expect(second, 0x09, reason: "Should then switch to booting");
    expect(third, 0x0b, reason: "Should then switch to on");

    // Now set it to sleep
    power.write([0x00]);
    expect(await power.readUint32(), 0x00,
        reason: "Should directly switch to sleep");
  });

  test(
      'Should be able to go from standby to sleep, FakeLighthouseV2PowerCharacteristic',
      () async {
    final power = FakeLighthouseV2PowerCharacteristic();

    // First turn it off to get a consistent state.
    power.write([0x00]);
    expect(await power.read(), [0x00]);

    // Now set it to standby
    power.write([0x02]);
    // Get the next states in order. This should take around 10ms + 1200ms = 1210ms = 1.21s. But just in case I added a timeout.
    final first = await getNextPowerState(power, 0x00, Duration(seconds: 1));
    final second = await getNextPowerState(power, first, Duration(seconds: 1));
    final third = await getNextPowerState(power, second, Duration(seconds: 3));
    expect(first, 0x02, reason: "Should first switch to standby command");
    expect(second, 0x09, reason: "Should then switch to booting");
    expect(third, 0x02, reason: "Should then switch to standby");

    // Now set it to sleep
    power.write([0x00]);
    expect(await power.readUint32(), 0x00,
        reason: "Should directly switch to standby");
  });

  test(
      'Should be able to go from standby to on, FakeLighthouseV2PowerCharacteristic',
      () async {
    final power = FakeLighthouseV2PowerCharacteristic();

    // First turn it off to get a consistent state.
    power.write([0x00]);
    expect(await power.read(), [0x00]);

    // Now set it to standby
    power.write([0x02]);
    // Get the next states in order. This should take around 10ms + 1200ms = 1210ms = 1.21s. But just in case I added a timeout.
    final first = await getNextPowerState(power, 0x00, Duration(seconds: 1));
    final second = await getNextPowerState(power, first, Duration(seconds: 1));
    final third = await getNextPowerState(power, second, Duration(seconds: 3));
    expect(first, 0x02, reason: "Should first switch to standby command");
    expect(second, 0x09, reason: "Should then switch to booting");
    expect(third, 0x02, reason: "Should then switch to standby");

    // Now set it to sleep
    power.write([0x01]);
    expect(await power.readUint32(), 0x0b,
        reason: "Should directly switch to on");
  });

  test(
      'Should be able to go from on to standby, FakeLighthouseV2PowerCharacteristic',
      () async {
    final power = FakeLighthouseV2PowerCharacteristic();

    // First turn it off to get a consistent state.
    power.write([0x00]);
    expect(await power.read(), [0x00]);

    // First turn the device on
    power.write([0x01]);
    // Get the next states in order. This should take around 10ms + 1200ms = 1210ms = 1.21s. But just in case I added a timeout.
    final first = await getNextPowerState(power, 0x00, Duration(seconds: 1));
    final second = await getNextPowerState(power, first, Duration(seconds: 1));
    final third = await getNextPowerState(power, second, Duration(seconds: 3));
    expect(first, 0x01, reason: "Should first switch to on command");
    expect(second, 0x09, reason: "Should then switch to booting");
    expect(third, 0x0b, reason: "Should then switch to on");

    // Now set it to sleep
    power.write([0x02]);
    expect(await power.readUint32(), 0x02,
        reason: "Should directly switch to standby");
  });

  test(
      'Should not change state with unrecognized command, FakeLighthouseV2PowerCharacteristic',
      () async {
    final power = FakeLighthouseV2PowerCharacteristic();

    // First turn it off to get a consistent state.
    power.write([0x00]);
    expect(await power.read(), [0x00]);

    // Change the state to something unrecognized
    power.write([0xFF]);
    // Should not change within a second
    final end = DateTime.now().add(Duration(seconds: 1)).millisecondsSinceEpoch;
    while (DateTime.now().millisecondsSinceEpoch < end) {
      expect(await power.readUint32(), 0x00,
          reason: "Power state should stay off.");
      await Future.delayed(Duration(milliseconds: 1));
    }
  });

  test(
      'Should not change state with wrong command size, FakeLighthouseV2PowerCharacteristic',
      () async {
    final power = FakeLighthouseV2PowerCharacteristic();

    // First turn it off to get a consistent state.
    power.write([0x00]);
    expect(await power.read(), [0x00]);

    // Change the state with too many bytes
    power.write([0x01, 0x00]);
    // Should not change within a second
    final end = DateTime.now().add(Duration(seconds: 1)).millisecondsSinceEpoch;
    while (DateTime.now().millisecondsSinceEpoch < end) {
      expect(await power.readUint32(), 0x00,
          reason: "Power state should stay off.");
      await Future.delayed(Duration(milliseconds: 1));
    }

    // Change the state with not enough bytes
    power.write([]);
    // Should not change within a second
    final end2 =
        DateTime.now().add(Duration(seconds: 1)).millisecondsSinceEpoch;
    while (DateTime.now().millisecondsSinceEpoch < end2) {
      expect(await power.readUint32(), 0x00,
          reason: "Power state should stay off.");
      await Future.delayed(Duration(milliseconds: 1));
    }
  });

  test('Setting identify should boot a FakeLighthouseV2Device', () async {
    final power = FakeLighthouseV2PowerCharacteristic();
    final identify = FakeLighthouseV2IdentifyCharacteristic(power);

    // First turn the device off
    power.write([0x00]);
    expect(await power.read(), [0x00]);

    //Now identify
    identify.write([0x00]);

    // Get the next states in order. This should take around 10ms + 1200ms = 1210ms = 1.21s. But just in case I added a timeout.
    final first = await getNextPowerState(power, 0x00, Duration(seconds: 1));
    final second = await getNextPowerState(power, first, Duration(seconds: 1));
    final third = await getNextPowerState(power, second, Duration(seconds: 3));

    expect(first, 0x01, reason: "Should first switch to on command");
    expect(second, 0x09, reason: "Should then switch to booting");
    expect(third, 0x0b, reason: "Should then switch to on");
  });

  test(
      'Setting identify should not boot with a wrong command size, FakeLighthouseV2Device',
      () async {
    final power = FakeLighthouseV2PowerCharacteristic();
    final identify = FakeLighthouseV2IdentifyCharacteristic(power);

    // First turn the device off
    power.write([0x00]);
    expect(await power.read(), [0x00]);

    //Now identify with too many bytes
    identify.write([0x00, 0x00]);
    // Should not change within a second
    final end = DateTime.now().add(Duration(seconds: 1)).millisecondsSinceEpoch;
    while (DateTime.now().millisecondsSinceEpoch < end) {
      expect(await power.readUint32(), 0x00,
          reason: "Power state should stay off.");
      await Future.delayed(Duration(milliseconds: 1));
    }

    //Now identify with not enough
    identify.write([]);
    // Should not change within a second
    final end2 =
        DateTime.now().add(Duration(seconds: 1)).millisecondsSinceEpoch;
    while (DateTime.now().millisecondsSinceEpoch < end2) {
      expect(await power.readUint32(), 0x00,
          reason: "Power state should stay off.");
      await Future.delayed(Duration(milliseconds: 1));
    }
  });

  test(
      'Setting identify should not boot with a wrong command, FakeLighthouseV2Device',
      () async {
    final power = FakeLighthouseV2PowerCharacteristic();
    final identify = FakeLighthouseV2IdentifyCharacteristic(power);

    // First turn the device off
    power.write([0x00]);
    expect(await power.read(), [0x00]);

    //Now send an incorrect command.
    identify.write([0xFF]);
    // Should not change within a second
    final end = DateTime.now().add(Duration(seconds: 1)).millisecondsSinceEpoch;
    while (DateTime.now().millisecondsSinceEpoch < end) {
      expect(await power.readUint32(), 0x00,
          reason: "Power state should stay off.");
      await Future.delayed(Duration(milliseconds: 1));
    }
  });
}

Future<int> getNextPowerState(FakeLighthouseV2PowerCharacteristic power,
    int previous, Duration timeout) async {
  final beforeTime = DateTime.now().add(timeout).millisecondsSinceEpoch;
  int? currentState;
  while (true) {
    currentState = await power.readUint32();
    // Give the other thread time to finish.
    if (currentState != previous) {
      break;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now > beforeTime) {
      print("Now: $now, before: $beforeTime, diff = ${beforeTime - now}");
      throw TimeoutException('Could not get a new value within $timeout');
    }
    await Future.delayed(Duration(microseconds: 10));
  }

  return currentState;
}
