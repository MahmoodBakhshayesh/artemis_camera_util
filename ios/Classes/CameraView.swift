import Flutter
import UIKit


import Foundation
import AVFoundation
import MLKitBarcodeScanning
import MLKitTextRecognition
import MLKitCommon
import MLKitVision


@available(iOS 10.0, *)
class CameraView: NSObject, FlutterPlatformView, AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var _view: UIView
    let channel: FlutterMethodChannel
    let frame: CGRect
    //    var hasBarcodeReader:Bool!
    var imageSavePath:String!
    var isCameraVisible:Bool! = true
    var initCameraFinished:Bool! = false
    var isFillScale:Bool!
    var flashMode:AVCaptureDevice.FlashMode!
    var cameraPosition: AVCaptureDevice.Position!
    var previewView : UIView!
    var videoDataOutput: AVCaptureVideoDataOutput!
    var videoDataOutputQueue: DispatchQueue!
    var photoOutput: AVCapturePhotoOutput?
    var previewLayer:AVCaptureVideoPreviewLayer!
    var captureDevice : AVCaptureDevice!
    let session = AVCaptureSession()
    var barcodeScanner:BarcodeScanner!
    var textRecognizer : TextRecognizer?
    var flutterResultTakePicture:FlutterResult!
    var flutterResultOcr:FlutterResult!
    var orientation : UIImage.Orientation!
    
    /// 0:camera 1:barcodeScanner 2:ocrReader
    var usageMode:Int = 0
    
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        _view = UIView()
        self.channel = FlutterMethodChannel(name:"artemis_camera_kit",binaryMessenger: messenger!)
        self.frame = frame
        
        super.init()
        self.channel.setMethodCallHandler(handle)
        createNativeView(view: _view)
    }
    
    func view() -> UIView {
        if previewView == nil {
            self.previewView = UIView(frame: frame)
            //            previewView.contentMode = UIView.ContentMode.scaleAspectFill
        }
        return previewView
    }
    
    func createNativeView(view _view: UIView){
        _view.backgroundColor = UIColor.blue
        let nativeLabel = UILabel()
        nativeLabel.text = "Native text from iOS"
        nativeLabel.textColor = UIColor.white
        nativeLabel.textAlignment = .center
        nativeLabel.frame = CGRect(x: 0, y: 0, width: 180, height: 48.0)
        _view.addSubview(nativeLabel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments
        let myArgs = args as? [String: Any]
        switch call.method {
        case "getCameraPermission":
            self.getCameraPermission(flutterResult: result)
            break
        case "initCamera":
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                let initFlashModeID = (myArgs?["initFlashModeID"] as! Int);
                let modeID = (myArgs?["modeID"] as! Int);
                let fill = (myArgs?["fill"] as! Bool);
                let barcodeTypeID = (myArgs?["barcodeTypeID"] as! Int);
                let cameraTypeID = (myArgs?["cameraTypeID"] as! Int);
                
                self.initCamera( flashMode: initFlashModeID, fill: fill, barcodeTypeID: barcodeTypeID, cameraID: cameraTypeID,modeID: modeID)
                
            }
            break
        case "changeFlashMode":
            let flashModeID = (myArgs?["flashModeID"] as! Int);
            self.setFlashMode(flashMode: flashModeID)
            self.changeFlashMode()
            break
        case "changeCameraVisibility":
            let visibility = (myArgs?["visibility"] as! Bool)
            self.changeCameraVisibility(visibility: visibility)
            break
        case "pauseCamera":
            self.pauseCamera();
            break
        case "resumeCamera":
            self.resumeCamera()
            break
        case "takePicture":
            let path = (myArgs?["path"] as! String);
            self.takePicture(path:path,flutterResult: result)
            break
        case "processImageFromPath":
            let path = (myArgs?["path"] as! String);
            self.processImageFromPath(path: path, flutterResult:result)
            break
        case "getBarcodesFromPath":
            let path = (myArgs?["path"] as! String);
            let orientation = (myArgs?["orientation"] as! Int?);
            self.getBarcodeFromPath(path: path, flutterResult:result,orient: orientation)
            break
        case "dispose":
            self.getCameraPermission(flutterResult: result)
            break
        default:
            result(false)
        }
        
    }
    
    
    
    
    func getCameraPermission(flutterResult:  @escaping FlutterResult) {
        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
            flutterResult(true as Bool)
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
                    if granted {
                        flutterResult(true as Bool)
                    } else {
                        flutterResult(false as Bool)
                    }
                })
            }
        }
    }
    
    
    func initCamera( flashMode: Int, fill: Bool, barcodeTypeID: Int, cameraID: Int, modeID: Int) {
        print("Usage Mode set to "+String(modeID))
        self.usageMode = modeID
        self.isFillScale = fill
        self.cameraPosition = cameraID == 0 ? .back : .front
        var myBarcodeMode: Int
        setFlashMode(flashMode: flashMode)
        if (usageMode == 1){
            if barcodeTypeID == 0 {
                myBarcodeMode = 65535
            }
            else {
                myBarcodeMode = barcodeTypeID
            }
            let barcodeOptions = BarcodeScannerOptions(formats:
                                                        BarcodeFormat(rawValue: myBarcodeMode))
            barcodeScanner = BarcodeScanner.barcodeScanner(options: barcodeOptions)
        }
        
        textRecognizer = TextRecognizer.textRecognizer()
        self.setupAVCapture()
    }
    
    @available(iOS 10.0, *)
    func setupAVCapture(){
        session.sessionPreset = AVCaptureSession.Preset.hd1920x1080
        guard let device = AVCaptureDevice
            .default(AVCaptureDevice.DeviceType.builtInWideAngleCamera,
                     for: .video,
                     position: cameraPosition) else {
            return
        }
        captureDevice = device
        
        
        beginSession()
        changeFlashMode()
    }
    
    func beginSession(isFirst: Bool = true){
        var deviceInput: AVCaptureDeviceInput!
        
        
        do {
            deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            guard deviceInput != nil else {
                print("error: cant get deviceInput")
                return
            }
            
            if self.session.canAddInput(deviceInput){
                self.session.addInput(deviceInput)
            }
            
            orientation = imageOrientation(
                fromDevicePosition: cameraPosition
            )
            
            if(usageMode == 1){
                videoDataOutput = AVCaptureVideoDataOutput()
                videoDataOutput.alwaysDiscardsLateVideoFrames=true
                
                videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
                videoDataOutput.setSampleBufferDelegate(self, queue:self.videoDataOutputQueue)
                if session.canAddOutput(videoDataOutput!){
                    session.addOutput(videoDataOutput!)
                }
                videoDataOutput.connection(with: .video)?.isEnabled = true
                
            }else if(usageMode == 2){
                videoDataOutput = AVCaptureVideoDataOutput()
                videoDataOutput.alwaysDiscardsLateVideoFrames = true
                
                videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
                videoDataOutput.setSampleBufferDelegate(self, queue:self.videoDataOutputQueue)
                if session.canAddOutput(videoDataOutput!){
                    session.addOutput(videoDataOutput)
                }
                videoDataOutput.connection(with: .video)?.isEnabled = true
            }
            
            AudioServicesDisposeSystemSoundID(1108)
            photoOutput = AVCapturePhotoOutput()
            photoOutput?.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecJPEG])], completionHandler: nil)
            if session.canAddOutput(photoOutput!){
                session.addOutput(photoOutput!)
            }
            
            
            
            
            previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
            if self.isFillScale == true {
                previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            } else {
                previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
            }
            
            startSession(isFirst: isFirst)
            
            
        } catch let error as NSError {
            deviceInput = nil
            print("error: \(error.localizedDescription)")
        }
    }
    
    func startSession(isFirst: Bool) {
        DispatchQueue.main.async {
            let rootLayer :CALayer = self.previewView.layer
            rootLayer.masksToBounds = true
            if(rootLayer.bounds.size.width != 0 && rootLayer.bounds.size.width != 0){
                self.previewLayer.frame = rootLayer.bounds
                rootLayer.addSublayer(self.previewLayer)
                self.session.startRunning()
                if isFirst == true {
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
                        self.initCameraFinished = true
                    }
                }
            } else {
                DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                    self.startSession(isFirst: isFirst)
                }
            }
        }
    }
    
    func setFlashMode(flashMode: Int) {
        if flashMode == 2 {
            self.flashMode = .auto
        } else if flashMode == 1 {
            self.flashMode = .on
        } else if flashMode == 0{
            self.flashMode = .off
        }
    }
    
    func changeFlashMode() {
        
        if(self.usageMode>0) {
            do{
                if (captureDevice.hasFlash)
                {
                    try captureDevice.lockForConfiguration()
                    captureDevice.torchMode = (self.flashMode == .auto) ?(.auto):(self.flashMode == .on ? (.on) : (.off))
                    captureDevice.flashMode = self.flashMode
                    captureDevice.unlockForConfiguration()
                }
            }catch{
                //DISABEL FLASH BUTTON HERE IF ERROR
                print("Device tourch Flash Error ");
            }
            
        }
    }
    
    func pauseCamera() {
        if self.initCameraFinished == true {
            self.stopCamera()
            self.isCameraVisible = false
        }
    }
    
    
    
    func resumeCamera() {
        if  self.initCameraFinished == true {
            self.session.startRunning()
            self.isCameraVisible = true
        }
    }
    
    func stopCamera(){
        if session.isRunning {
            session.stopRunning()
        }
    }
    
    func changeCameraVisibility(visibility:Bool){
        if visibility == true {
            if self.isCameraVisible == false {
                self.session.startRunning()
                self.isCameraVisible = true
            }
        } else {
            if self.isCameraVisible == true {
                self.stopCamera()
                self.isCameraVisible = false
            }
        }
    }
    
    
    func takePicture(path :String,flutterResult:  @escaping FlutterResult){
        self.imageSavePath = path;
        self.flutterResultTakePicture = flutterResult;
        let settings = AVCapturePhotoSettings()
        if captureDevice.hasFlash {
            settings.flashMode = self.flashMode
        }
        photoOutput?.capturePhoto(with: settings, delegate:self)
    }
    
    func processImageFromPath(path:String,flutterResult:  @escaping FlutterResult){
        let fileURL = URL(fileURLWithPath: path)
        do {
            self.flutterResultOcr = flutterResult
            let imageData = try Data(contentsOf: fileURL)
            let image = UIImage(data: imageData)
            if image == nil {
                return
            }
            let visionImage = VisionImage(image: image!)
            visionImage.orientation = image!.imageOrientation
            print("Go TO processImage")
            processImage(visionImage: visionImage, selectedImagePath: path)
        } catch {
            print("Error loading image : \(error)")
        }
        
    }
    
    
    
    func getBarcodeFromPath(path:String,flutterResult:  @escaping FlutterResult,orient:Int?){
        let fileURL = URL(fileURLWithPath: path)
        do {
            self.flutterResultOcr = flutterResult
            let imageData = try Data(contentsOf: fileURL)
            let image = UIImage(data: imageData)
            if image == nil {
                return
            }
            let visionImage = VisionImage(image: image!)
            if(orient==nil){
                let ori = image?.imageOrientation
                print("Image Orientation is \(ori?.rawValue)")
//                visionImage.orientation = imageOrientation(fromDevicePosition: cameraPosition)
                visionImage.orientation = ori!
            }else{
                visionImage.orientation = UIImage.Orientation.init(rawValue: orient!)!
            }
            
            print("Go TO processImage")
            processBarcodeImage(visionImage: visionImage, selectedImagePath: path,flutterResult:flutterResult)
        } catch {
            print("Error loading image : \(error)")
        }
        
    }
    
    func imageOrientation2(
      deviceOrientation: UIDeviceOrientation,
      cameraPosition: AVCaptureDevice.Position
    ) -> UIImage.Orientation {
      switch deviceOrientation {
      case .portrait:
        return cameraPosition == .front ? .leftMirrored : .right
      case .landscapeLeft:
        return cameraPosition == .front ? .downMirrored : .up
      case .portraitUpsideDown:
        return cameraPosition == .front ? .rightMirrored : .left
      case .landscapeRight:
        return cameraPosition == .front ? .upMirrored : .down
      case .faceDown, .faceUp, .unknown:
        return .up
      }
    }
    
    
    
    
    
    
    private func currentUIOrientation() -> UIDeviceOrientation {
        let deviceOrientation = { () -> UIDeviceOrientation in
            switch UIApplication.shared.statusBarOrientation {
            case .landscapeLeft:
                return .landscapeRight
            case .landscapeRight:
                return .landscapeLeft
            case .portraitUpsideDown:
                return .portraitUpsideDown
            case .portrait, .unknown:
                return .portrait
            @unknown default:
                fatalError()
            }
        }
        guard Thread.isMainThread else {
            var currentOrientation: UIDeviceOrientation = .portrait
            DispatchQueue.main.sync {
                currentOrientation = deviceOrientation()
            }
            return currentOrientation
        }
        return deviceOrientation()
    }
    
    
    public func imageOrientation(
        fromDevicePosition devicePosition: AVCaptureDevice.Position = .back
    ) -> UIImage.Orientation {
        var deviceOrientation = UIDevice.current.orientation
        if deviceOrientation == .faceDown || deviceOrientation == .faceUp
            || deviceOrientation
            == .unknown
        {
            deviceOrientation = currentUIOrientation()
        }
        switch deviceOrientation {
        case .portrait:
            return devicePosition == .front ? .leftMirrored : .right
        case .landscapeLeft:
            return devicePosition == .front ? .downMirrored : .up
        case .portraitUpsideDown:
            return devicePosition == .front ? .rightMirrored : .left
        case .landscapeRight:
            return devicePosition == .front ? .upMirrored : .down
        case .faceDown, .faceUp, .unknown:
            return .up
        @unknown default:
            fatalError()
        }
    }
    
    func saveImage(image: UIImage) -> Bool {
        guard let data = image.jpegData(compressionQuality: 1) ?? image.pngData() else {
            return false
        }
        var fileURL : URL? = nil
        if self.imageSavePath == "" {
            guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL else {
                return false
            }
            fileURL = directory.appendingPathComponent("pic.jpg")!
        } else  {
            fileURL = URL(fileURLWithPath: self.imageSavePath)
        }
        
        
        
        
        
        
        
        guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL else {
            return false
        }
        do {
            try data.write(to: fileURL!)
            flutterResultTakePicture(fileURL?.path)
            //print(directory)
            return true
        } catch {
            print(error.localizedDescription)
            flutterResultTakePicture(FlutterError(code: "-103", message: error.localizedDescription, details: nil))
            return false
        }
    }
    
    public func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?,
                            resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Swift.Error?) {
        AudioServicesDisposeSystemSoundID(1108)
        if let error = error { //self.photoCaptureCompletionBlock?(nil, error)
            flutterResultTakePicture(FlutterError(code: "-101", message: error.localizedDescription, details: nil))
        }
        
        else if let buffer = photoSampleBuffer, let data = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: buffer, previewPhotoSampleBuffer: nil),
                let image = UIImage(data: data) {
            
            self.saveImage(image: image)
        }
        
        else {
            
            flutterResultTakePicture(FlutterError(code: "-102", message: "Unknown error", details: nil))
        }
    }
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        if(usageMode==1){
            
            // do stuff here
            if barcodeScanner != nil {
                let visionImage = VisionImage(buffer: sampleBuffer)
                let orientation = imageOrientation(
                    fromDevicePosition: cameraPosition
                )
                visionImage.orientation = orientation
                var barcodes: [Barcode]
                do {
                    barcodes = try self.barcodeScanner.results(in: visionImage)
                } catch let error {
                    print("Failed to scan barcodes with error: \(error.localizedDescription).")
                    return
                }
                
                guard !barcodes.isEmpty else {
                    //print("Barcode scanner returrned no results.")
                    return
                }
                
                for barcode in barcodes {
                    onBarcodeRead(barcode: barcode.rawValue!)
                }
            }
            //
            //            if(false) {
            //                let visionImage = VisionImage(buffer: sampleBuffer)
            //                visionImage.orientation = orientation
            //                processImage(visionImage: visionImage)
            //            }
        }else if(usageMode == 2){
            if(textRecognizer != nil) {
                let visionImage = VisionImage(buffer: sampleBuffer)
                visionImage.orientation = orientation
                
                do {
                    let result = try textRecognizer?.results(in: visionImage)
                    
                    if(result?.text != "") {
                        var listLineModel: [LineModel] = []
                        
                        for b in result!.blocks {
                            for l in b.lines{
                                let lineModel : LineModel = LineModel()
                                lineModel.text = l.text
                                
                                
                                
                                for c in l.cornerPoints {
                                    lineModel.cornerPoints.append(CornerPointModel(x: c.cgPointValue.x, y: c.cgPointValue.y))
                                }
                                
                                listLineModel.append(lineModel)
                                
                            }
                        }
                        
                        
                        self.onTextRead(text: result!.text, values: listLineModel, path: "", orientation:  visionImage.orientation.rawValue)
                        
                    } else {
                        
                        self.onTextRead(text: "", values: [], path: "", orientation:  nil)
                    }
                    
                    
                    
                } catch {
                    print("can't fetch result")
                }
            }
        }
        
    }
    
    func onBarcodeRead(barcode: String) {
        channel.invokeMethod("onBarcodeRead", arguments: barcode)
    }
    
    func processBarcodeImage(visionImage: VisionImage, image: UIImage? = nil, selectedImagePath : String? = nil,flutterResult:  @escaping FlutterResult) {
        
//        let orientation = imageOrientation(fromDevicePosition: cameraPosition)
//        visionImage.orientation = orientation
        print("Looking In barcode with orinet \(visionImage.orientation.rawValue)")
        let format = BarcodeFormat.all
        let barcodeOptions = BarcodeScannerOptions(formats: format)
        
        let bs = BarcodeScanner.barcodeScanner(options: barcodeOptions)
        
        visionImage.orientation = UIImage.Orientation.up
        
        var imageBarcodeObjects: [BarcodeObject] = []
        bs.process(visionImage) { features, error in
            guard error == nil, let features = features else {
                print("error happended ")
                return
            }
            for barcode in features {
                let barcodeObj : BarcodeObject = BarcodeObject()
                let corners = barcode.cornerPoints
                
                
                for c in corners ?? [] {
                    barcodeObj.cornerPoints.append(CornerPointModel(x: c.cgPointValue.x, y: c.cgPointValue.y))
                }
                
                barcodeObj.rawValue = barcode.rawValue;
                barcodeObj.orientation = visionImage.orientation.rawValue;
                barcodeObj.type = barcode.valueType.rawValue;
                barcodeObj.value = barcode.displayValue;
                
                imageBarcodeObjects.append(barcodeObj)
            }
            
            let data = BarcodeData(path: "", orientation: visionImage.orientation.rawValue, barcodes:imageBarcodeObjects)
            let jsonEncoder = JSONEncoder()
            let jsonData = try! jsonEncoder.encode(data)
            let json = String(data: jsonData, encoding: String.Encoding.utf8)
            flutterResult(json)
        }

        
        
    }
    
    func onTextRead(text: String, values: [LineModel], path: String?, orientation: Int?) {
        let data = OcrData(text: text, path: path, orientation: orientation, lines: values)
        let jsonEncoder = JSONEncoder()
        let jsonData = try! jsonEncoder.encode(data)
        let json = String(data: jsonData, encoding: String.Encoding.utf8)
        channel.invokeMethod("onTextRead", arguments: json)
    }
    
    func textRead(text: String, values: [LineModel], path: String?, orientation: Int?) {
        
        
        let data = OcrData(text: text, path: path, orientation: orientation, lines: values)
        let jsonEncoder = JSONEncoder()
        let jsonData = try! jsonEncoder.encode(data)
        let json = String(data: jsonData, encoding: String.Encoding.utf8)
        flutterResultOcr(json)
    }
    
    
    func processImage(visionImage: VisionImage, image: UIImage? = nil, selectedImagePath : String? = nil) {
        if textRecognizer != nil {
            
            var path : String?
            path = selectedImagePath
            
            textRecognizer?.process(visionImage) { result, error in
                guard error == nil, let result = result else {
                    // Error handling
                    self.textRead(text: "Error: " + error.debugDescription, values: [], path: "", orientation: nil)
                    return
                }
                // Recognized text
                
                
                if(result.text != "") {
                    var listLineModel: [LineModel] = []
                    
                    for b in result.blocks {
                        for l in b.lines{
                            let lineModel : LineModel = LineModel()
                            lineModel.text = l.text
                            
                            
                            
                            for c in l.cornerPoints {
                                lineModel.cornerPoints
                                    .append(
                                        CornerPointModel(x: c.cgPointValue.x, y: c.cgPointValue.y))
                            }
                            
                            
                            
                            listLineModel.append(lineModel)
                            
                        }
                    }
                    
                    
                    self.textRead(text: result.text, values: listLineModel, path: path, orientation:  visionImage.orientation.rawValue)
                    
                } else {
                    
                    self.textRead(text: "", values: [], path: path, orientation:  nil)
                }
            }
            
            
        }
    }
    
    
    
    
    
    
    
}

struct OcrData: Codable {
    var text: String?
    var path: String?
    var orientation: Int?
    var lines: [LineModel]=[]
}

// Encode


class LineModel: Codable {
    var text:String = ""
    var cornerPoints : [CornerPointModel] = []
}


class CornerPointModel: Codable {
    
    init(x:CGFloat, y:CGFloat) {
        self.x = x
        self.y = y
    }
    
    var x:CGFloat
    var y:CGFloat
}

class BarcodeObject: Codable {
    var rawValue:String? = ""
    var value:String? = ""
    var type:Int? = 0
    var orientation: Int?
    var cornerPoints : [CornerPointModel] = []
}


struct BarcodeData: Codable {
    var path: String?
    var orientation: Int?
    var barcodes: [BarcodeObject]=[]
}

