import 'package:flutter/material.dart';
import 'package:lighthouse_pm/permissions_helper/ble_permissions_helper.dart';
import 'package:lighthouse_pm/widgets/permanent_permission_denied_alert_widget.dart';
import 'package:lighthouse_pm/widgets/permissions_alert_widget.dart';
import 'package:permission_handler/permission_handler.dart';

///
/// A simple class just for keeping the functions in the right place.
///
class LocationPermissionDialogFlow {
  LocationPermissionDialogFlow._();

  ///
  /// Show a dialog explaining to the user why they should enable location permissions.
  /// After the explanation the native permission dialog will show.
  /// If the native dialog is rejected forever then an extra dialog will show,
  /// explaining again why it is needed and redirecting the user to the app
  /// settings.
  ///
  /// This flow works only on Android!
  static Future<bool> showLocationPermissionDialogFlow(
      BuildContext context) async {
    switch (await BLEPermissionsHelper.hasBLEPermissions()) {
      case PermissionStatus.denied:
      case PermissionStatus.restricted:
        // expression can be `null`
        if (await PermissionsAlertWidget.showCustomDialog(context) != true) {
          return false;
        }
        switch (await BLEPermissionsHelper.requestBLEPermissions()) {
          case PermissionStatus.permanentlyDenied:
            continue permanentlyDenied;
          case PermissionStatus.granted:
            continue granted;
          default:
            return false;
        }
      granted:
      case PermissionStatus.granted:
      case PermissionStatus.limited:
        return true;
      permanentlyDenied:
      case PermissionStatus.permanentlyDenied:
        // expression can be `null`
        if (await PermanentPermissionDeniedAlertWidget.showCustomDialog(
                context) ==
            true) {
          openAppSettings();
        }
        return false;
    }
  }
}
