import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'artemis_camera_kit_method_channel.dart';

abstract class ArtemisCameraKitPlatform extends PlatformInterface {
  /// Constructs a ArtemisCameraKitPlatform.
  ArtemisCameraKitPlatform() : super(token: _token);

  static final Object _token = Object();

  static ArtemisCameraKitPlatform _instance = MethodChannelArtemisCameraKit();

  /// The default instance of [ArtemisCameraKitPlatform] to use.
  ///
  /// Defaults to [MethodChannelArtemisCameraKit].
  static ArtemisCameraKitPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ArtemisCameraKitPlatform] when
  /// they register themselves.
  static set instance(ArtemisCameraKitPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<bool?> getCameraPermission() {
    throw UnimplementedError('cameraPermission() has not been implemented.');
  }

  Future<void> initCamera({
    required bool hasBarcodeReader,
    required FlashMode initFlash,
    required bool fill,
    required BarcodeType barcodeType,
    required CameraType cameraType,
    required UsageMode mode,
  }) {
    throw UnimplementedError('initCamera() has not been implemented.');
  }

  Future<void> pauseCamera() {
    throw UnimplementedError('pauseCamera() has not been implemented.');
  }

  Future<void> resumeCamera() {
    throw UnimplementedError('resumeCamera() has not been implemented.');
  }

  Future<void> changeFlashMode(FlashMode flashMode) {
    throw UnimplementedError('changeFlashMode() has not been implemented.');
  }

  Future<String?> takePicture([String path = ""]) {
    throw UnimplementedError('takePicture() has not been implemented.');
  }

  Future<OcrData?> processImageFromPath([String path = ""]) {
    throw UnimplementedError('processImageFromPath() has not been implemented.');
  }

  Future<BarcodeData?> getBarcodesFromImage([String path = ""]) {
    throw UnimplementedError('getBarcodesFromImage() has not been implemented.');
  }

  Future<void> dispose() {
    throw UnimplementedError('dispose() has not been implemented.');
  }

  Future<void> changeCameraVisibility(bool visibility) {
    throw UnimplementedError('changeCameraVisibility() has not been implemented!.');
  }

  Future<void> setMethodCallHandler(Future<dynamic> Function(MethodCall call)? handler) {
    throw UnimplementedError('setMethodCallHandler() has not been implemented.');
  }

  Future<DataInImage> getDataFromImage(String path) {
    throw UnimplementedError('getDataFromImage() has not been implemented.');
  }
}

enum BarcodeType { allFormats, code128, code39, cod93, codabar, dataMatrix, ean13, ean8, itf, qrCode, upcA, upcE, pdf417, aztec,unknown }

enum CameraType { back, front }

enum FlashMode { on, off, auto }

enum UsageMode { camera, barcodeScanner, ocrReader }

extension FlashModeDetails on FlashMode {
  int get id {
    switch (this) {
      case FlashMode.on:
        return 1;
      case FlashMode.off:
        return 0;
      case FlashMode.auto:
        return 2;
    }
  }
}

extension CameraTypeDetails on CameraType {
  int get id {
    switch (this) {
      case CameraType.back:
        return 0;
      case CameraType.front:
        return 1;
    }
  }
}

extension UsageModeDetails on UsageMode {
  int get id {
    switch (this) {
      case UsageMode.camera:
        return 0;
      case UsageMode.barcodeScanner:
        return 1;
      case UsageMode.ocrReader:
        return 2;
    }
  }
}

extension BarcodeTypeDetails on BarcodeType {
  int get id {
    switch (this) {
      case BarcodeType.allFormats:
        return 0;
      case BarcodeType.code128:
        return 1;
      case BarcodeType.code39:
        return 2;
      case BarcodeType.cod93:
        return 4;
      case BarcodeType.codabar:
        return 8;
      case BarcodeType.dataMatrix:
        return 16;
      case BarcodeType.ean13:
        return 32;
      case BarcodeType.ean8:
        return 64;
      case BarcodeType.itf:
        return 128;
      case BarcodeType.qrCode:
        return 256;
      case BarcodeType.upcA:
        return 512;
      case BarcodeType.upcE:
        return 1024;
      case BarcodeType.pdf417:
        return 2048;
      case BarcodeType.aztec:
        return 4096;
      case BarcodeType.unknown:
        return -1;
    }
  }

  String get name {
    switch (this) {
      case BarcodeType.allFormats:
        return "All";
      case BarcodeType.code128:
        return "Code128";
      case BarcodeType.code39:
        return "Code39";
      case BarcodeType.cod93:
        return "Code93";
      case BarcodeType.codabar:
        return "CodaBar";
      case BarcodeType.dataMatrix:
        return "DataMatrix";
      case BarcodeType.ean13:
        return "Ean13";
      case BarcodeType.ean8:
        return "Ean8";
      case BarcodeType.itf:
        return "Itf";
      case BarcodeType.qrCode:
        return "QrCode";
      case BarcodeType.upcA:
        return "UpcA";
      case BarcodeType.upcE:
        return "UpcE";
      case BarcodeType.pdf417:
        return "Pdf417";
      case BarcodeType.aztec:
        return "Aztec";
      case BarcodeType.unknown:
        return "Unknown";
    }
  }
}

class OcrData {
  OcrData({
    required this.text,
    this.path = "",
    this.orientation = 0,
    required this.lines,
  });

  String text;
  String path;
  int orientation;
  List<OcrLine> lines;

  factory OcrData.fromJson(Map<String, dynamic> json) => OcrData(
        text: json["text"],
        path: json["path"] ?? "",
        orientation: json["orientation"] ?? 0,
        lines: List<OcrLine>.from((json["lines"] ?? []).map((x) => OcrLine.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "text": text,
        "path": path,
        "orientation": orientation,
        "lines": List<dynamic>.from(lines.map((x) => x.toJson())),
      };
}

class OcrLine {
  OcrLine({
    required this.text,
    required this.cornerPoints,
  });

  String text;
  List<OcrPoint> cornerPoints;

  factory OcrLine.fromJson(Map<String, dynamic> json) => OcrLine(
        text: json["text"] ?? json["a"] ?? "",
        cornerPoints: List<OcrPoint>.from((json["cornerPoints"] ?? json["b"] ?? []).map((x) => OcrPoint.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "text": text,
        "cornerPoints": List<dynamic>.from(cornerPoints.map((x) => x.toJson())),
      };
}

class OcrPoint {
  OcrPoint({
    required this.x,
    required this.y,
  });

  double x;
  double y;

  factory OcrPoint.fromJson(Map<String, dynamic> json) => OcrPoint(
        x: (json["x"] ?? json["a"]).toDouble(),
        y: (json["y"] ?? json["b"]).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "x": x,
        "y": y,
      };
}

class BarcodeData {
  BarcodeData({
    this.path = "",
    this.orientation = 0,
    required this.barcodes,
  });

  String path;
  int orientation;
  List<BarcodeObject> barcodes;

  factory BarcodeData.fromJson(Map<String, dynamic> json) => BarcodeData(
        path: json["path"] ?? "",
        orientation: json["orientation"] ?? 0,
        barcodes: List<BarcodeObject>.from((json["barcodes"] ?? []).map((x) => BarcodeObject.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "path": path,
        "orientation": orientation,
        "barcodes": List<dynamic>.from(barcodes.map((x) => x.toJson())),
      };
}

class BarcodeObject {
  BarcodeObject({
    required this.value,
    required this.rawValue,
    required this.typeId,
    required this.cornerPoints,
  });

  String value;
  String rawValue;
  int typeId;
  List<OcrPoint> cornerPoints;

  BarcodeType get type =>typeId>=BarcodeType.values.length?BarcodeType.unknown: BarcodeType.values[typeId];

  factory BarcodeObject.fromJson(Map<String, dynamic> json) => BarcodeObject(
        value: json["value"],
        rawValue: json["rawValue"],
        typeId: json["type"],
        cornerPoints: List<OcrPoint>.from((json["cornerPoints"] ?? json["b"] ?? []).map((x) => OcrPoint.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "type": type,
        "value": value,
        "rawValue": rawValue,
        "cornerPoints": List<dynamic>.from(cornerPoints.map((x) => x.toJson())),
      };
}

class DataInImage {
  OcrData? ocrData;
  BarcodeData? barcodeData;

  DataInImage(this.ocrData, this.barcodeData);

  Map<String,dynamic> toJson() =>{
    "OcrData":ocrData?.toJson(),
    "BarcodeData":barcodeData?.toJson()
  };

  factory DataInImage.fromJson(Map<String, dynamic> json) => DataInImage(
        OcrData.fromJson(json["OcrData"]),
        BarcodeData.fromJson(json["BarcodeData"]),
      );
}
