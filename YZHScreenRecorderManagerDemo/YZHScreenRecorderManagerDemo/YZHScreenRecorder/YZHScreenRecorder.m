//
//  YZHScreenRecorder.m
//  YZHScreenRecorderManagerDemo
//
//  Created by yuan on 2018/10/23.
//  Copyright © 2018年 yuan. All rights reserved.
//

#import "YZHScreenRecorder.h"
#import <AVFoundation/AVFoundation.h>

@interface YZHScreenRecorder ()

/* <#注释#> */
@property (nonatomic, strong) AVAssetWriter *videoWriter;

/* <#注释#> */
@property (nonatomic, strong) AVAssetWriterInput *videoWriterInput;

/* <#注释#> */
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *videoInputPixelBufferAdaptor;

/* <#name#> */
@property (nonatomic, assign) CVPixelBufferPoolRef pixelBufferPool;

///* <#注释#> */
//@property (nonatomic, strong) NSString *defaultVideoTempFilePath;

/* <#注释#> */
@property (nonatomic, strong) CADisplayLink *displayLink;

/* 第一帧开始时的时间 */
@property (nonatomic, assign) CFTimeInterval startFrameTimeStamp;

/* <#注释#> */
@property (nonatomic, assign) CFTimeInterval pauseFrameTimeStamp;

/* <#name#> */
@property (nonatomic, assign) CFTimeInterval pauseTotalTime;

/* <#name#> */
@property (nonatomic, assign) NSRecordStatus recordStatus;


@end

@implementation YZHScreenRecorder
{
    dispatch_queue_t _renderQueue;
    dispatch_semaphore_t _frameRenderSemaphore;
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        [self _setupDefaultValue];
    }
    return self;
}

-(void)_setupDefaultValue
{
    self.recordStatus = NSRecordStatusNull;
    self.startFrameTimeStamp = 0;
    self.pauseFrameTimeStamp = 0;
    self.pauseTotalTime = 0;
    
    _renderQueue = dispatch_queue_create("YZHScreenRecorder.renderQueue", DISPATCH_QUEUE_SERIAL);
    dispatch_set_target_queue(_renderQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
    _frameRenderSemaphore = dispatch_semaphore_create(1);
    
//    [self _setupWriter];
}

-(CVPixelBufferPoolRef)pixelBufferPool
{
    if (_pixelBufferPool == NULL) {
        
    }
    return _pixelBufferPool;
}

-(NSURL*)_recordVideoFileURL
{
    NSString *videoPath = self.recordVideoPath;
    if (!IS_AVAILABLE_NSSTRNG(videoPath)) {
        NSString *pathComponent = NEW_STRING_WITH_FORMAT(@"YZHScreenRecorder/%llu_%u.mp4",MSEC_FROM_DATE_SINCE1970_NOW,arc4random());
        videoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:pathComponent];
    }
    NSString *dir = [videoPath stringByDeletingLastPathComponent];
    [Utils checkAndCreateDirectory:dir];
    if ([Utils checkFileExistsAtPath:videoPath]) {
        [Utils removeFileItemAtPath:videoPath];
    }
    return NSURL_FROM_FILE_PATH(videoPath);
}

-(NSDictionary*)_videoOutputSetting
{
    NSInteger bitRate = self.bitRate;
    if (bitRate > 0) {
        bitRate = SCREEN_WIDTH * SCREEN_HEIGHT * SCREEN_SCALE * 11.4;
    }
    NSInteger width = SCREEN_WIDTH * SCREEN_SCALE;
    NSInteger height = SCREEN_HEIGHT * SCREEN_SCALE;
    NSDictionary *videoCompression = @{AVVideoAverageBitRateKey:@(bitRate)};
    NSDictionary* videoSettings = @{AVVideoCodecKey: AVVideoCodecH264,
                                    AVVideoWidthKey: @(width),
                                    AVVideoHeightKey: @(height),
                                    AVVideoCompressionPropertiesKey: videoCompression};
    return videoSettings;
}

- (CGAffineTransform)_videoTransformForDeviceOrientation
{
    CGAffineTransform videoTransform;
    switch ([UIDevice currentDevice].orientation) {
        case UIDeviceOrientationLandscapeLeft:
            videoTransform = CGAffineTransformMakeRotation(-M_PI_2);
            break;
        case UIDeviceOrientationLandscapeRight:
            videoTransform = CGAffineTransformMakeRotation(M_PI_2);
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            videoTransform = CGAffineTransformMakeRotation(M_PI);
            break;
        default:
            videoTransform = CGAffineTransformIdentity;
    }
    return videoTransform;
}

-(AVAssetWriter*)videoWriter
{
    if (_videoWriter == nil) {
        NSError *error = nil;
        _videoWriter = [AVAssetWriter assetWriterWithURL:[self _recordVideoFileURL] fileType:AVFileTypeQuickTimeMovie error:&error];
    }
    return _videoWriter;
}

-(AVAssetWriterInput*)videoWriterInput
{
    if (_videoWriterInput == nil) {
        _videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:[self _videoOutputSetting]];
        _videoWriterInput.expectsMediaDataInRealTime = YES;
        _videoWriterInput.transform = [self _videoTransformForDeviceOrientation];
    }
    return _videoWriterInput;
}

-(AVAssetWriterInputPixelBufferAdaptor*)videoInputPixelBufferAdaptor
{
    if (_videoInputPixelBufferAdaptor == nil) {
        _videoInputPixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.videoWriterInput sourcePixelBufferAttributes:nil];
        
    }
    return _videoInputPixelBufferAdaptor;
}

-(void)_setupWriter
{
    [self videoInputPixelBufferAdaptor];
    [self.videoWriter addInput:self.videoWriterInput];
    [self.videoWriter startWriting];
    [self.videoWriter startSessionAtSourceTime:CMTimeMake(0, 1000)];
}














@end
