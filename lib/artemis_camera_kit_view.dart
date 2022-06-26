import 'dart:developer';

import 'package:artemis_camera_kit/artemis_camera_kit_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'artemis_camera_kit_platform_interface.dart';

class ArtemisCameraKitView extends StatefulWidget {
  final void Function(String barcode)? onBarcodeRead;

  // final void Function() onPermissionDenied;
  final ArtemisCameraKitController? controller;
  final bool hasBarcodeReader;
  final FlashMode initFlash;
  final bool fill;
  final BarcodeType barcodeType;
  final CameraType cameraType;

  const ArtemisCameraKitView(
      {Key? key,
      this.controller,
      this.onBarcodeRead,
      this.hasBarcodeReader = true,
      this.initFlash = FlashMode.auto,
      this.fill = true,
      this.barcodeType = BarcodeType.allFormats,
      this.cameraType = CameraType.back})
      : super(key: key);

  @override
  State<ArtemisCameraKitView> createState() => _ArtemisCameraKitViewState();
}

class _ArtemisCameraKitViewState extends State<ArtemisCameraKitView> with WidgetsBindingObserver {
  late VisibilityDetector visibilityDetector;
  late ArtemisCameraKitController controller;
  static const String viewType = '<platform-view-type>';

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    controller = widget.controller ?? ArtemisCameraKitController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // This is used in the platform side to register the view.

    // Pass parameters to the platform side.
    // const Map<String, dynamic> creationParams = <String, dynamic>{};

    return VisibilityDetector(
      key: const Key(viewType),
      onVisibilityChanged: _handleVisibilityChange,
      child: _buildView(),
    );
  }

  Widget _buildView() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return VisibilityDetector(
            key: const Key(viewType),
            onVisibilityChanged: _handleVisibilityChange,
            child: AndroidView(
              viewType: viewType,
              onPlatformViewCreated: _onPlatformViewCreated,
            ));
      case TargetPlatform.fuchsia:
        throw UnsupportedError('Unsupported platform view');
      case TargetPlatform.iOS:
        return VisibilityDetector(
            key: const Key(viewType),
            onVisibilityChanged: _handleVisibilityChange,
            child: UiKitView(
              viewType: viewType,
              onPlatformViewCreated: _onPlatformViewCreated,
            ));
      case TargetPlatform.linux:
        throw UnsupportedError('Unsupported platform view');
      case TargetPlatform.macOS:
        throw UnsupportedError('Unsupported platform view');
      case TargetPlatform.windows:
        throw UnsupportedError('Unsupported platform view');
    }
  }

  void _onPlatformViewCreated(int id) {
    controller.getCameraPermission().then((value) {
      if (value!) {
        controller.initCamera(
          barcodeType: widget.barcodeType,
          fill: widget.fill,
          initFlash: widget.initFlash,
          cameraType: widget.cameraType,
          hasBarcodeReader: widget.hasBarcodeReader,
        );

        controller.setMethodCallHandler(handler: _methodCallHandler);
      } else {
        _onPlatformViewCreated(id);
      }
    });
  }

  void _handleVisibilityChange(VisibilityInfo info) {
    if (info.visibleFraction == 0) {
      controller.changeCameraVisibility(visibility: false);
    } else {
      controller.changeCameraVisibility(visibility: true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // print("Flutter Life Cycle: resumed");
        controller.resumeCamera();
        break;
      case AppLifecycleState.inactive:
        // print("Flutter Life Cycle: inactive");
        // if (Platform.isIOS) {
        controller.pauseCamera();
        // }
        break;
      case AppLifecycleState.paused:
        // print("Flutter Life Cycle: paused");
        controller.pauseCamera();
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<dynamic> _methodCallHandler(MethodCall methodCall) async {
    if (methodCall.method == "onBarcodeRead") {
      String barcode = methodCall.arguments.toString();
      if (widget.onBarcodeRead == null) {
        log("Barcode $barcode Detected but no OnBarcodeRead is Implemented");
      } else {
        widget.onBarcodeRead!(barcode);
      }
    }

    return null;
  }
}
