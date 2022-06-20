package com.example.artemis_camera_kit;

import android.widget.FrameLayout;

import io.flutter.plugin.common.MethodChannel;

public interface CameraViewInterface {

    void initCamera( boolean hasBarcodeReader, int flashModeID, boolean fill, int barcodeMode, int cameraSelector);
    void changeCameraVisibility(boolean isCameraVisible);
    void changeFlashMode(int flashModeID);
    void takePicture(String path, final MethodChannel.Result result);
    void pauseCamera();
    void resumeCamera();
    void dispose();

}
