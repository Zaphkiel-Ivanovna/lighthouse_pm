import 'package:device_info/device_info.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:lighthouse_pm/platform_specific/shared/local_platform.dart';
import 'package:permission_handler/permission_handler.dart';

///
/// A simple class with helper functions to check if the device is allowed to use
/// BLE.
///
abstract class BLEPermissionsHelper {
  @visibleForTesting
  static const channel =
      MethodChannel("com.jeroen1602.lighthouse_pm/bluetooth");

  ///
  /// A function to check if the app is allowed to use BLE.
  /// On Android 12+ the device is allowed to use BLE if the bluetooth scan and
  /// connect permission have been granted by the user.
  /// On older Android versions the device is only allowed to use BLE if the
  /// location permission has been granted by the user.
  ///
  /// On iOS, web, and Linux it's always allowed to use BLE.
  ///
  /// May throw [UnsupportedError] if the platform is not supported.
  static Future<PermissionStatus> hasBLEPermissions() async {
    if (LocalPlatform.isIOS) {
      return await Permission.bluetooth.status;
    }
    if (LocalPlatform.isAndroid) {
      final version = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
      // Check the new bluetooth permission for Android 12 and higher.
      if (version >= 31) {
        final scan = await Permission.bluetoothScan.status;
        if (!scan.isGranted) {
          return scan;
        }
        final connect = await Permission.bluetoothConnect.status;
        return connect;
      } else {
        // Check the "legacy" location permission.
        return await Permission.locationWhenInUse.status;
      }
    }
    if (LocalPlatform.isWeb) {
      return PermissionStatus.granted;
    }
    if (LocalPlatform.isLinux) {
      return PermissionStatus.granted;
    }
    throw UnsupportedError(
        "ERROR: unsupported platform! ${LocalPlatform.current}");
  }

  ///
  /// A function to request the user to allow BLE permissions.
  /// On Android 12+ the device is allowed to use BLE if the bluetooth scan and
  /// connect permission have been granted by the user.
  /// On older Android versions the device is only allowed to use BLE if the
  /// location permission has been granted by the user.
  ///
  /// On iOS, web, and Linux the app is always allowed to use BLE and thus this
  /// will always return [PermissionStatus.granted].
  ///
  /// May throw [UnsupportedError] if the platform is not supported.
  static Future<PermissionStatus> requestBLEPermissions() async {
    if (LocalPlatform.isAndroid) {
      final version = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
      if (version >= 31) {
        // Request the new bluetooth permission for Android 12 and higher.
        return await [Permission.bluetoothScan, Permission.bluetoothConnect]
            .request()
            .then((map) => map.values)
            .then((statuses) {
          for (final status in statuses) {
            if (!status.isGranted) {
              return status;
            }
          }
          return statuses.last;
        });
      } else {
        // Request the "legacy" location permission.
        return await Permission.locationWhenInUse.request();
      }
    }
    if (LocalPlatform.isIOS) {
      return await Permission.bluetooth.request();
    }
    if (LocalPlatform.isWeb) {
      return PermissionStatus.granted;
    }
    if (LocalPlatform.isLinux) {
      return PermissionStatus.granted;
    }
    throw UnsupportedError(
        "ERROR: unsupported platform! ${LocalPlatform.current}");
  }

  ///
  /// Open the bluetooth settings on the device.
  /// On Android this is possible.
  /// This function is not possible on iOS, web, and Linux and will always
  /// return [false].
  ///
  /// May throw [UnsupportedError] if the platform is not supported.
  static Future<bool> openBLESettings() async {
    if (LocalPlatform.isAndroid) {
      return channel.invokeMethod("openBLESettings").then((value) {
        if (value is bool) {
          return value;
        } else {
          throw TypeError();
        }
      });
    }
    if (LocalPlatform.isIOS) {
      // According to [this](https://stackoverflow.com/a/43754366/13324337) you
      // aren't allowed to open settings on ios.
      debugPrint("Can't open settings because iOS doesn't support it.");
      return false;
    }
    if (LocalPlatform.isWeb) {
      debugPrint("Can't open settings on WEB because there is no api.");
      return false;
    }
    if (LocalPlatform.isLinux) {
      debugPrint("Can't open settings on Linux because there is no api.");
      return false;
    }
    throw UnsupportedError(
        "ERROR: unsupported platform! ${LocalPlatform.current}");
  }

  ///
  /// Enable the bluetooth adapter on a device.
  /// On Android this is possible.
  /// This function is not possible on iOS, web, and Linux and will always
  /// return [false].
  ///
  /// May throw [UnsupportedError] if the platform is not supported.
  static Future<bool> enableBLE() async {
    if (LocalPlatform.isAndroid) {
      return channel.invokeMethod("enableBluetooth").then((value) {
        if (value is bool) {
          return value;
        } else {
          throw TypeError();
        }
      });
    }
    if (LocalPlatform.isLinux) {
      debugPrint("Can't enable BLE on Linux because I'm lazy 🙃.");
      return false;
    }
    if (LocalPlatform.isIOS) {
      // iOS doesn't have an API that can handle enable bluetooth for us.
      debugPrint("Can't enable BLE on iOS since there is no api.");
      return false;
    }
    if (LocalPlatform.isWeb) {
      debugPrint("Can't enable BLE on WEB since there is no api.");
      return false;
    }
    throw UnsupportedError(
        "ERROR: unsupported platform! ${LocalPlatform.current}");
  }

  ///
  /// Open location settings for a specific platform.
  /// On Android this is possible.
  /// This function is not possible On iOS, web, and Linux and will always
  /// return [false].
  ///
  /// May throw [UnsupportedError] if the platform is not supported.
  static Future<bool> openLocationSettings() async {
    if (LocalPlatform.isAndroid) {
      return channel.invokeMethod("openLocationSettings").then((value) {
        if (value is bool) {
          return value;
        } else {
          throw TypeError();
        }
      });
    }
    if (LocalPlatform.isIOS) {
      // iOS doesn't have an API that can open location settings
      debugPrint("Can't open location settings on iOS since there is no api.");
      return false;
    }
    if (LocalPlatform.isWeb) {
      debugPrint("Can't open location settings on WEB since there is no api.");
      return false;
    }
    if (LocalPlatform.isLinux) {
      debugPrint(
          "Can't open location settings on Linux since there is no api.");
      return false;
    }
    throw UnsupportedError(
        "ERROR: unsupported platform! ${LocalPlatform.current}");
  }
}
