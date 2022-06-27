package com.example.artemis_camera_kit;

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.content.res.Configuration;
import android.graphics.Color;
import android.graphics.Point;
import android.graphics.SurfaceTexture;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraManager;
import android.hardware.camera2.params.StreamConfigurationMap;
import android.media.Image;
import android.net.Uri;
import android.os.Build;
import android.util.DisplayMetrics;
import android.util.Log;
import android.util.Size;
import android.view.Surface;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.LinearLayout;

import androidx.annotation.NonNull;
import androidx.camera.core.AspectRatio;
import androidx.camera.core.Camera;
import androidx.camera.core.CameraSelector;
import androidx.camera.core.ImageAnalysis;
import androidx.camera.core.ImageCapture;
import androidx.camera.core.ImageCaptureException;
import androidx.camera.core.ImageProxy;
import androidx.camera.core.Preview;
import androidx.camera.lifecycle.ProcessCameraProvider;
import androidx.camera.view.PreviewView;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.lifecycle.LifecycleOwner;

import com.example.artemis_camera_kit.Model.CornerPointModel;
import com.example.artemis_camera_kit.Model.LineModel;
import com.google.common.util.concurrent.ListenableFuture;
import com.google.gson.Gson;
import com.google.mlkit.vision.barcode.BarcodeScanner;
import com.google.mlkit.vision.barcode.BarcodeScannerOptions;
import com.google.mlkit.vision.barcode.BarcodeScanning;
import com.google.mlkit.vision.barcode.common.Barcode;
import com.google.mlkit.vision.common.InputImage;
import com.google.mlkit.vision.text.Text;
import com.google.mlkit.vision.text.TextRecognition;
import com.google.mlkit.vision.text.TextRecognizer;
import com.google.mlkit.vision.text.latin.TextRecognizerOptions;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.concurrent.ExecutionException;

import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

import static android.content.ContentValues.TAG;


class CameraView implements PlatformView, CameraViewInterface, MethodChannel.MethodCallHandler, FlutterMethodListener {
    private static final int MAX_PREVIEW_WIDTH = 1920;
    private static final int MAX_PREVIEW_HEIGHT = 1080;

    @NonNull
    private final FrameLayout linearLayout;
    private final ActivityPluginBinding activityPluginBinding;
    private final Activity activity;
    private final Context context;
    private BarcodeScanner scanner;
    private TextRecognizer recognizer;
    private BarcodeScannerOptions options;
    final private MethodChannel channel;
    private ImageCapture imageCapture;
//    private boolean hasBarcodeReader;
    private int selectedCameraID;
    private int flashModeID;
    private int modeID;
    private Point displaySize;
    private PreviewView previewView;
    private ListenableFuture<ProcessCameraProvider> cameraProviderFuture;
    private ImageAnalysis imageAnalyzer;
    private boolean isCameraVisible = true;
    private ProcessCameraProvider cameraProvider;
    private Camera camera;
    private CameraSelector cameraSelector;
    private Preview preview;
    private Size optimalPreviewSize;

    public CameraView(ActivityPluginBinding activityPluginBinding, BinaryMessenger binaryMessenger, int viewId) {
        this.activityPluginBinding = activityPluginBinding;
        this.channel = new MethodChannel(binaryMessenger, "artemis_camera_kit");
        this.channel.setMethodCallHandler(this);
        this.activity = activityPluginBinding.getActivity();
        this.context = activityPluginBinding.getActivity().getApplicationContext();
        linearLayout = new FrameLayout(activity);
        linearLayout.setLayoutParams(new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.MATCH_PARENT));
        linearLayout.setBackgroundColor(Color.parseColor("#000000"));

    }

    @NonNull
    @Override
    public View getView() {
        return linearLayout;
    }


    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "getPlatformVersion":
                result.success("Android" + android.os.Build.VERSION.RELEASE);
                break;
            case "getCameraPermission":
                getCameraPermission(result);
                break;
            case "initCamera":
                int initFlashModeID = call.argument("initFlashModeID");
                boolean fill = Boolean.TRUE.equals(call.argument("fill"));
                int barcodeTypeID = call.argument("barcodeTypeID");
                int modeID = call.argument("modeID");
                int cameraID = call.argument("cameraTypeID");
                initCamera( initFlashModeID, fill, barcodeTypeID, cameraID, modeID);
                break;
            case "changeFlashMode":
                int flashModeID = call.argument("flashModeID");
                changeFlashMode(flashModeID);
                break;
            case "changeCameraVisibility":
                boolean visibility = Boolean.TRUE.equals(call.argument("visibility"));
                changeCameraVisibility(visibility);
                break;
            case "pauseCamera":
                pauseCamera();
                break;
            case "resumeCamera":
                resumeCamera();
                break;
            case "takePicture":
                String path = call.argument("path");
                takePicture(path, result);
                break;
            case "processImageFromPath":
                String imgPath = call.argument("path");
                processImageFromPath(imgPath, result);
                break;
            case "dispose":
                dispose();
                break;
            default:
                result.notImplemented();
                break;
        }
    }


    private void getCameraPermission(MethodChannel.Result result) {
        Log.println(Log.INFO, "ArtemisCameraUtil", "GettingCameraPermission");
        final int REQUEST_CAMERA_PERMISSION = 10001;
        if (ActivityCompat.checkSelfPermission(activity, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(activity, new String[]{Manifest.permission.CAMERA}, REQUEST_CAMERA_PERMISSION);
            activityPluginBinding.addRequestPermissionsResultListener((requestCode, permissions, grantResults) -> {
                for (int i : grantResults) {
                    if (i == PackageManager.PERMISSION_DENIED) {
                        try {
                            result.success(false);
                        } catch (Exception e) {
                            result.error("-1", e.getMessage(), e);
                        }
                    }
                }
                result.success(true);
                return false;
            });

        } else {
            result.success(true);
        }
    }

    @Override
    public void initCamera( int flashModeID, boolean fill, int barcodeTypeID, int cameraID, int modeID) {
        Log.println(Log.INFO, "ArtemisCameraUtil", "InitializingCamera");
        this.flashModeID = flashModeID;
        this.modeID = modeID;
        selectedCameraID = 0;

        if (cameraID == 0) {
            cameraSelector = new CameraSelector.Builder().requireLensFacing(CameraSelector.LENS_FACING_BACK).build();
        } else {
            cameraSelector = new CameraSelector.Builder().requireLensFacing(CameraSelector.LENS_FACING_FRONT).build();
        }

        if (modeID == 1) {
            options = new BarcodeScannerOptions.Builder().setBarcodeFormats(barcodeTypeID).build();
            scanner = BarcodeScanning.getClient(options);
        } else if (modeID == 2) {
            recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS);
        }


//        if (hasBarcodeReader) {
//            options = new BarcodeScannerOptions.Builder().setBarcodeFormats(barcodeTypeID).build();
//            scanner = BarcodeScanning.getClient(options);
//        }


        try {
            displaySize = new Point();
            DisplayMetrics displaymetrics = new DisplayMetrics();
            displaymetrics = context.getResources().getDisplayMetrics();
            int screenWidth = displaymetrics.widthPixels;
            int screenHeight = displaymetrics.heightPixels;
            displaySize.x = screenWidth;
            displaySize.y = screenHeight;
//            activity.getWindowManager().getDefaultDisplay().getSize(displaySize);
            if (fill) linearLayout.setLayoutParams(new FrameLayout.LayoutParams(displaySize.x, displaySize.y));
            previewView = new PreviewView(activity);
            previewView.setLayoutParams(new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
            previewView.setImplementationMode(PreviewView.ImplementationMode.COMPATIBLE);
            linearLayout.addView(previewView);

            startCamera();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }


    private void startCamera() {
        Log.println(Log.INFO, "ArtemisCameraUtil", "StaringCamera");
        cameraProviderFuture = ProcessCameraProvider.getInstance(context);

        cameraProviderFuture.addListener(() -> {
            try {
                prepareOptimalSize();
                imageCapture = new ImageCapture.Builder()
                        .setFlashMode(getFlashMode())
                        .setTargetResolution(new Size(optimalPreviewSize.getWidth(), optimalPreviewSize.getHeight()))
                        .setCaptureMode(ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY)
                        .build();

                if (modeID == 1) {
                    imageAnalyzer = new ImageAnalysis.Builder().build();
                    imageAnalyzer.setAnalyzer(Runnable::run, new BarcodeAnalyzer());
                } else if (modeID == 2) {
                    imageAnalyzer = new ImageAnalysis.Builder().build();
                    imageAnalyzer.setAnalyzer(Runnable::run, new OcrAnalyzer());
                }
                cameraProvider = cameraProviderFuture.get();
                bindPreview(cameraProvider);
            } catch (ExecutionException | InterruptedException e) {
                e.printStackTrace();
            }
        }, ContextCompat.getMainExecutor(context));
    }

    private void bindPreview(ProcessCameraProvider cameraProvider) {
        Log.println(Log.INFO, "ArtemisCameraUtil", "BindingCamera");
        cameraProvider.unbindAll();

        preview = new Preview.Builder().setTargetAspectRatio(AspectRatio.RATIO_16_9).
                setTargetRotation(previewView.getDisplay().getRotation()).build();


        preview.setSurfaceProvider(previewView.getSurfaceProvider());

        if(modeID==1){
            camera = cameraProvider.bindToLifecycle((LifecycleOwner) activity, cameraSelector, preview, imageAnalyzer, imageCapture);
        }else if(modeID ==2){
            camera = cameraProvider.bindToLifecycle((LifecycleOwner) activity, cameraSelector, preview, imageAnalyzer, imageCapture);
        } else {
            camera = cameraProvider.bindToLifecycle((LifecycleOwner) activity, cameraSelector, preview, imageCapture);
        }


    }

    private void prepareOptimalSize() {
        Log.println(Log.INFO, "ArtemisCameraUtil", "PreparingOptimalSize");
        int width = previewView.getWidth();
        int height = previewView.getHeight();
        CameraManager manager = (CameraManager) activity.getSystemService(Context.CAMERA_SERVICE);
        try {
            for (String cameraId : manager.getCameraIdList()) {
                CameraCharacteristics characteristics = manager.getCameraCharacteristics(cameraId);

                // We don't use a front facing camera in this sample.
                Integer facing = characteristics.get(CameraCharacteristics.LENS_FACING);
//                Boolean available = characteristics.get(CameraCharacteristics.FLASH_INFO_AVAILABLE);
                if (facing != null && facing == CameraCharacteristics.LENS_FACING_FRONT) {
                    if (selectedCameraID == 0)
                        continue;
                } else {
                    if (selectedCameraID == 1)
                        continue;
                }
                StreamConfigurationMap map = characteristics.get(
                        CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP);
                if (map == null) {
                    continue;
                }


                // Find out if we need to swap dimension to get the preview size relative to sensor
                // coordinate.
//                int displayRotation = activity.getWindowManager().getDefaultDisplay().getRotation();
                int displayRotation = activity.getResources().getConfiguration().orientation;

                Integer sensorOrientation = characteristics.get(CameraCharacteristics.SENSOR_ORIENTATION);
                boolean swappedDimensions = false;
                switch (displayRotation) {
                    case Surface.ROTATION_0:
                    case Surface.ROTATION_180:
                        if (sensorOrientation == 90 || sensorOrientation == 270) {
                            swappedDimensions = true;
                        }
                        break;
                    case Surface.ROTATION_90:
                    case Surface.ROTATION_270:
                        if (sensorOrientation == 0 || sensorOrientation == 180) {
                            swappedDimensions = true;
                        }
                        break;
                    default:
                        Log.e(TAG, "Display rotation is invalid: " + displayRotation);
                }


                int rotatedPreviewWidth = width;
                int rotatedPreviewHeight = height;
                int maxPreviewWidth = displaySize.x;
                int maxPreviewHeight = displaySize.y;

                if (swappedDimensions) {
                    rotatedPreviewWidth = height;
                    rotatedPreviewHeight = width;
                    maxPreviewWidth = displaySize.y;
                    maxPreviewHeight = displaySize.x;
                }

                if (maxPreviewWidth > MAX_PREVIEW_WIDTH) {
                    maxPreviewWidth = MAX_PREVIEW_WIDTH;
                }

                if (maxPreviewHeight > MAX_PREVIEW_HEIGHT) {
                    maxPreviewHeight = MAX_PREVIEW_HEIGHT;
                }

                // Danger, W.R.! Attempting to use too large a preview size could  exceed the camera
                // bus' bandwidth limitation, resulting in gorgeous previews but the storage of
                // garbage capture data.
                Size previewSize = chooseOptimalSize(map.getOutputSizes(SurfaceTexture.class),
                        rotatedPreviewWidth, rotatedPreviewHeight, maxPreviewWidth,
                        maxPreviewHeight);
                int orientation = activity.getResources().getConfiguration().orientation;
                if (orientation == Configuration.ORIENTATION_LANDSCAPE) {
                    optimalPreviewSize = new Size(previewSize.getWidth(), previewSize.getHeight());
                } else {
                    optimalPreviewSize = new Size(previewSize.getHeight(), previewSize.getWidth());
                }

                return;
            }
        } catch (CameraAccessException | NullPointerException e) {
            e.printStackTrace();
        }

    }

    private static Size chooseOptimalSize(Size[] choices, int textureViewWidth, int textureViewHeight, int maxWidth, int maxHeight) {

        Log.println(Log.INFO, "ArtemisCameraUtil", "ChoosingOptimalSize");
        // Collect the supported resolutions that are at least as big as the preview Surface
        List<Size> bigEnough = new ArrayList<>();
        // Collect the supported resolutions that are smaller than the preview Surface
        List<Size> notBigEnough = new ArrayList<>();

        int w = 16;
        int h = 9;
        for (Size option : choices) {
            if (option.getWidth() <= maxWidth && option.getHeight() <= maxHeight &&
                    option.getHeight() == option.getWidth() * h / w) {
                if (option.getWidth() >= textureViewWidth &&
                        option.getHeight() >= textureViewHeight) {
                    bigEnough.add(option);
                } else {
                    notBigEnough.add(option);
                }
            }
        }

        // Pick the smallest of those big enough. If there is no one big enough, pick the
        // largest of those not big enough.
        if (bigEnough.size() > 0) {
            return Collections.min(bigEnough, new CompareSizesByArea());
        } else if (notBigEnough.size() > 0) {
            return Collections.max(notBigEnough, new CompareSizesByArea());
        } else {
            Log.e(TAG, "Couldn't find any suitable preview size");
            return choices[0];
        }
    }

    @Override
    public void changeCameraVisibility(boolean isCameraVisible) {
        Log.println(Log.INFO, "ArtemisCameraUtil", "SettingCameraVisible");
        if (isCameraVisible != this.isCameraVisible) {
            this.isCameraVisible = isCameraVisible;
            if (isCameraVisible) resumeCamera();
            else pauseCamera();
        }

    }

    @Override
    public void changeFlashMode(int flashModeID) {
        Log.println(Log.INFO, "ArtemisCameraUtil", "ChangingFlashMode");
        imageCapture.setFlashMode(getFlashMode());
        if (camera != null) {
            camera.getCameraControl().enableTorch(flashModeID == 1);
        }
    }

    @Override
    public void takePicture(String path, MethodChannel.Result result) {
        Log.println(Log.INFO, "ArtemisCameraUtil", "TakingPicture");
        final File file = getPictureFile(path);
        ImageCapture.OutputFileOptions outputOptions = new ImageCapture.OutputFileOptions.Builder(file).build();


        // Set up image capture listener, which is triggered after photo has
        // been taken
        imageCapture.takePicture(
                outputOptions, ContextCompat.getMainExecutor(activity), new ImageCapture.OnImageSavedCallback() {
                    @Override
                    public void onImageSaved(@NonNull ImageCapture.OutputFileResults outputFileResults) {
                        activityPluginBinding.getActivity().runOnUiThread(() -> result.success(file + ""));
                    }

                    @Override
                    public void onError(@NonNull ImageCaptureException exception) {
                        activityPluginBinding.getActivity().runOnUiThread(() -> result.error("-1", exception.getMessage(), null));
                    }
                });
    }

    private File getPictureFile(String path) {
        if (path.equals(""))
            return new File(activity.getCacheDir(), "pic.jpg");
        else return new File(path);
    }

    @Override
    public void pauseCamera() {
        Log.println(Log.INFO, "ArtemisCameraUtil", "PausingCamera");
        cameraProvider.unbindAll();
        if (scanner != null) {
            scanner.close();
            scanner = null;
        }

    }

    @Override
    public void resumeCamera() {
        Log.println(Log.INFO, "ArtemisCameraUtil", "ResumingCamera");
        if (isCameraVisible) {
            if(modeID ==1){
                if (scanner == null) scanner = BarcodeScanning.getClient(options);
            }else if(modeID ==2){
                if (recognizer == null) recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS);
            }

            startCamera();
        }
    }

    @Override
    public void dispose() {
        Log.println(Log.INFO, "ArtemisCameraUtil", "DisposingCamera");
    }

    @Override
    public void onBarcodeRead(String barcode) {
        channel.invokeMethod("onBarcodeRead", barcode);
    }

    public void onTextRead(String ocrData) {
        channel.invokeMethod("onTextRead", ocrData);
    }


    @Override
    public void onTakePicture(MethodChannel.Result result, String filePath) {

    }

    private int getFlashMode() {
        switch (flashModeID) {
            case 1:
                return ImageCapture.FLASH_MODE_ON;
            case 0:
                return ImageCapture.FLASH_MODE_OFF;
            default:
                return ImageCapture.FLASH_MODE_AUTO;
        }
    }

    private class BarcodeAnalyzer implements ImageAnalysis.Analyzer {


        @Override
        public void analyze(@NonNull ImageProxy imageProxy) {
            @SuppressLint({"UnsafeExperimentalUsageError", "UnsafeOptInUsageError"}) Image mediaImage = imageProxy.getImage();
            if (mediaImage != null) {
                InputImage image =
                        InputImage.fromMediaImage(mediaImage, imageProxy.getImageInfo().getRotationDegrees());

                scanner.process(image)
                        .addOnSuccessListener(this::onSuccess)
                        .addOnFailureListener(e -> System.out.println("Error in reading barcode: " + e.getMessage()))
                        .addOnCompleteListener(task -> imageProxy.close());
            }
        }

        private void onSuccess(List<Barcode> barcodes) {
            if (barcodes.size() > 0) {
                for (Barcode barcode : barcodes)
                    onBarcodeRead(barcode.getRawValue());
            }
        }
    }

    private class OcrAnalyzer implements ImageAnalysis.Analyzer {

        @Override
        public void analyze(@NonNull ImageProxy imageProxy) {
            @SuppressLint({"UnsafeExperimentalUsageError", "UnsafeOptInUsageError"})
            Image mediaImage = imageProxy.getImage();
            if (mediaImage != null) {
                InputImage image =
                        InputImage.fromMediaImage(mediaImage, imageProxy.getImageInfo().getRotationDegrees());
                recognizer.process(image)
                        .addOnSuccessListener(this::onSuccess)
                        .addOnFailureListener(e -> System.out.println("Error in reading ocr: " + e.getMessage()))
                        .addOnCompleteListener(task -> imageProxy.close());

            }
        }

        private void onSuccess(Text text) {
            if(text.getText().trim().isEmpty())return;
            List<LineModel> lineModels = new ArrayList<>();
            for (Text.TextBlock b : text.getTextBlocks()) {

                for (Text.Line line : b.getLines()) {
                    LineModel lineModel = new LineModel(line.getText());
                    for (Point p : Objects.requireNonNull(line.getCornerPoints())) {
                        lineModel.cornerPoints.add(new CornerPointModel(p.x, p.y));
                    }
                    lineModels.add(lineModel);
                }
            }
            Gson gson = new Gson();
            gson.toJson(lineModels);

            Map<String, Object> map = new HashMap<>();
            map.put("text", text.getText());
            map.put("lines", lineModels);
            map.put("path", "");
            map.put("orientation", 0);

            onTextRead(new Gson().toJson(map));
        }

    }

    static class CompareSizesByArea implements Comparator<Size> {

        @Override
        public int compare(Size lhs, Size rhs) {
            // We cast here to ensure the multiplications won't overflow
            return Long.signum((long) lhs.getWidth() * lhs.getHeight() -
                    (long) rhs.getWidth() * rhs.getHeight());
        }
    }

    public void processImageFromPath(final String p, final MethodChannel.Result flutterResult) {
        Log.println(Log.INFO, "ArtemisCameraUtil", "ProcessingImageFromPath");
        try {
            InputImage image = InputImage.fromFilePath(context, Uri.fromFile(new File(p)));

            TextRecognizer recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS);

            recognizer.process(image)
                    .addOnSuccessListener(visionText -> processText(visionText, p, flutterResult))
                    .addOnFailureListener(e -> flutterResult.error("-1", e.getMessage(), ""));

        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public void processText(Text text, String path, final MethodChannel.Result flutterResult) {
        List<LineModel> lineModels = new ArrayList<>();
        for (Text.TextBlock b : text.getTextBlocks()) {

            for (Text.Line line : b.getLines()) {
                LineModel lineModel = new LineModel(line.getText());
                for (Point p : Objects.requireNonNull(line.getCornerPoints())) {
                    lineModel.cornerPoints.add(new CornerPointModel(p.x, p.y));
                }
                lineModels.add(lineModel);
            }
        }
        Gson gson = new Gson();
        gson.toJson(lineModels);

        Map<String, Object> map = new HashMap<>();
        map.put("text", text.getText());
        map.put("lines", lineModels);
        map.put("path", path);
        map.put("orientation", 0);

        flutterResult.success(new Gson().toJson(map));
    }


}



