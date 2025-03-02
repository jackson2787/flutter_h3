import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_h3_method_channel.dart';

abstract class FlutterH3Platform extends PlatformInterface {
  /// Constructs a FlutterH3Platform.
  FlutterH3Platform() : super(token: _token);

  static final Object _token = Object();

  static FlutterH3Platform _instance = MethodChannelFlutterH3();

  /// The default instance of [FlutterH3Platform] to use.
  ///
  /// Defaults to [MethodChannelFlutterH3].
  static FlutterH3Platform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterH3Platform] when
  /// they register themselves.
  static set instance(FlutterH3Platform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
