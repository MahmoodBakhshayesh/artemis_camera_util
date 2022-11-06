# artemis_camera_kit

ArtemisCameraKit uses native android and ios APIs for taking picture and ScanningBarcode and Text Recognition

Main features:
- Easy implementation 
- Automatic permission handling (no need for 3rd-party libraries)
- Automatic camera resource handling for battery usage and avoid any conflict with another camera based applications.(you can also manage manually pause and resume camera)
- `fill` property for camera preview frame.
- Optimize memory usage in taking picture
- `auto`, `on` and `off` flash mode while taking picture and scan barcode.



## Getting Started


# Installation

## iOS
Add `io.flutter.embedded_views_preview` in info.plist with value `YES`.
Add `Privacy - Camera Usage Description` in info.plist.


# Usage

Create an instance of `ArtemisCameraKitController` then initial `ArtemisCameraKitView` passing `ArtemisCameraKitController` instance to it for better handling.
```
    final controller = ArtemisCameraKitController();
```
Use Widget in Build:
```
    ArtemisCameraKitView(
                fill: true,
                initFlash: FlashMode.off,
                barcodeType: BarcodeType.allFormats,
                mode: UsageMode.barcodeScanner,
                onBarcodeRead: (b) {
                  log("Barcode Read $b");
                },
              )
```
or for text recognition Mode:
```
    ArtemisCameraKitView(
                fill: true,
                initFlash: FlashMode.off,
                mode: UsageMode.ocrReader,
                onOcrRead: (o) {
                  log("Text Read ${o.text}");
                },
              )
```

**Pause and Resume camera**
This plugin automatically manage pause and resume camera based on android, iOS life cycle and widget visibility, also you can call with your controller when ever you need.
```
    controller.pauseCamera();
    controller.resumeCamera();
```

**Taking Picture**
This plugin can be used to take picture of current stream in order to use for other operations
```
    String? imgPath = await cameraKitController.takePicture();
```

**Barcode Scanning or Text Recognition from image**
This plugin can be used to take picture of current stream in order to use for other operations
```
    String? imgPath = await cameraKitController.takePicture();
    OcrData? ocr = awat cameraKitController.processImageFromPath(imgPath);
    BarcodeData barcode = cameraKitController.getBarcodesFromImage(imgPath);
    
```
**OCR functionalities are Disable in Android Because of mlkit limitations**


