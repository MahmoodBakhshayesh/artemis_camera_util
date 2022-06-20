// import 'package:flutter_test/flutter_test.dart';
// import 'package:artemis_camera_kit/artemis_camera_kit.dart';
// import 'package:artemis_camera_kit/artemis_camera_kit_platform_interface.dart';
// import 'package:artemis_camera_kit/artemis_camera_kit_method_channel.dart';
// import 'package:plugin_platform_interface/plugin_platform_interface.dart';
//
// class MockArtemisCameraKitPlatform
//     with MockPlatformInterfaceMixin
//     implements ArtemisCameraKitPlatform {
//
//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
//
//   @override
//   Future<bool?> getCameraPermission() =>Future.value(true);
//
//   @override
//   Future<void> initCamera() => Future.value();
// }
//
// void main() {
//   final ArtemisCameraKitPlatform initialPlatform = ArtemisCameraKitPlatform.instance;
//
//   test('$MethodChannelArtemisCameraKit is the default instance', () {
//     expect(initialPlatform, isInstanceOf<MethodChannelArtemisCameraKit>());
//   });
//
//   test('getPlatformVersion', () async {
//     ArtemisCameraKit artemisCameraKitPlugin = ArtemisCameraKit();
//     MockArtemisCameraKitPlatform fakePlatform = MockArtemisCameraKitPlatform();
//     ArtemisCameraKitPlatform.instance = fakePlatform;
//
//     expect(await artemisCameraKitPlugin.getPlatformVersion(), '42');
//   });
// }
