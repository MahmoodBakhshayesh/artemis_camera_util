package com.example.artemis_camera_kit;

import android.Manifest;
import android.content.Context;
import android.content.pm.PackageManager;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.platform.PlatformViewRegistry;

/** ArtemisCameraKitPlugin */
public class ArtemisCameraKitPlugin implements FlutterPlugin, ActivityAware,MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private PlatformViewRegistry registry;
  private MethodChannel channel;
  private FlutterActivity flutterActivity;
  private BinaryMessenger binaryMessenger;
  private Context context;
  private FlutterPluginBinding flutterPluginBinding;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    registry = flutterPluginBinding.getPlatformViewRegistry();
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "artemis_camera_kit");
    this.flutterPluginBinding = flutterPluginBinding;
    binaryMessenger = flutterPluginBinding.getBinaryMessenger();
//    ActivityPluginBinding pluginBinding = flutterActivity.bin;
//    flutterPluginBinding.getPlatformViewRegistry().registerViewFactory("<platform-view-type>", new CameraViewFactory(flutterPluginBinding,this));
    context = flutterPluginBinding.getApplicationContext();

//    channel.setMethodCallHandler(this);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("getPlatformVersion")) {
      result.success("Android22 " + android.os.Build.VERSION.RELEASE);
    } else if(call.method.equals("getCameraPermission")){
      result.success(true);
    } else {
      result.notImplemented();
    }
  }


  public boolean getCameraPermission ( ){
    if (ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) == PackageManager.PERMISSION_DENIED){

    }else{
//      ActivityCompat.requestPermissions(activity, new String[] {Manifest.permission.CAMERA}, requestCode)
    }
    return true;
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    flutterActivity = (FlutterActivity) binding.getActivity();
    System.out.println("onAttachedToActivity");
//    binding.getActivity();
    registry.registerViewFactory("<platform-view-type>",new CameraViewFactory(binding,binaryMessenger));
//    flutterPluginBinding.getPlatformViewRegistry().registerViewFactory("<platform-view-type>", new CameraViewFactory(binding,binaryMessenger));
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {

  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {

  }

  @Override
  public void onDetachedFromActivity() {
    channel.setMethodCallHandler(null);
  }
}
