package com.example.artemis_camera_kit;

import io.flutter.plugin.common.MethodChannel;

public interface FlutterMethodListener {

    void onBarcodeRead(String barcode);

    void onTakePicture(MethodChannel.Result result, String filePath);
}
