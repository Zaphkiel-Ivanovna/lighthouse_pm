import 'package:flutter/widgets.dart';
import 'package:lighthouse_pm/platformSpecific/shared/LocalPlatform.dart';

const _EXIT_WAIT_TIME = 5;

abstract class CloseCurrentRouteMixin {
  Future<void> closeCurrentRouteWithWait(BuildContext context) async {
    await Future.delayed(Duration(seconds: _EXIT_WAIT_TIME));
    await closeCurrentRoute(context);
  }

  Future<void> closeCurrentRoute(BuildContext context) async {
    Navigator.pop(context);
    bool canPop = Navigator.canPop(context);
    if (!canPop) {
      if (LocalPlatform.isAndroid) {
        // This is not recommended for iOS but this code should only be run
        // on Android.
        LocalPlatform.exit(0);
      } else {
        Navigator.pushNamed(context, Navigator.defaultRouteName);
      }
    }
  }
}
