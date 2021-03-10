#import <Flutter/Flutter.h>

@interface ActivityStringItemSource: NSObject <UIActivityItemSource>
@property (nonatomic, strong) NSString* subject;
@property (nonatomic, strong) NSString* body;
@end

@interface ShareExtendPlugin : NSObject<FlutterPlugin>
@end
