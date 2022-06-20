package com.example.artemis_camera_kit;

import android.content.Context;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.Map;

import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

public class CameraViewFactory extends PlatformViewFactory {
    private ActivityPluginBinding activityPluginBinding;
    private BinaryMessenger dartExecutor;


    public CameraViewFactory(ActivityPluginBinding activityPluginBinding,BinaryMessenger dartExecutor) {
        super(StandardMessageCodec.INSTANCE);
        this.activityPluginBinding = activityPluginBinding;
        this.dartExecutor = dartExecutor;
    }

    @NonNull
    @Override
    public PlatformView create(@NonNull Context context, int id, @Nullable Object args) {
        final Map<String, Object> creationParams = (Map<String, Object>) args;

//        this.channel = new MethodChannel(dartExecutor, "plugins/camera_kit_" + viewId);
//        this.activityPluginBinding = activityPluginBinding;
//        this.channel.setMethodCallHandler(this);
//        this.context = activityPluginBinding.getActivity().getApplicationContext();
//        if (getCameraView() == null) {
//            cameraView = new CameraBaseView(activityPluginBinding.getActivity(), this);
//        }
        return new com.example.artemis_camera_kit.CameraView(activityPluginBinding,dartExecutor,id);
//        return new com.example.artemis_camera_kit.CameraView(context, id, creationParams);
    }
}
