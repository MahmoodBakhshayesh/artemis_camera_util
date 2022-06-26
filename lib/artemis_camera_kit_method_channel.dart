import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'artemis_camera_kit_platform_interface.dart';

/// An implementation of [ArtemisCameraKitPlatform] that uses method channels.
class MethodChannelArtemisCameraKit extends ArtemisCameraKitPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('artemis_camera_kit');



  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<bool?> getCameraPermission() async {
    final permissionResult = await methodChannel.invokeMethod<bool>('getCameraPermission');
    return permissionResult;
  }

  @override
  Future<void> initCamera({
    required bool hasBarcodeReader,
    required FlashMode initFlash,
    required bool fill,
    required BarcodeType barcodeType,
    required CameraType cameraType,
  }) async {
    return methodChannel.invokeMethod<void>('initCamera', {
      "hasBarcodeReader": hasBarcodeReader,
      "initFlashModeID": initFlash.id,
      "fill": fill,
      "barcodeTypeID": barcodeType.id,
      "cameraTypeID": cameraType.id
    });
  }

  @override
  Future<void> pauseCamera() async {
    methodChannel.invokeMethod<void>('pauseCamera');
  }

  @override
  Future<void> resumeCamera() async {
    methodChannel.invokeMethod<void>('resumeCamera');
  }

  @override
  Future<void> dispose() async {
    methodChannel.invokeMethod<void>('dispose');
  }

  @override
  Future<void> changeFlashMode(FlashMode flashMode) async {
    methodChannel.invokeMethod<void>('changeFlashMode', {"flashModeID": flashMode.id});
  }

  @override
  Future<String?> takePicture([String path = ""]) async {
    return methodChannel.invokeMethod<String?>('takePicture', {"path": path});
  }

  @override
  Future<OcrData?> processImageFromPath([String path = ""]) async {
    String? ocrJson = await methodChannel.invokeMethod<String?>('processImageFromPath', {"path": path});
    if (ocrJson == null) return null;
    try {
      OcrData ocrData = OcrData.fromJson(jsonDecode(ocrJson));
      return ocrData;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> changeCameraVisibility(bool visibility) async {
    methodChannel.invokeMethod<void>('changeCameraVisibility', {"visibility": visibility});
  }


  @override
  Future<void> setMethodCallHandler(Future Function(MethodCall call)? handler) async {
    methodChannel.setMethodCallHandler(handler);
  }
}
