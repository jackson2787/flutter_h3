import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_h3/flutter_h3.dart';
import 'package:flutter_h3/flutter_h3_platform_interface.dart';
import 'package:flutter_h3/flutter_h3_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterH3Platform
    with MockPlatformInterfaceMixin
    implements FlutterH3Platform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterH3Platform initialPlatform = FlutterH3Platform.instance;

  test('$MethodChannelFlutterH3 is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterH3>());
  });

  test('getPlatformVersion', () async {
    FlutterH3 flutterH3Plugin = FlutterH3();
    MockFlutterH3Platform fakePlatform = MockFlutterH3Platform();
    FlutterH3Platform.instance = fakePlatform;

    expect(await flutterH3Plugin.getPlatformVersion(), '42');
  });
}
