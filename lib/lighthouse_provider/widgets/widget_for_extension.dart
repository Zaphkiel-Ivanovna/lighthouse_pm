import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lighthouse_provider/device_extensions/device_extension.dart';
import 'package:lighthouse_provider/device_extensions/shortcut_extension.dart';
import 'package:lighthouse_providers/lighthouse_v2_device_provider.dart';
import 'package:lighthouse_providers/vive_base_station_device_provider.dart';

Widget getWidgetFromDeviceExtension(final DeviceExtension extension) {
  if (extension is OnExtension) {
    return const Icon(Icons.power_settings_new, size: 24, color: Colors.green);
  } else if (extension is SleepExtension) {
    return const Icon(Icons.power_settings_new, size: 24, color: Colors.blue);
  } else if (extension is StandbyExtension) {
    return const Icon(Icons.power_settings_new, size: 24, color: Colors.orange);
  } else if (extension is ShortcutExtension) {
    return const Icon(Icons.add);
  } else if (extension is IdentifyDeviceExtension) {
    return SvgPicture.asset(
      "assets/images/identify-icon.svg",
      width: 24,
      height: 24,
    );
  } else if (extension is ClearIdExtension) {
    return const Text('ID');
  }

  return Text(extension.runtimeType.toString());
}
