import 'package:flutter/foundation.dart';

import 'android_launcher_shortcut_shared.dart';

///
/// A copy of the api but all the functions fail, this is done so it can still
/// exist on the other platforms.
///
class AndroidLauncherShortcut {
  static AndroidLauncherShortcut? _instance;

  AndroidLauncherShortcut._() {
    if (!kReleaseMode) {
      throw UnsupportedError(
        "Hey developer this platform doesn't support shortcuts!\nHow come the class is still initialized?",
      );
    }
  }

  @visibleForTesting
  AndroidLauncherShortcut.testing() {
    debugPrint(
      "Warning created testing version of unsupported AndroidLauncherShortcut!",
    );
  }

  static AndroidLauncherShortcut get instance {
    return _instance ??= AndroidLauncherShortcut._();
  }

  Future<void> readyForData() async {
    _throwUnsupportedError();
  }

  Stream<ShortcutHandle?> get changePowerStateMac {
    _throwUnsupportedError();
    return const Stream.empty();
  }

  Future<bool> shortcutSupported() async {
    return false;
  }

  Future<bool> requestShortcutLighthouse(
    final String macAddress,
    final String name,
  ) async {
    _throwUnsupportedError();
    return false;
  }

  static void _throwUnsupportedError() {
    if (!kReleaseMode) {
      throw UnsupportedError(
        "Hey developer this platform doesn't support shortcuts!",
      );
    }
  }
}
