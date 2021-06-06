import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_web_bluetooth/flutter_web_bluetooth.dart';
import 'package:lighthouse_pm/lighthouseProvider/LighthousePowerState.dart';
import 'package:lighthouse_pm/lighthouseProvider/backEnd/fake/FakeDeviceIdentifier.dart';
import 'package:lighthouse_pm/lighthouseProvider/devices/LighthouseV2Device.dart';
import 'package:lighthouse_pm/platformSpecific/shared/LocalPlatform.dart';

import '../../ble/BluetoothCharacteristic.dart';
import '../../ble/BluetoothDevice.dart';
import '../../ble/BluetoothService.dart';
import '../../ble/DeviceIdentifier.dart';
import '../../ble/Guid.dart';

class FakeBluetoothDevice extends LHBluetoothDevice {
  final LHDeviceIdentifier deviceIdentifier;
  final SimpleBluetoothService service;
  final String _name;

  FakeBluetoothDevice(
      List<LHBluetoothCharacteristic> characteristics, int id, String name)
      : service = SimpleBluetoothService(characteristics),
        deviceIdentifier = _generateIdentifier(id),
        _name = name;

  static LHDeviceIdentifier _generateIdentifier(int id) {
    if (LocalPlatform.isWeb) {
      return LHDeviceIdentifier(
          'a${FakeDeviceIdentifier.generateDeviceIdentifier(id).toString().substring(1)}');
    }
    return FakeDeviceIdentifier.generateDeviceIdentifier(id);
  }

  @override
  Future<void> connect({Duration? timeout}) async {
    // do nothing
  }

  @override
  Future<void> disconnect() async {}

  @override
  Future<List<LHBluetoothService>> discoverServices() async {
    return [service];
  }

  @override
  LHDeviceIdentifier get id => deviceIdentifier;

  @override
  String get name => _name;

  @override
  Stream<LHBluetoothDeviceState> get state =>
      Stream.value(LHBluetoothDeviceState.connected);
}

class FakeLighthouseV2Device extends FakeBluetoothDevice {
  FakeLighthouseV2Device(int deviceName, int deviceId)
      : super([
          _FakeFirmwareCharacteristic(),
          _FakeModelNumberCharacteristic(),
          _FakeSerialNumberCharacteristic(),
          _FakeHardwareRevisionCharacteristic(),
          _FakeManufacturerNameCharacteristic(),
          _FakeChannelCharacteristic(),
          ..._getPowerAndIdentifyCharacteristic(),
        ], deviceId, _getNameFromInt(deviceName));

  static String _getNameFromInt(int deviceName) {
    return 'LHB-000000${deviceName.toRadixString(16).padLeft(2, '0').toUpperCase()}';
  }

  static List<FakeReadWriteCharacteristic>
      _getPowerAndIdentifyCharacteristic() {
    final powerCharacteristic = FakeLighthouseV2PowerCharacteristic();
    return [
      powerCharacteristic,
      FakeLighthouseV2IdentifyCharacteristic(powerCharacteristic)
    ];
  }
}

class FakeViveBaseStationDevice extends FakeBluetoothDevice {
  FakeViveBaseStationDevice(int deviceName, int deviceId)
      : super([
          _FakeFirmwareCharacteristic(),
          _FakeModelNumberCharacteristic(),
          _FakeSerialNumberCharacteristic(),
          _FakeHardwareRevisionCharacteristic(),
          _FakeManufacturerNameCharacteristic(),
          _FakeViveBaseStationCharacteristic()
        ], deviceId, _getNameFromInt(deviceName));

  static String _getNameFromInt(int deviceName) {
    return 'HTC BS 0000${deviceName.toRadixString(16).padLeft(2, '0').toUpperCase()}';
  }
}

@visibleForTesting
class SimpleBluetoothService extends LHBluetoothService {
  SimpleBluetoothService(List<LHBluetoothCharacteristic> characteristics)
      : _characteristics = characteristics;

  List<LHBluetoothCharacteristic> _characteristics;

  LighthouseGuid _uuid =
      LighthouseGuid.fromString('00000000-0000-0000-0000-000000000001');

  @override
  List<LHBluetoothCharacteristic> get characteristics => _characteristics;

  @override
  LighthouseGuid get uuid => _uuid;
}

abstract class FakeReadWriteCharacteristic extends LHBluetoothCharacteristic {
  final LighthouseGuid _uuid;

  List<int> data = [];

  FakeReadWriteCharacteristic(LighthouseGuid uuid) : _uuid = uuid;

  @override
  LighthouseGuid get uuid => _uuid;

  @override
  Future<List<int>> read() async {
    return data;
  }
}

abstract class FakeReadOnlyCharacteristic extends LHBluetoothCharacteristic {
  final List<int> data;
  final LighthouseGuid _uuid;

  FakeReadOnlyCharacteristic(this.data, LighthouseGuid uuid) : _uuid = uuid;

  @override
  LighthouseGuid get uuid => _uuid;

  @override
  Future<List<int>> read() async => data;

  @override
  Future<Function> write(List<int> data, {bool withoutResponse = false}) {
    throw UnimplementedError(
        'Write is not supported by FakeReadOnlyCharacteristic');
  }
}

//region Fake default
class _FakeFirmwareCharacteristic extends FakeReadOnlyCharacteristic {
  _FakeFirmwareCharacteristic()
      : super(
            intListFromString('FAKE_DEVICE'),
            LighthouseGuid.fromString(BluetoothDefaultCharacteristicUUIDS
                .FIRMWARE_REVISION_STRING.uuid));
}

class _FakeModelNumberCharacteristic extends FakeReadOnlyCharacteristic {
  _FakeModelNumberCharacteristic()
      : super(
            intListFromNumber(0xFF),
            LighthouseGuid.fromString(
                BluetoothDefaultCharacteristicUUIDS.MODEL_NUMBER_STRING.uuid));
}

class _FakeSerialNumberCharacteristic extends FakeReadOnlyCharacteristic {
  _FakeSerialNumberCharacteristic()
      : super(
            intListFromNumber(0xFF),
            LighthouseGuid.fromString(
                BluetoothDefaultCharacteristicUUIDS.SERIAL_NUMBER_STRING.uuid));
}

class _FakeHardwareRevisionCharacteristic extends FakeReadOnlyCharacteristic {
  _FakeHardwareRevisionCharacteristic()
      : super(
            intListFromString('FAKE_REVISION'),
            LighthouseGuid.fromString(BluetoothDefaultCharacteristicUUIDS
                .HARDWARE_REVISION_STRING.uuid));
}

class _FakeManufacturerNameCharacteristic extends FakeReadOnlyCharacteristic {
  _FakeManufacturerNameCharacteristic()
      : super(
            intListFromString('LIGHTHOUSE PM By Jeroen1602'),
            LighthouseGuid.fromString(BluetoothDefaultCharacteristicUUIDS
                .MANUFACTURER_NAME_STRING.uuid));
}
//endregion

class _FakeChannelCharacteristic extends FakeReadOnlyCharacteristic {
  _FakeChannelCharacteristic()
      : super(
            intListFromNumber(0xFF),
            LighthouseGuid.fromString(
                LighthouseV2Device.CHANNEL_CHARACTERISTIC));
}

@visibleForTesting
class FakeLighthouseV2PowerCharacteristic extends FakeReadWriteCharacteristic {
  @visibleForTesting
  FakeLighthouseV2PowerCharacteristic()
      : super(LighthouseGuid.fromString(
            LighthouseV2Device.POWER_CHARACTERISTIC)) {
    if (random.nextBool()) {
      this.data.add(0x00); // sleep
    } else {
      this.data.add(0x0b); // on
    }
  }

  final random = Random();

  @override
  Future<void> write(List<int> data, {bool withoutResponse = false}) async {
    if (data.length != 1) {
      debugPrint(
          'Send incorrect amount of bytes to fake lighthouse v2 power characteristic');
      return;
    }
    final byte = data[0];
    switch (byte) {
      case 0x00:
        this.data[0] = byte;
        break;
      case 0x01:
      case 0x02:
        // Go from on to standby
        if (this.data[0] == 0x0b && byte == 0x02) {
          this.data[0] = byte;
          break;
        }
        // Go from standby to on
        if (this.data[0] == 0x02 && byte == 0x01) {
          this.data[0] = 0x0b;
          break;
        }
        // Go from off to standby/ on.
        this.data[0] = byte;
        Future.delayed(Duration(milliseconds: 10)).then((value) async {
          // booting
          this.data[0] = 0x09;
          await Future.delayed(Duration(milliseconds: 1200));
        }).then((value) {
          if (byte == 0x01) {
            this.data[0] = 0x0b; // on
          } else {
            this.data[0] = byte; // other
          }
        });

        break;
      default:
        debugPrint(
            'Unknown state 0x${byte.toRadixString(16).padLeft(2, '0').toUpperCase()}');
    }
  }
}

@visibleForTesting
class FakeLighthouseV2IdentifyCharacteristic
    extends FakeReadWriteCharacteristic {
  @visibleForTesting
  FakeLighthouseV2IdentifyCharacteristic(this.powerCharacteristic)
      : super(
          LighthouseGuid.fromString(LighthouseV2Device.IDENTIFY_CHARACTERISTIC),
        );

  final FakeLighthouseV2PowerCharacteristic powerCharacteristic;

  @override
  Future<void> write(List<int> data, {bool withoutResponse = false}) async {
    if (data.length == 1 && data[0] == 0x00) {
      await powerCharacteristic.write([0x01], withoutResponse: withoutResponse);
    } else {
      debugPrint("Send unrecognized data to the identify characteristic");
    }
  }
}

class _FakeViveBaseStationCharacteristic extends FakeReadWriteCharacteristic {
  _FakeViveBaseStationCharacteristic()
      : super(
            LighthouseGuid.fromString('0000cb01-0000-1000-8000-00805f9b34fb')) {
    data.addAll([0x00, 0x12]);
  }

  void changeState(LighthousePowerState state) {
    switch (state) {
      case LighthousePowerState.ON:
        data.clear();
        data.addAll([0x00, 0x15]);
        break;
      case LighthousePowerState.SLEEP:
        data.clear();
        data.addAll([0x00, 0x12]);
    }
  }

  @override
  Future<void> write(List<int> data, {bool withoutResponse = false}) async {
    if (data[1] == 0x00 && data[2] == 0x00 && data[3] == 0x00) {
      changeState(LighthousePowerState.ON);
    } else if (data[1] == 0x02 && data[2] == 0x00 && data[3] == 0x01) {
      changeState(LighthousePowerState.SLEEP);
    }
  }
}

@visibleForTesting
List<int> intListFromString(String data) {
  return Utf8Encoder().convert(data).toList();
}

///
/// Converts a number to an int list. Will also trim the leading 00's from the
/// number. On io platforms it will work with a max of 64bit ints, for web it
/// will work with a max of 32bit ints.
///
/// If the input number is 0xFF00, then the output will be [0xFF, 0x00]. Where
/// the leading 0x00's have been stripped from the conversion.
///
/// If the input is 0x00, then the output will be [] (empty list).
///
@visibleForTesting
List<int> intListFromNumber(int number) {
  final data = ByteData(LocalPlatform.isWeb ? 4 : 8);
  if (LocalPlatform.isWeb) {
    data.setUint32(0, number, Endian.big);
  } else {
    data.setUint64(0, number, Endian.big);
  }
  final List<int> list = List<int>.filled(data.lengthInBytes, 0);
  var nonZero = false;
  var trimZeroStart = -1;
  //        V
  // 00 00 00 FF
  for (int i = 0; i < data.lengthInBytes; i++) {
    final byte = data.getUint8(i);
    if (byte > 0 && !nonZero) {
      nonZero = true;
      trimZeroStart = i - 1;
    }
    list[i] = byte;
  }
  if (nonZero) {
    if (trimZeroStart > 0) {
      // 00 00 00 FF -> FF
      // 00 00 FF 00 -> FF 00
      return list.sublist(trimZeroStart);
    }
    return list;
  } else {
    return <int>[];
  }
}
