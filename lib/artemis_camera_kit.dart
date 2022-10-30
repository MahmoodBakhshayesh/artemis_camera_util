import 'package:flutter/services.dart';

import 'artemis_camera_kit_platform_interface.dart';

class ArtemisCameraKit {
  Future<String?> getPlatformVersion() {
    return ArtemisCameraKitPlatform.instance.getPlatformVersion();
  }

  Future<bool?> getCameraPermission() {
    return ArtemisCameraKitPlatform.instance.getCameraPermission();
  }

  Future<void> initCamera({
    required bool hasBarcodeReader,
    FlashMode initFlash = FlashMode.auto,
    bool fill = true,
    BarcodeType barcodeType = BarcodeType.allFormats,
    CameraType cameraType = CameraType.back,
    UsageMode mode = UsageMode.barcodeScanner,
  }) {
    return ArtemisCameraKitPlatform.instance.initCamera(
        mode: mode,
        hasBarcodeReader: hasBarcodeReader,
        initFlash: initFlash,
        fill: fill,
        barcodeType: barcodeType,
        cameraType: cameraType);
  }

  Future<void> changeFlashMode({required FlashMode mode}) {
    return ArtemisCameraKitPlatform.instance.changeFlashMode(mode);
  }

  Future<void> changeCameraVisibility({required bool visibility}) {
    return ArtemisCameraKitPlatform.instance.changeCameraVisibility(visibility);
  }

  Future<void> pauseCamera() {
    return ArtemisCameraKitPlatform.instance.pauseCamera();
  }

  Future<void> resumeCamera() {
    return ArtemisCameraKitPlatform.instance.resumeCamera();
  }

  Future<String?> takePicture([String path = ""]) {
    return ArtemisCameraKitPlatform.instance.takePicture(path);
  }

  Future<OcrData?> processImageFromPath([String path = ""]) {
    return ArtemisCameraKitPlatform.instance.processImageFromPath(path);
  }


  Future<BarcodeData?> getBarcodesFromImage([String path = ""]) {
    return ArtemisCameraKitPlatform.instance.getBarcodesFromImage(path);
  }

  Future<void> setMethodCallHandler({required Future<dynamic> Function(MethodCall call)? handler}) {
    return ArtemisCameraKitPlatform.instance.setMethodCallHandler(handler);
  }

  Future<DataInImage> getDataFromImage(String path) {
    return ArtemisCameraKitPlatform.instance.getDataFromImage(path);
  }
}
