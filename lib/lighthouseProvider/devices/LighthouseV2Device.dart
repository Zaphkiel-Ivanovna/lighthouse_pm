import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:lighthouse_pm/lighthouseProvider/LighthousePowerState.dart';
import 'package:lighthouse_pm/lighthouseProvider/devices/BLEDevice.dart';

///The bluetooth service that handles the power state of the device.
final Guid _POWER_SERVICE = Guid('00001523-1212-efde-1523-785feabcd124');

///The characteristic that handles the power state of the device.
final Guid _POWER_CHARACTERISTIC = Guid('00001525-1212-efde-1523-785feabcd124');

class LighthouseV2Device extends BLEDevice {
  LighthouseV2Device(BluetoothDevice device) : super(device);

  BluetoothCharacteristic _characteristic;

  @override
  Future<int /*?*/ > getCurrentState() async {
    if (_characteristic == null) {
      return null;
    }
    if ((await this.device.state.first) != BluetoothDeviceState.connected) {
      await disconnect();
      return null;
    }
    final dataArray = await _characteristic.read();
    if (dataArray.length >= 1) {
      return dataArray[0];
    }
    return null;
  }

  @override
  bool get hasOpenConnection {
    return (_characteristic != null);
  }

  @override
  LighthousePowerState internalGetPowerStateFromByte(int byte) =>
      LighthousePowerState.fromByte(byte);

  @override
  Future<bool> isValid() async {
    debugPrint('Connecting to device: ${this.deviceIdentifier}');
    await this.device.connect(timeout: Duration(seconds: 10)).catchError((e) {
      debugPrint('Connection timed-out for device: ${this.deviceIdentifier}');
      return false;
    }, test: (e) => e is TimeoutException);

    debugPrint('Finding service for device: ${this.deviceIdentifier}');
    final List<BluetoothService> services =
        await this.device.discoverServices();
    for (final service in services) {
      if (service.uuid != _POWER_SERVICE) {
        continue;
      }
      // Find the correct characteristic.
      for (final characteristic in service.characteristics) {
        if (characteristic.uuid == _POWER_CHARACTERISTIC) {
          this._characteristic = characteristic;
          return true;
        }
      }
    }
    await disconnect();
    return false;
  }

  // TODO: support nicknames.
  @override
  String get name => device.name;

  @override
  Future cleanupConnection() async {
    this._characteristic = null;
  }

  @override
  Future internalChangeState(LighthousePowerState newState) async {
    if (this._characteristic != null) {
      await this
          ._characteristic
          .write([newState.setByte], withoutResponse: true);
    }
  }
}
