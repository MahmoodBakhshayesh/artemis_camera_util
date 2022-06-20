import Flutter
import UIKit

public class SwiftArtemisCameraKitPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "artemis_camera_kit", binaryMessenger: registrar.messenger())
    let instance = SwiftArtemisCameraKitPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
      
    let factory = CameraViewFactory(messenger: registrar.messenger())
    registrar.register(factory, withId: "<platform-view-type>")
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
