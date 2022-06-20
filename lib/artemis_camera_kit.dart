import 'artemis_camera_kit_platform_interface.dart';

class ArtemisCameraKit {
  Future<String?> getPlatformVersion() {
    return ArtemisCameraKitPlatform.instance.getPlatformVersion();
  }

  Future<bool?> getCameraPemission() {
    return ArtemisCameraKitPlatform.instance.getCameraPermission();
  }

  Future<void> initCamera({
    required bool hasBarcodeReader,
    FlashMode initFlash = FlashMode.auto,
    bool fill = true,
    BarcodeType barcodeType = BarcodeType.allFormats,
    CameraType cameraType = CameraType.back,
  }) {
    return ArtemisCameraKitPlatform.instance.initCamera(
        hasBarcodeReader: hasBarcodeReader, initFlash: initFlash, fill: fill, barcodeType: barcodeType, cameraType: cameraType);
  }

  Future<void> changeFlashMode({required FlashMode mode}) {
    return ArtemisCameraKitPlatform.instance.changeFlashMode(mode);
  }

  Future<void> pauseCamera() {
    return ArtemisCameraKitPlatform.instance.pauseCamera();
  }

  Future<void> resumeCamera() {
    return ArtemisCameraKitPlatform.instance.resumeCamera();
  }

  Future<String?> takePicture([String path =""]) {
    return ArtemisCameraKitPlatform.instance.takePicture(path);
  }

  Future<OcrData?> processImageFromPath([String path =""]) {
    return ArtemisCameraKitPlatform.instance.processImageFromPath(path);
  }
}
