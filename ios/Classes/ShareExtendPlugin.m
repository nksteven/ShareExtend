#import "ShareExtendPlugin.h"
#import <LinkPresentation/LPLinkMetadata.h>

@implementation ActivityStringItemSource
- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController {
    return @"";
}
- (id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(UIActivityType)activityType {
    return self.body;
}
- (NSString *)activityViewController:(UIActivityViewController *)activityViewController subjectForActivityType:(nullable UIActivityType)activityType {
    return self.subject;
}
- (nullable LPLinkMetadata *)activityViewControllerLinkMetadata:(UIActivityViewController *)activityViewController  API_AVAILABLE(ios(13.0)) {
    LPLinkMetadata* data = [[LPLinkMetadata alloc]init];
    data.title = self.subject;
    return data;
}

@end

@implementation ShareExtendPlugin {
    FlutterResult _methodResult;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* shareChannel = [FlutterMethodChannel
                                          methodChannelWithName:@"com.zt.shareextend/share_extend"
                                          binaryMessenger:[registrar messenger]];
    ShareExtendPlugin *instance = [[ShareExtendPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:shareChannel];
}

- (void)share:(NSArray *)sharedItems atSource:(CGRect)origin withSubject:(NSString *) subject {
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:sharedItems applicationActivities:nil];

    __weak __typeof(self) weakSelf = self;
    activityViewController.completionWithItemsHandler = ^(UIActivityType __nullable activityType, BOOL completed, NSArray * __nullable returnedItems, NSError * __nullable activityError){
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf->_methodResult != nil && completed) {
            strongSelf->_methodResult(activityType);
        }
    };

    UIViewController *controller =[UIApplication sharedApplication].keyWindow.rootViewController;
    activityViewController.popoverPresentationController.sourceView = controller.view;

    if (CGRectIsEmpty(origin)) {
        origin = CGRectMake(0, 0, controller.view.bounds.size.width, controller.view.bounds.size.width /2);
    }
    activityViewController.popoverPresentationController.sourceRect = origin;

    [activityViewController setValue:subject forKey:@"subject"];

    [controller presentViewController:activityViewController animated:YES completion:nil];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if ([@"share" isEqualToString:call.method]) {
        NSDictionary *arguments = [call arguments];
        NSArray *array = arguments[@"list"];
        NSString *shareType = arguments[@"type"];
        NSString *subject = arguments[@"subject"];

        if (array.count == 0) {
            result(
                   [FlutterError errorWithCode:@"error" message:@"Non-empty list expected" details:nil]);
            return;
        }

        NSNumber *originX = arguments[@"originX"];
        NSNumber *originY = arguments[@"originY"];
        NSNumber *originWidth = arguments[@"originWidth"];
        NSNumber *originHeight = arguments[@"originHeight"];

        CGRect originRect = CGRectZero;
        if (originX != nil && originY != nil && originWidth != nil && originHeight != nil) {
            originRect = CGRectMake([originX doubleValue], [originY doubleValue],
                                    [originWidth doubleValue], [originHeight doubleValue]);
        }

        _methodResult = result;

        if ([shareType isEqualToString:@"text"]) {
            if (@available(iOS 13.0,*)) {
                ActivityStringItemSource* itemSource = [[ActivityStringItemSource alloc]init];
                itemSource.body = array.firstObject;
                itemSource.subject = (subject != nil && subject.length > 0) ? subject : @"";
                array = @[itemSource];
            }
            [self share:array atSource:originRect withSubject:subject];
        }  else if ([shareType isEqualToString:@"image"]) {
            NSMutableArray * imageArray = [[NSMutableArray alloc] init];
            for (NSString * path in array) {
                UIImage *image = [UIImage imageWithContentsOfFile:path];
                [imageArray addObject:image];
            }
            [self share:imageArray atSource:originRect withSubject:subject];
        } else {
            NSMutableArray * urlArray = [[NSMutableArray alloc] init];
            for (NSString * path in array) {
                NSURL *url = [NSURL fileURLWithPath:path];
                [urlArray addObject:url];
            }
            [self share:urlArray atSource:originRect withSubject:subject];
        }
    } else {
        result(FlutterMethodNotImplemented);
    }
}

@end
