//
//  YZHScreenRecorder.h
//  YZHScreenRecorderManagerDemo
//
//  Created by yuan on 2018/10/23.
//  Copyright © 2018年 yuan. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, NSRecordStatus)
{
    NSRecordStatusNull        = 0,
    NSRecordStatusRecoding    = 1,
    NSRecordStatusPause       = 2,
    
};

@interface YZHScreenRecorder : NSObject

/* <#注释#> */
@property (nonatomic, strong) NSString *recordVideoPath;

/* <#name#> */
@property (nonatomic, assign) NSInteger bitRate;

/* <#name#> */
@property (nonatomic, assign) NSTimeInterval minRecordTime;

-(void)startRecord;

-(void)pauseRecord;

-(void)resumeRecord;

-(void)endRecord;

-(NSRecordStatus)recordStatus;

@end
