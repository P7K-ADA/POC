#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GlaumaOpenCVBridge : NSObject
/// Input: tightly packed RGB8 bytes, row-major, 3 bytes/pixel.
/// Output keys: ok, status, reason, message, metrics, rgbData, width, height,
/// stage1...stage7, fovMetadata, roiMetadata, warnings.
+ (NSDictionary *)prepareRGB:(NSData *)rgbData
                       width:(NSInteger)width
                      height:(NSInteger)height;
@end

NS_ASSUME_NONNULL_END
