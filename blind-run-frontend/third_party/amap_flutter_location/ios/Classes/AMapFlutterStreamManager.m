//
//  AMapFlutterStreamManager.m
//  amap_location_flutter_plugin
//
//  Created by ldj on 2018/10/30.
//

#import "AMapFlutterStreamManager.h"

@implementation AMapFlutterStreamManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static AMapFlutterStreamManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[AMapFlutterStreamManager alloc] init];
        AMapFlutterStreamHandler * streamHandler = [[AMapFlutterStreamHandler alloc] init];
        manager.streamHandler = streamHandler;
    });
    
    return manager;
}

@end


@implementation AMapFlutterStreamHandler

- (instancetype)init {
    self = [super init];
    if (self) {
        _pendingEvents = [[NSMutableArray alloc] init];
    }
    return self;
}

- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)eventSink {
    self.eventSink = eventSink;
    if (self.pendingEvents.count > 0) {
        NSArray<NSDictionary *> *events = [self.pendingEvents copy];
        [self.pendingEvents removeAllObjects];
        dispatch_block_t flushBlock = ^{
            for (NSDictionary *event in events) {
                self.eventSink(event);
            }
        };
        if ([NSThread isMainThread]) {
            flushBlock();
        } else {
            dispatch_async(dispatch_get_main_queue(), flushBlock);
        }
    }
    return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
    self.eventSink = nil;
    return nil;
}

- (void)emitOrBufferEvent:(NSDictionary *)event {
    NSDictionary *immutableEvent = [NSDictionary dictionaryWithDictionary:event];
    dispatch_block_t emitBlock = ^{
        if (self.eventSink != nil) {
            self.eventSink(immutableEvent);
            return;
        }
        [self.pendingEvents addObject:immutableEvent];
    };
    if ([NSThread isMainThread]) {
        emitBlock();
    } else {
        dispatch_async(dispatch_get_main_queue(), emitBlock);
    }
}

@end
