import 'dart:convert';
import 'dart:developer';
import 'package:artemis_camera_kit/artemis_camera_kit_controller.dart';
import 'package:artemis_camera_kit/artemis_camera_kit_platform_interface.dart';
import 'package:artemis_camera_kit/artemis_camera_kit_view.dart';
import 'package:flutter/material.dart';

import 'package:artemis_camera_kit/artemis_camera_kit.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ArtemisCameraKitController cameraKitController = ArtemisCameraKitController();
  List<String> barcodes = [];
  String address = "";

  @override
  void initState() {
    super.initState();
    // initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  // Future<void> initPlatformState() async {
  //   bool cameraPermission;
  //   try {
  //     cameraPermission = await _artemisCameraKitPlugin.getCameraPermission() ?? false;
  //   } on PlatformException {
  //     cameraPermission = false;
  //   }
  //
  //   if (!mounted) return;
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            children: [
              Wrap(
                direction: Axis.horizontal,
                children: [
                  TextButton(
                      onPressed: () {
                        cameraKitController.getCameraPermission().then((value) {
                          log(value.toString());
                        });
                      },
                      child: const Text("Get Camera Permission")),
                  TextButton(
                      onPressed: () {
                        cameraKitController.initCamera(hasBarcodeReader: true).then((value) {});
                      },
                      child: const Text("init Camera")),
                  TextButton(
                      onPressed: () {
                        cameraKitController.changeFlashMode(mode: FlashMode.on);
                      },
                      child: const Text("F on")),
                  TextButton(
                      onPressed: () {
                        cameraKitController.changeFlashMode(mode: FlashMode.off);
                      },
                      child: const Text("F off")),
                  TextButton(
                      onPressed: () {
                        cameraKitController.pauseCamera();
                      },
                      child: const Text("Pause")),
                  TextButton(
                      onPressed: () {
                        cameraKitController.resumeCamera();

                      },
                      child: const Text("Resume")),
                  TextButton(
                      onLongPress: () {
                        cameraKitController.getBarcodesFromImage(address).then((value) {
                          if (value == null) {
                            print("NULL Bar");
                          } else {
                            print(value.toJson());
                          }
                        });
                      },
                      onPressed: () {
                        cameraKitController.takePicture().then((imgPath) {
                          log(imgPath.toString());
                          // address = imgPath;
                          if (imgPath != null) {
                            address = imgPath;
                            cameraKitController.processImageFromPath(imgPath).then((value) {
                              if (value == null) {
                                print("NULL OCR");
                              } else {
                                print(value.toJson());
                                // print(value.barcodeData?.barcodes.length);
                              }
                            });
                          }
                        });
                      },
                      child: const Text("Take Pic")),
                ],
              ),
              Expanded(
                  child: ArtemisCameraKitView(
                fill: true,
                initFlash: FlashMode.off,
                mode: UsageMode.barcodeScanner,
                onBarcodeRead: (c){
                  log("barcode Read ${c}");
                },
                onOcrRead: (o) {
                  log("Text Read ${o.text}");
                },
              ))
            ],
          ),
        ),
      ),
    );
  }
}
