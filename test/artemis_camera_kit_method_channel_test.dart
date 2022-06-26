import 'package:artemis_camera_kit/artemis_camera_kit_method_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  MethodChannelArtemisCameraKit platform = MethodChannelArtemisCameraKit();
  const MethodChannel channel = MethodChannel('artemis_camera_kit');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
