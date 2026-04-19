//
//  AMapInfoWindow.m
//  amap_flutter_map
//
//  Created by lly on 2020/11/3.
//

#import "AMapInfoWindow.h"

@implementation AMapInfoWindow

+ (NSArray<NSString *> *)optionalProperties {
    return @[@"anchor"];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _anchor = CGPointZero;
    }
    return self;
}

@end
