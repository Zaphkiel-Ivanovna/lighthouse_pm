import 'package:flutter/material.dart';
import 'package:lighthouse_pm/permissions_helper/ble_permissions_helper.dart';
import 'package:lighthouse_pm/widgets/enable_bluetooth_alert_widget.dart';

///
/// A simple class just for keeping the functions in the right place.
///
class EnableBluetoothDialogFlow {
  EnableBluetoothDialogFlow._();

  ///
  /// Show the enable bluetooth dialog flow.
  /// The flow consists of asking the user to enable Bluetooth.
  /// Trying to enable Bluetooth if accepted.
  /// Showing a snack bar if unable to do so.
  /// Opening Bluetooth settings if snack bar action is used.
  ///
  /// This flow works only on Android!
  static Future showEnableBluetoothDialogFlow(BuildContext context,
      {bool showSnackBarOnFailure = true}) async {
    // Expression can be `null`
    if (await EnableBluetoothAlertWidget.showCustomDialog(context) == true) {
      if (!await BLEPermissionsHelper.enableBLE()) {
        if (showSnackBarOnFailure) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
              content: Text('Could not enable Bluetooth.'),
              action: SnackBarAction(
                label: 'Go to Settings.',
                onPressed: () async {
                  await BLEPermissionsHelper.openBLESettings();
                },
              )));
        } else {
          debugPrint(
              'Could not enable bluetooth, but no snack bar was shown because of a setting');
        }
      }
    }
  }
}
