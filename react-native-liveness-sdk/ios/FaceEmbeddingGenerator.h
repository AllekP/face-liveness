#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FaceEmbeddingGenerator : NSObject

- (NSArray<NSNumber *> *)generateEmbedding:(UIImage *)image;

@end
