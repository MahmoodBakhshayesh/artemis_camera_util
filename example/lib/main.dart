import 'dart:convert';
import 'dart:developer';

import 'package:artemis_camera_kit/ArtemisCameraKitView.dart';
import 'package:artemis_camera_kit/artemis_camera_kit_platform_interface.dart';
// import 'package:artemis_camera_kit_example/ArtemisCameraKitView.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
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
  String _platformVersion = 'Unknown';
  bool _cameraPermission = false;
  final _artemisCameraKitPlugin = ArtemisCameraKit();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    bool cameraPermission;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      // platformVersion =
      //     await _artemisCameraKitPlugin.getPlatformVersion() ?? 'Unknown platform version';
      cameraPermission = await _artemisCameraKitPlugin.getCameraPemission() ?? false;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
      cameraPermission = false;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      // _platformVersion = platformVersion;
      _cameraPermission = cameraPermission;
    });
  }

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
                        _artemisCameraKitPlugin.getCameraPemission().then((value) {
                          print(value);
                        });
                      },
                      child: const Text("Get Camera Permission")),
                  TextButton(
                      onPressed: () {
                        _artemisCameraKitPlugin.initCamera(hasBarcodeReader: true).then((value) {});
                      },
                      child: const Text("init Camera")),
                  TextButton(
                      onPressed: () {
                        _artemisCameraKitPlugin.changeFlashMode(mode:FlashMode.on);
                      },
                      child: const Text("F on")),
                  TextButton(
                      onPressed: () {
                        _artemisCameraKitPlugin.changeFlashMode(mode:FlashMode.off);
                      },
                      child: const Text("F off")),
                  TextButton(
                      onPressed: () {
                        _artemisCameraKitPlugin.pauseCamera();
                      },
                      child: const Text("Pause")),
                  TextButton(
                      onPressed: () {
                        _artemisCameraKitPlugin.resumeCamera();
                      },
                      child: const Text("Resume")),
                  TextButton(
                      onPressed: () {
                        _artemisCameraKitPlugin.takePicture().then((imgPath){
                          log(imgPath.toString());
                          if(imgPath!=null) {
                            _artemisCameraKitPlugin.processImageFromPath(imgPath).then((value) {
                              log(jsonEncode(value?.toJson()));
                            });
                          }
                        });
                      },
                      child: const Text("Take Pic")),
                ],
              ),
              const Expanded(child:  ArtemisCameraKitView())
            ],
          ),
        ),
      ),
    );
  }
}
