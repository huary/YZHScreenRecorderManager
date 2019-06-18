//
//  Utils.h
//  YXX
//
//  Created by yuan on 2017/5/4.
//  Copyright © 2017年 gdtech. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "NSPenPoint.h"

#define CGPointTypeEncodingPrefix                   @"{CGPoint="
#define CGVectorTypeEncodingPrefix                  @"{CGVector="
#define CGSizeTypeEncodingPrefix                    @"{CGSize="
#define CGRectTypeEncodingPrefix                    @"{CGRect="
#define NSRangeTypeEncodingPrefix                   @"{_NSRange="
#define UIOffsetTypeEncodingPrefix                  @"{UIOffset="
#define UIEdgeInsetsTypeEncodingPrefix              @"{UIEdgeInsets="
#define CGAffineTransformTypeEncodingPrefix         @"{CGAffineTransform="

#define OPEN_NSTypeObjectSet_DB_STORE              (0)

#define SLASH_MIN_ANGLE     (15)
#define SLASH_MAX_ANGLE     (80)
#define MIN_LINE_LEN        (30)

#define LR_INCLU_INTERVA(VAL,MIN_VAL,MAX_VAL)           (VAL >= MIN_VAL && VAL <= MAX_VAL)
#define L_INCLU_R_OPEN_INTERVA(VAL,MIN_VAL,MAX_VAL)     (VAL >= MIN_VAL && VAL < MAX_VAL)
#define L_OPEN_R_INCLU_INTERVA(VAL,MIN_VAL,MAX_VAL)     (VAL > MIN_VAL && VAL <= MAX_VAL)
#define LR_OPEN_INTERVA(VAL,MIN_VAL,MAX_VAL)            (VAL > MIN_VAL && VAL < MAX_VAL)

#define IS_SLASH_FOR_ANGLE(ANGLE)   LR_INCLU_INTERVA(ANGLE,SLASH_MIN_ANGLE,SLASH_MAX_ANGLE)
#define IS_HLINE_FOR_ANGLE(ANGLE)   LR_INCLU_INTERVA(ANGLE,0,SLASH_MIN_ANGLE)
#define IS_VLINE_FOR_ANGLE(ANGLE)   LR_INCLU_INTERVA(ANGLE,SLASH_MAX_ANGLE,90)

typedef NS_ENUM(NSInteger, NSNumberType)
{
    //可以浮点数，也可以是整数
    NSNumberTypeNumber   = 0,
    //整数
    NSNumberTypeInteger  = 1,
    //浮点数
    NSNumberTypeFloat    = 2,
};

//Ax + By + C = 0;
typedef struct
{
    CGFloat A;
    CGFloat B;
    CGFloat C;
}CGLineEquation;

CG_INLINE CGLineEquation
CGLineEquationMake(CGFloat A, CGFloat B, CGFloat C)
{
    CGLineEquation L; L.A = A; L.B = B; L.C = C; return L;
}

CG_INLINE BOOL
CGLineEquationIsNull(CGLineEquation L)
{
    return (L.A == 0 && L.B == 0);
}


CG_EXTERN const CGLineEquation CGLineEquationZero;

typedef NS_ENUM(NSInteger,NSFloatPointType)
{
    //可以是[+-].xxx，[+-]xxx.xxx，[+-]xxx.
    NSFloatPointTypeDefault = 0,
    //[+-].xxx这种类型的
    NSFloatPointTypeFirst   = (1 << 0),
    //[+-]xxx.xxx这种类型的
    NSFloatPointTypeMid     = (1 << 1),
    //[+-]xxx.这种类型的
    NSFloatPointTypeLast    = (1 << 2),
};

//数据类型
typedef NS_ENUM(NSInteger, NSType)
{
    NSTypeMask      = 0XFF,
    NSTypeUnknow    = 0,
    NSTypeVoid                ,
    
    NSTypeBit                 ,
    NSTypeBool                ,
    NSTypeInt8                ,
    NSTypeUInt8               ,
    NSTypeInt16               ,
    NSTypeUInt16              ,
    NSTypeInt32               ,
    NSTypeUInt32              ,
    NSTypeInt64               ,
    NSTypeUInt64              ,
    NSTypePointer             ,
    
    NSTypeFloat               ,
    NSTypeDouble              ,
    NSTypeLongDouble          ,
    
    NSTypeUnion               ,
    
    NSTypeStruct              ,
    NSTypeCGPoint             ,
    NSTypeCGVector            ,
    NSTypeCGSize              ,
    NSTypeCGRect              ,
    NSTypeNSRange             ,
    NSTypeUIOffset            ,
    NSTypeUIEdgeInsets        ,
    //other struct do here
    NSTypeCGAffineTransform   ,
    
    NSTypeCString             ,
    NSTypeCArray              ,
    
    NSTypeClass               ,
    NSTypeSEL                 , //这种不能以KVC的方式来取
    //这种block没法存储的
    NSTypeBlock               ,
    
    //integer
    NSTypeObjectNSNumber      , //用integer来存储的，默认为integer,
    //text，一下的存储方式只能是text或者blob
    NSTypeObjectText          , //默认 text
    //blob
    NSTypeObject              , //默认 blob
    NSTypeObjectNSValue       , //可以用text(如果是NSTypeStruct到NSTypeCGAffineTransform直接的)来存储,默认是blob
    NSTypeObjectData          , //NSData
    NSTypeObjectDataCoding    , //默认为blob
#if !OPEN_NSTypeObjectSet_DB_STORE
    //是一种集合类，如NSArray，NSDictionary，NSSet，NSHashTable，NSMapTable等,是不被存储支持的,如果要被存储支持的，里面的所有元素必须支持nscoding协议
    NSTypeObjectSet           ,
#endif
};


@interface Utils : NSObject

+(NSString *)applicationTmpDirectory:(NSString *)filename;
+(NSString *)applicationCachesDirectory:(NSString *)filename;
+(NSString *)applicationDocumentsDirectory:(NSString *)filename;

+(NSString *)applicationStoreInfoDirectory:(NSString*)fileName;

+(NSString *)applicationVersion;
+(NSString *)applicationShortVersion;

+(NSData*)encodeObject:(id)object forKey:(NSString*)key;
+(id)decodeObjectForData:(NSData*)data forKey:(NSString*)key;

+(NSData*)saveObject:(id<NSCoding>)ObjectToSave to:(NSString *)filename;
+(id<NSCoding>)loadObjectFrom:(NSString *)filename;
+(void)removeObjectFrom:(NSString *)filename;


+(id)jsonObjectFromJsonString:(NSString*)jsonString;

//+(BOOL)isDocumentsInboxDir:(NSString*)filePath;
+(BOOL)checkAndCreateDirectory:(NSString*)filePath;
+(BOOL)checkFileExistsAtPath:(NSString*)filePath;
+(void)removeFileItemAtPath:(NSString*)path;
+(void)createFileItemAtPath:(NSString *)path;

+(NSType)getDataType:(NSString*)typeEncoding;
+(Class)getClassFromTypeEncoding:(NSString*)typeEncoding;

+(id)respondsToSelector:(SEL)selector forTarget:(id)target;
+(id)respondsToSelector:(SEL)selector forTarget:(id)target withObject:(id)object;
+(id)respondsToSelector:(SEL)selector forClass:(Class)cls;
+(id)respondsToSelector:(SEL)selector forClass:(Class)cls withObject:(id)object;

//+(NSString*)_floatRegularExpressionPattern:(NSFloatPointType)floatPointType;
//前面可以包含正负号，和浮点数,如05这样的数字也可可以
+(BOOL)isNumberForString:(NSString*)text;
//如05这样的数字可以通过firstCanBeZero来确定，0.5这样的数字返回YES
+(BOOL)isNumberForString:(NSString *)text numberType:(NSNumberType)numberType;
+(BOOL)isNumberForString:(NSString *)text firstDigitCanBeZero:(BOOL)firstCanBeZero;

//浮点数
+(BOOL)isFloatNumberForString:(NSString*)text;
+(BOOL)isFloatNumberForString:(NSString *)text floatPointType:(NSFloatPointType)floatPointType;
+(CGFloat)floatNumberForString:(NSString*)text;
//整数
+(BOOL)isIntegerNumberForString:(NSString*)text;
//如05，这样的数字
+(BOOL)isIntegerNumberForString:(NSString *)text firstDigitCanBeZero:(BOOL)firstCanBeZero;
+(NSInteger)integerNumberForString:(NSString*)text;

+(BOOL)isHexIntegerNumberForString:(NSString*)text;
+(NSNumber*)hexIntegerNumberForString:(NSString *)text;


+(NSString*)getIntegerValueString:(NSInteger)value;
//保留小数点后面1位的数字，如果后面为0的话不进行显示
+(NSString*)getFloatValueString:(CGFloat)value;
//这个有四舍五入
+(NSString*)getFloatValueString:(CGFloat)value decimal:(NSInteger)decimal;
+(NSString*)getFloatValueString:(CGFloat)value lessThanZeroText:(NSString*)lessThanZeroText;

//+(CGRect)getRectForCGPoints:(NSArray<NSValue*> *)points;
//+(CGRect)getRectForNSWidgetPoints:(NSArray<NSWidgetPoint*> *)widgetPoints;
//+(CGRect)getRectForEventPoints:(NSArray<NSArray<NSWidgetPoint*>*> *)eventPoints;
+(CGFloat)getAngleFromPoint:(CGPoint)from to:(CGPoint)to;
//+(CGFloat)getAngleFromEventPoints:(NSArray<NSArray<NSWidgetPoint*>*> *)eventPoints;
+(CGFloat)getDistanceFromPoint:(CGPoint)from to:(CGPoint)to;
//这个做简单的角度识别
//+(NSRecognizedTextType)getTextTypeForWidgetPoints:(NSArray<NSWidgetPoint*> *)widgetPoints;
//返回的和candidatesEventPoints有可能会有重复的
//+(NSArray<NSArray<NSWidgetPoint*>*>*)getLastEventPointsFromEventPoints:(NSArray<NSArray<NSWidgetPoint*>*> *)eventPoints withEventRect:(CGRect)eventRect candidateEventPoints:(NSArray<NSArray<NSWidgetPoint*>*> **)candidatesEventPoints;
+(BOOL)isAtHorizontalLineForRect:(CGRect)firstRect nextRect:(CGRect)nextRect;
+(CGFloat)getHorizontalSpaceForRect:(CGRect)firstRect nextRect:(CGRect)nextRect;
//+(CGFloat)getStrokeHorizontalSpaceForEventPoints:(NSArray<NSArray<NSWidgetPoint*>*> *)eventPoints;
//+(CGFloat)getStrokeWidthForEventPoints:(NSArray<NSArray<NSWidgetPoint*>*> *)eventPoints;
//+(CGRect)getOutRectForRect:(CGRect)firstRect nextRect:(CGRect)nextRect shouldIntersect:(BOOL)intersects;
//+(BOOL)isFloatNumberForEventPoints:(NSArray<NSArray<NSWidgetPoint*>*> *)eventPoints floatPointAtIndex:(NSInteger*)pointAtIndex;
//+(BOOL)isJointToFloatNumberForEventPoints:(NSArray<NSArray<NSWidgetPoint*>*> *)eventPoints stroke:(NSArray<NSWidgetPoint*>*)stroke;
//+(NSArray<NSWidgetPoint*>*)getFloatPointStrokeForEventPoints:(NSArray<NSArray<NSWidgetPoint*>*> *)eventPoints floatPointStroke:(NSArray<NSWidgetPoint*>*)floatPointStroke;
//+(NSArray<NSArray<NSWidgetPoint*>*>*)changeFloatNumberPointForEventPoints:(NSArray<NSArray<NSWidgetPoint*>*> *)eventPoints;
//+(BOOL)haveSingleLineText:(NSString*)text candidateWords:(NSArray<NSString*>*)candidateWords textType:(NSRecognizedTextType)textType;
//+(NSRecognizedTextType)getSingleLineTextTypeFromText:(NSString*)text candidateWords:(NSArray<NSString*>*)candidateWords eventPoints:(NSArray<NSArray<NSWidgetPoint*>*> *)eventPoints;

//+(CGLineEquation)getLineEquationForWidgetPoints:(NSArray<NSWidgetPoint*> *)widgetPoints;
+(CGFloat)getDistanceFromPoint:(CGPoint)point toLine:(CGLineEquation)lineEquation;
//+(CGFloat)getLineWidthForWidgetPoints:(NSArray<NSWidgetPoint*>*)widgetPoints maxUpDistance:(CGFloat*)maxUpDistance maxDownDistance:(CGFloat*)maxDownDistance;
//+(NSRecognizedTextType)getTextTypeForSingleStroke:(NSArray<NSWidgetPoint *>*)stroke;

//+(CGFloat)getContainsPointsRatioForRect:(CGRect)rect eventPints:(NSArray<NSArray<NSWidgetPoint*>*>*)eventPoints;

/*
 *将text中的数字进行+changeValue(可正可负)
 *text中支持有一段数字：123，XX123，XX123XX
 */
+(NSString*)changeIntegerStringForText:(NSString*)text changeValue:(NSInteger)changeValue;
+(BOOL)isAvailableIntegerStringForText:(NSString *)text;
//返回第一段数字
+(NSInteger)integerValueForText:(NSString*)text;

+(NSData*)UIImageToDataRepresentation:(UIImage*)image;


+(NSInteger)mainQuestionIdForQuestionId:(NSString*)questionId;
+(NSInteger)subQuestionIdForQuestionId:(NSString*)questionId;

+(BOOL)isMacStringForText:(NSString*)macText;
+(NSString*)getMacStringForText:(NSString*)macText;
@end
