#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import <AMapFoundationKit/AMapServices.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [GeneratedPluginRegistrant registerWithRegistry:self];
//    设置AMap的key
    [AMapServices sharedServices].apiKey = @"YOUR_AMAP_IOS_KEY";
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
