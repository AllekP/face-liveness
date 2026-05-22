#import "FaceEmbeddingGenerator.h"
#import <TensorFlowLiteSwift/TensorFlowLiteSwift-Swift.h>
#import <Accelerate/Accelerate.h>

@implementation FaceEmbeddingGenerator {
    TFLInterpreter *_interpreter;
}

- (instancetype)init {
    if (self = [super init]) {
        NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"mobile_facenet" ofType:@"tflite"];
        if (modelPath) {
            NSError *error;
            _interpreter = [[TFLInterpreter alloc] initWithModelPath:modelPath error:&error];
            [_interpreter allocateTensorsWithError:&error];
        }
    }
    return self;
}

- (NSArray<NSNumber *> *)generateEmbedding:(UIImage *)image {
    if (!_interpreter || !image) return @[];

    // Resize and normalize the image
    CGSize size = CGSizeMake(112, 112);
    UIGraphicsBeginImageContextWithOptions(size, NO, 1.0);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    CGImageRef cgImage = resizedImage.CGImage;
    CFDataRef data = CGDataProviderCopyData(CGImageGetDataProvider(cgImage));
    const UInt8 *bytes = CFDataGetBytePtr(data);

    int numPixels = 112 * 112;
    float *inputBuffer = (float *)malloc(numPixels * 3 * sizeof(float));

    for (int i = 0; i < numPixels; i++) {
        // Assume BGRA or RGBA
        inputBuffer[i * 3 + 0] = (bytes[i * 4 + 0] - 127.5f) / 127.5f;
        inputBuffer[i * 3 + 1] = (bytes[i * 4 + 1] - 127.5f) / 127.5f;
        inputBuffer[i * 3 + 2] = (bytes[i * 4 + 2] - 127.5f) / 127.5f;
    }

    NSData *inputData = [NSData dataWithBytesNoCopy:inputBuffer length:numPixels * 3 * sizeof(float) freeWhenDone:YES];
    NSError *error;
    [_interpreter copyData:inputData toInputTensorAtIndex:0 error:&error];
    [_interpreter invokeWithError:&error];

    NSData *outputData = [_interpreter outputTensorAtIndex:0 error:&error].data;
    float *outputBuffer = (float *)outputData.bytes;

    NSMutableArray *embedding = [NSMutableArray arrayWithCapacity:192];
    for (int i = 0; i < 192; i++) {
        [embedding addObject:@(outputBuffer[i])];
    }

    CFRelease(data);
    return embedding;
}

@end
