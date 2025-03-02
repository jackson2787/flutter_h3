import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_h3_platform_interface.dart';

/// An implementation of [FlutterH3Platform] that uses method channels.
class MethodChannelFlutterH3 extends FlutterH3Platform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_h3');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
