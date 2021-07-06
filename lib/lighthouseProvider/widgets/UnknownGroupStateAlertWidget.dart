import 'package:flutter/material.dart';
import 'package:lighthouse_pm/lighthouseProvider/LighthousePowerState.dart';

/// An alert dialog to ask the user what to do since the group state is unknown.
class UnknownGroupStateAlertWidget extends StatelessWidget {
  UnknownGroupStateAlertWidget(this.supportsStandby, this.isStateUniversal,
      {Key? key})
      : super(key: key);

  final bool supportsStandby;
  final bool isStateUniversal;

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      SimpleDialogOption(
        child: const Text("Cancel"),
        onPressed: () {
          Navigator.pop(context, null);
        },
      ),
      // Add standby, but only if it's supported
      if (supportsStandby)
        SimpleDialogOption(
          child: const Text("Standby"),
          onPressed: () {
            Navigator.pop(context, LighthousePowerState.STANDBY);
          },
        ),
      SimpleDialogOption(
        child: const Text("Sleep"),
        onPressed: () {
          Navigator.pop(context, LighthousePowerState.SLEEP);
        },
      ),
      SimpleDialogOption(
        child: const Text("On"),
        onPressed: () {
          Navigator.pop(context, LighthousePowerState.ON);
        },
      ),
    ];

    return AlertDialog(
        title: Text(this.isStateUniversal
            ? 'Group state is unknown'
            : 'Group state is not universal'),
        content: Text(this.isStateUniversal
            ? 'The state of the devices in this group are unknown, '
                'what do you want to do?'
            : 'Not all the devices in this group have the same state, '
                'what do you want to do?'),
        actions: actions);
  }

  static Future<LighthousePowerState?> showCustomDialog(
      BuildContext context, bool supportsStandby, bool isStateUniversal) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return UnknownGroupStateAlertWidget(
              supportsStandby, isStateUniversal);
        });
  }
}
