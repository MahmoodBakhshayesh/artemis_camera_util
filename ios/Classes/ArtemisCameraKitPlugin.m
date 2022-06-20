#import "ArtemisCameraKitPlugin.h"
#if __has_include(<artemis_camera_kit/artemis_camera_kit-Swift.h>)
#import <artemis_camera_kit/artemis_camera_kit-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "artemis_camera_kit-Swift.h"
#endif

@implementation ArtemisCameraKitPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftArtemisCameraKitPlugin registerWithRegistrar:registrar];
}
@end
