#import "LivenessSdkView.h"

#import <react/renderer/components/LivenessSdk/ComponentDescriptors.h>
#import <react/renderer/components/LivenessSdk/EventEmitters.h>
#import <react/renderer/components/LivenessSdk/Props.h>
#import <react/renderer/components/LivenessSdk/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"

#import <AVFoundation/AVFoundation.h>
#import <MLKitFaceDetection/MLKitFaceDetection.h>
#import <MLKitVision/MLKitVision.h>
#import "FaceEmbeddingGenerator.h"

using namespace facebook::react;

@interface LivenessSdkView () <RCTLivenessSdkViewViewProtocol, AVCaptureVideoDataOutputSampleBufferDelegate>

@end

@implementation LivenessSdkView {
    UIView *_view;
    AVCaptureSession *_captureSession;
    AVCaptureVideoPreviewLayer *_previewLayer;
    MLKFaceDetector *_faceDetector;
    UILabel *_instructionLabel;
    CAShapeLayer *_ovalLayer;
    FaceEmbeddingGenerator *_embeddingGenerator;

    NSArray<NSString *> *_actions;
    NSInteger _currentActionIndex;
    BOOL _isCompleted;
    UIImage *_lastFaceImage;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<LivenessSdkViewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const LivenessSdkViewProps>();
    _props = defaultProps;

    _view = [[UIView alloc] initWithFrame:self.bounds];

    _instructionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 50, self.bounds.size.width, 50)];
    _instructionLabel.textColor = [UIColor whiteColor];
    _instructionLabel.textAlignment = NSTextAlignmentCenter;
    _instructionLabel.font = [UIFont systemFontOfSize:20];

    _ovalLayer = [CAShapeLayer layer];
    _ovalLayer.fillColor = [UIColor clearColor].CGColor;
    _ovalLayer.strokeColor = [UIColor greenColor].CGColor;
    _ovalLayer.lineWidth = 4.0;

    [self addSubview:_view];
    [_view addSubview:_instructionLabel];
    [_view.layer addSublayer:_ovalLayer];

    _embeddingGenerator = [[FaceEmbeddingGenerator alloc] init];

    MLKFaceDetectorOptions *options = [[MLKFaceDetectorOptions alloc] init];
    options.performanceMode = MLKFaceDetectorPerformanceModeFast;
    options.landmarkMode = MLKFaceDetectorLandmarkModeAll;
    options.classificationMode = MLKFaceDetectorClassificationModeAll;
    _faceDetector = [MLKFaceDetector faceDetectorWithOptions:options];

    [self setupCamera];

    self.contentView = _view;
  }

  return self;
}

- (void)setupCamera {
    _captureSession = [[AVCaptureSession alloc] init];
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];

    if ([_captureSession canAddInput:videoInput]) {
        [_captureSession addInput:videoInput];
    }

    AVCaptureVideoDataOutput *videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    [videoOutput setSampleBufferDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)];
    if ([_captureSession canAddOutput:videoOutput]) {
        [_captureSession addOutput:videoOutput];
    }

    _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _previewLayer.frame = self.bounds;
    [_view.layer insertSublayer:_previewLayer atIndex:0];

    [_captureSession startRunning];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _view.frame = self.bounds;
    _previewLayer.frame = self.bounds;
    _instructionLabel.frame = CGRectMake(0, 50, self.bounds.size.width, 50);

    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(self.bounds.size.width * 0.15, self.bounds.size.height * 0.25, self.bounds.size.width * 0.7, self.bounds.size.height * 0.5)];
    _ovalLayer.path = path.CGPath;
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    MLKVisionImage *image = [[MLKVisionImage alloc] initWithBuffer:sampleBuffer];
    image.orientation = [self imageOrientationFromDeviceOrientation];

    [_faceDetector processImage:image completion:^(NSArray<MLKFace *> * _Nullable faces, NSError * _Nullable error) {
        if (faces.count > 0) {
            if (self->_currentActionIndex == self->_actions.count - 1) {
                self->_lastFaceImage = [self imageFromSampleBuffer:sampleBuffer];
            }
            [self checkLiveness:faces[0]];
        }
    }];
}

- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:imageBuffer];
    CIContext *temporaryContext = [CIContext contextWithOptions:nil];
    CGImageRef videoImage = [temporaryContext createCGImage:ciImage fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(imageBuffer), CVPixelBufferGetHeight(imageBuffer))];
    UIImage *uiImage = [UIImage imageWithCGImage:videoImage];
    CGImageRelease(videoImage);
    return uiImage;
}

- (UIImageOrientation)imageOrientationFromDeviceOrientation {
  switch ([[UIDevice currentDevice] orientation]) {
    case UIDeviceOrientationPortrait:
      return UIImageOrientationUp;
    case UIDeviceOrientationPortraitUpsideDown:
      return UIImageOrientationDown;
    case UIDeviceOrientationLandscapeLeft:
      return UIImageOrientationLeft;
    case UIDeviceOrientationLandscapeRight:
      return UIImageOrientationRight;
    default:
      return UIImageOrientationUp;
  }
}

- (void)checkLiveness:(MLKFace *)face {
    if (_isCompleted || _actions.count == 0) return;

    NSString *currentAction = _actions[_currentActionIndex];
    BOOL actionVerified = NO;

    if ([currentAction isEqualToString:@"smile"]) {
        if (face.hasSmilingProbability && face.smilingProbability > 0.7) actionVerified = YES;
    } else if ([currentAction isEqualToString:@"blink"]) {
        if (face.hasLeftEyeOpenProbability && face.leftEyeOpenProbability < 0.2 && face.hasRightEyeOpenProbability && face.rightEyeOpenProbability < 0.2) actionVerified = YES;
    } else if ([currentAction isEqualToString:@"turnLeft"]) {
        if (face.headEulerAngleY > 20) actionVerified = YES;
    } else if ([currentAction isEqualToString:@"turnRight"]) {
        if (face.headEulerAngleY < -20) actionVerified = YES;
    } else if ([currentAction isEqualToString:@"nodUp"]) {
        if (face.headEulerAngleX > 15) actionVerified = YES;
    } else if ([currentAction isEqualToString:@"nodDown"]) {
        if (face.headEulerAngleX < -15) actionVerified = YES;
    }

    if (actionVerified) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self->_currentActionIndex >= self->_actions.count - 1) {
                self->_isCompleted = YES;
                NSString *imageUri = [self saveImageToTempFile:self->_lastFaceImage];
                NSArray *embedding = [self->_embeddingGenerator generateEmbedding:self->_lastFaceImage];
                [self emitEvent:@"completed" currentStep:nil embedding:embedding imageUri:imageUri];
            } else {
                self->_currentActionIndex++;
                [self emitEvent:@"step_completed" currentStep:self->_actions[self->_currentActionIndex] embedding:nil imageUri:nil];
            }
            [self updateUI];
        });
    }
}

- (NSString *)saveImageToTempFile:(UIImage *)image {
    if (!image) return nil;
    NSString *fileName = [NSString stringWithFormat:@"liveness_%f.jpg", [[NSDate date] timeIntervalSince1970]];
    NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
    NSData *imageData = UIImageJPEGRepresentation(image, 0.9);
    [imageData writeToFile:filePath atomically:YES];
    return [NSString stringWithFormat:@"file://%@", filePath];
}

- (void)updateUI {
    if (_isCompleted) {
        _instructionLabel.text = @"Liveness Check Completed!";
    } else if (_actions.count > 0) {
        _instructionLabel.text = [NSString stringWithFormat:@"Please %@", _actions[_currentActionIndex]];
    }
}

- (void)emitEvent:(NSString *)status currentStep:(NSString *)currentStep embedding:(NSArray *)embedding imageUri:(NSString *)imageUri {
    if (_eventEmitter) {
        auto livenessEmitter = std::static_pointer_cast<const LivenessSdkViewEventEmitter>(_eventEmitter);
        LivenessSdkViewEventEmitter::OnLivenessEvent event;
        event.status = [status UTF8String];
        if (currentStep) {
            event.currentStep = [currentStep UTF8String];
        }

        if ([status isEqualToString:@"completed"]) {
            LivenessSdkViewEventEmitter::OnLivenessEventResult result;
            result.success = YES;
            if (imageUri) result.imageUri = [imageUri UTF8String];
            if (embedding) {
                std::vector<double> embeddingVec;
                for (NSNumber *n in embedding) {
                    embeddingVec.push_back([n doubleValue]);
                }
                result.embedding = embeddingVec;
            }
            event.result = result;
        }

        livenessEmitter->onLivenessEvent(event);
    }
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
  const auto &oldViewProps = *std::static_pointer_cast<const LivenessSdkViewProps>(_props);
  const auto &newViewProps = *std::static_pointer_cast<const LivenessSdkViewProps>(props);

  if (oldViewProps.actions != newViewProps.actions) {
      NSMutableArray *newActions = [NSMutableArray array];
      for (const auto &action : newViewProps.actions) {
          [newActions addObject:[NSString stringWithUTF8String:action.c_str()]];
      }
      _actions = newActions;
      _currentActionIndex = 0;
      _isCompleted = NO;
      dispatch_async(dispatch_get_main_queue(), ^{
          [self updateUI];
      });
  }

  if (oldViewProps.ovalColor != newViewProps.ovalColor) {
      NSString *hex = [NSString stringWithUTF8String:newViewProps.ovalColor.c_str()];
      dispatch_async(dispatch_get_main_queue(), ^{
          self->_ovalLayer.strokeColor = [self colorFromHexString:hex].CGColor;
      });
  }

  [super updateProps:props oldProps:oldProps];
}

- (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    if ([hexString hasPrefix:@"#"]) {
        [scanner setScanLocation:1];
    }
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

@end

Class<RCTComponentViewProtocol> LivenessSdkViewCls(void)
{
  return LivenessSdkView.class;
}
