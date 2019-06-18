//
//  Utils.m
//  YXX
//
//  Created by yuan on 2017/5/4.
//  Copyright © 2017年 gdtech. All rights reserved.
//

#import "Utils.h"
#import <objc/runtime.h>

#define APPLICATION_INFO_PATH                   @"APP_INFO"
#define SAVE_DATA_KEY                           @"APP_DATA"
#define DOCUMENTS_INBOX_DIR_NAME                @"Inbox"


//正斜线'/',从左下角到右上角（正确的写法）
#define IS_LDRU_FORWARD_SLASH(FIRST_PT,LAST_PT)     (FIRST_PT.x < LAST_PT.x && FIRST_PT.y > LAST_PT.y)
//正斜线'/'从右上角到左下角
#define IS_RULD_FORWARD_SLASH(FIRST_PT,LAST_PT)     (FIRST_PT.x > LAST_PT.x && FIRST_PT.y < LAST_PT.y)
//包含从左下角到右上角（正确的写法），或者从右上角到左下角
#define IS_FORWARD_SLASH(FIRST_PT,LAST_PT)          (IS_LDRU_FORWARD_SLASH(FIRST_PT,LAST_PT) || IS_RULD_FORWARD_SLASH(FIRST_PT,LAST_PT))

//反斜线\从左上角到右下角
#define IS_LURD_BACK_SLASH(FIRST_PT,LAST_PT)        (FIRST_PT.x < LAST_PT.x && FIRST_PT.y < LAST_PT.y)
//反斜线\从右下角到左上角,很少这样写的吧
#define IS_RDLU_BACK_SLASH(FIRST_PT,LAST_PT)        (FIRST_PT.x > LAST_PT.x && FIRST_PT.y > LAST_PT.y)
//反斜线\包含从左上角到右下角（正确的写法），或者从右下角到左上角
#define IS_BACK_SLASH(FIRST_PT,LAST_PT)             IS_LURD_BACK_SLASH(FIRST_PT,LAST_PT) || IS_RDLU_BACK_SLASH(FIRST_PT,LAST_PT)

const CGLineEquation CGLineEquationZero={.A = 0, .B = 0, .C = 0};

@implementation Utils

+(NSString *)applicationTmpDirectory:(NSString *)filename
{
    NSString *tmpDir = NSTemporaryDirectory();
    if (IS_AVAILABLE_NSSTRNG(filename)) {
        return [tmpDir stringByAppendingString:filename];
    }
    return tmpDir;
}

+ (NSString *)applicationCachesDirectory:(NSString *)filename
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                                         NSUserDomainMask,
                                                         YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    if (IS_AVAILABLE_NSSTRNG(filename)) {
        return [basePath stringByAppendingPathComponent:filename];
    }
    return basePath;
}

+ (NSString *)applicationDocumentsDirectory:(NSString *)filename
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask,
                                                         YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    if (IS_AVAILABLE_NSSTRNG(filename)) {
        return [basePath stringByAppendingPathComponent:filename];
    }
    return basePath;
}

//这里的fileName可以带有相对路径，
+(NSString *)applicationStoreInfoDirectory:(NSString*)fileName
{
    NSString *filePath = [Utils applicationCachesDirectory:nil];
    
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    NSString *pathName = [[NSString alloc] initWithFormat:@"%@.%@",bundleId,APPLICATION_INFO_PATH];
    filePath = [filePath stringByAppendingPathComponent:pathName];
    
    NSString *directory = filePath;
    if (IS_AVAILABLE_NSSTRNG(fileName)) {
        filePath = [filePath stringByAppendingPathComponent:fileName];
        directory = [filePath stringByDeletingLastPathComponent];
    }
    [Utils checkAndCreateDirectory:directory];
    return filePath;
}

+(NSString *)applicationVersion
{
    return [[NSBundle mainBundle].infoDictionary objectForKey:@"CFBundleVersion"];
}

+(NSString*)applicationShortVersion
{
    return [[NSBundle mainBundle].infoDictionary objectForKey:@"CFBundleShortVersionString"];
}

+(NSData*)encodeObject:(id)object forKey:(NSString*)key
{
    if (/*object == nil ||*/ [object conformsToProtocol:@protocol(NSCoding)] == NO) {
        return nil;
    }
    
    if (key != nil) {
        if (ON_LATER_IOS_VERSION(10.0)) {
            NSKeyedArchiver *encoder = [[NSKeyedArchiver alloc] init];
            [encoder encodeObject:object forKey:key];
            [encoder finishEncoding];
            
            return encoder.encodedData;
        }
        else {
            NSMutableData *mutData = [NSMutableData data];
            NSKeyedArchiver *keyArchiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:mutData];
            
            [keyArchiver encodeObject:object forKey:key];
            [keyArchiver finishEncoding];
            
            return [mutData copy];
        }
    }
    else
    {
        if (object == nil) {
            return nil;
        }
        return [NSKeyedArchiver archivedDataWithRootObject:object];
    }
}

+(id)decodeObjectForData:(NSData*)data forKey:(NSString*)key
{
    if (data == nil) {
        return nil;
    }
    NSKeyedUnarchiver *decoder = nil;
    id value = nil;
    if (key != nil) {
        decoder = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        value = [decoder decodeObjectForKey:key];
        [decoder finishDecoding];
    }
    else
    {
        value = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    return value;
}

+(NSData*)saveObject:(id<NSCoding>)ObjectToSave to:(NSString *)filename
{
    NSData *data = [Utils encodeObject:ObjectToSave forKey:SAVE_DATA_KEY];
    if (data) {
        NSString *filePath = [Utils applicationStoreInfoDirectory:filename];
        [data writeToFile:filePath atomically:YES];
    }
    return data;
}

+(id<NSCoding>)loadObjectFrom:(NSString *)filename
{
    NSString *filePath  = [[Utils applicationStoreInfoDirectory:nil] stringByAppendingPathComponent:filename];
    if ([Utils checkFileExistsAtPath:filePath]) {
        NSData *data = [[NSData alloc] initWithContentsOfFile:filePath];
        id<NSCoding> result = [Utils decodeObjectForData:data forKey:SAVE_DATA_KEY];
        return result;
    }
    return nil;
}

+(void)removeObjectFrom:(NSString *)filename
{
    NSString *filePath  = [[Utils applicationStoreInfoDirectory:nil] stringByAppendingPathComponent:filename];
    [Utils removeFileItemAtPath:filePath];
}


+(id)jsonObjectFromJsonString:(NSString *)jsonString
{
    if (!IS_AVAILABLE_NSSTRNG(jsonString)) {
        return nil;
    }
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    id obj = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    return obj;
}

//+(BOOL)isDocumentsInboxDir:(NSString*)filePath
//{
//    NSString *docPath = [Utils applicationDocumentsDirectory:DOCUMENTS_INBOX_DIR_NAME];
//    if (filePath && [filePath containsString:docPath]) {
//        return YES;
//    }
//    return NO;
//}

+(BOOL)checkAndCreateDirectory:(NSString*)filePath
{
    if (!IS_AVAILABLE_NSSTRNG(filePath)) {
        return NO;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isExists = [fileManager fileExistsAtPath:filePath isDirectory:&isDir];
    if ((isExists && isDir == NO) || isExists == NO) {
        if (isExists == YES) {
            [fileManager removeItemAtPath:filePath error:nil];
        }
        [fileManager createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return YES;
}

+(BOOL)checkFileExistsAtPath:(NSString*)filePath
{
    if (!IS_AVAILABLE_NSSTRNG(filePath)) {
        return NO;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:filePath];
}

+(void)removeFileItemAtPath:(NSString*)path
{
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    [defaultManager removeItemAtPath:path error:NULL];
}

+(void)createFileItemAtPath:(NSString *)path
{
    if (!IS_AVAILABLE_NSSTRNG(path)) {
        return;
    }
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    [defaultManager createFileAtPath:path contents:nil attributes:nil];
}


+(NSType)getDataType:(NSString*)typeEncoding
{
    char type = [typeEncoding characterAtIndex:0];
    switch (type) {
        case 'v': return NSTypeVoid;
        case 'b': return NSTypeBit;
        case 'B': return NSTypeBool;
        case 'c': return NSTypeInt8;
        case 'C': return NSTypeUInt8;
        case 's': return NSTypeInt16;
        case 'S': return NSTypeUInt16;
        case 'i': return NSTypeInt32;
        case 'I': return NSTypeUInt32;
        case 'l': return NSTypeInt32;
        case 'L': return NSTypeUInt32;
        case 'q': return NSTypeInt64;
        case 'Q': return NSTypeUInt64;
        case 'f': return NSTypeFloat;
        case 'd': return NSTypeDouble;
        case 'D': return NSTypeLongDouble;
        case '#': return NSTypeClass;
        case ':': return NSTypeSEL;
        case '*': return NSTypeCString;
        case '^': return NSTypePointer;
        case '[': return NSTypeCArray;
        case '(': return NSTypeUnion;
        case '{': {
            if (typeEncoding.length > CGPointTypeEncodingPrefix.length && [typeEncoding compare:CGPointTypeEncodingPrefix options:NSCaseInsensitiveSearch range:NSMakeRange(0, CGPointTypeEncodingPrefix.length)] == NSOrderedSame) {
                return NSTypeCGPoint;
            }
            else if (typeEncoding.length > CGVectorTypeEncodingPrefix.length && [typeEncoding compare:CGVectorTypeEncodingPrefix options:NSCaseInsensitiveSearch range:NSMakeRange(0, CGVectorTypeEncodingPrefix.length)] == NSOrderedSame)
            {
                return NSTypeCGVector;
            }
            else if (typeEncoding.length > CGSizeTypeEncodingPrefix.length && [typeEncoding compare:CGSizeTypeEncodingPrefix options:NSCaseInsensitiveSearch range:NSMakeRange(0, CGSizeTypeEncodingPrefix.length)] == NSOrderedSame) {
                return NSTypeCGSize;
            }
            else if (typeEncoding.length > CGRectTypeEncodingPrefix.length && [typeEncoding compare:CGRectTypeEncodingPrefix options:NSCaseInsensitiveSearch range:NSMakeRange(0, CGRectTypeEncodingPrefix.length)] == NSOrderedSame) {
                return NSTypeCGRect;
            }
            else if (typeEncoding.length > NSRangeTypeEncodingPrefix.length && [typeEncoding compare:NSRangeTypeEncodingPrefix options:NSCaseInsensitiveSearch range:NSMakeRange(0, NSRangeTypeEncodingPrefix.length)] == NSOrderedSame) {
                return NSTypeNSRange;
            }
            else if (typeEncoding.length > UIOffsetTypeEncodingPrefix.length && [typeEncoding compare:UIOffsetTypeEncodingPrefix options:NSCaseInsensitiveSearch range:NSMakeRange(0, UIOffsetTypeEncodingPrefix.length)] == NSOrderedSame) {
                return NSTypeUIOffset;
            }
            else if (typeEncoding.length > UIEdgeInsetsTypeEncodingPrefix.length && [typeEncoding compare:UIEdgeInsetsTypeEncodingPrefix options:NSCaseInsensitiveSearch range:NSMakeRange(0, UIEdgeInsetsTypeEncodingPrefix.length)] == NSOrderedSame) {
                return NSTypeUIEdgeInsets;
            }
            else if (typeEncoding.length > CGAffineTransformTypeEncodingPrefix.length && [typeEncoding compare:CGAffineTransformTypeEncodingPrefix options:NSCaseInsensitiveSearch range:NSMakeRange(0, CGAffineTransformTypeEncodingPrefix.length)] == NSOrderedSame) {
                return NSTypeCGAffineTransform;
            }
            return NSTypeStruct;
        };
        case '@': {
            if (typeEncoding.length == 2 && [typeEncoding characterAtIndex:1] == '?')
            {
                return NSTypeBlock;
            }
            else
            {
                NSString *classString = [typeEncoding substringWithRange:NSMakeRange(2, typeEncoding.length - 3)];
                Class class = NSCLASS_FROM_STRING(classString);
                if (class == [NSString class] || class == [NSMutableString class]) {
                    return NSTypeObjectText;
                }
                else if (class == [NSNumber class])
                {
                    return NSTypeObjectNSNumber;
                }
                else if (class == [NSValue class])
                {
                    return NSTypeObjectNSValue;
                }
                else if (class == [NSData class] || class == [NSMutableData class])
                {
                    return NSTypeObjectData;
                }
#if !OPEN_NSTypeObjectSet_DB_STORE
                else if ([class conformsToProtocol:@protocol(NSFastEnumeration)])
                {
                    return NSTypeObjectSet;
                }
#endif
                else if ([class conformsToProtocol:@protocol(NSCoding)])
                {
                    return NSTypeObjectDataCoding;
                }
                return NSTypeObject;
            }
        }
            
        default: return NSTypeUnknow;
    }
}

+(Class)getClassFromTypeEncoding:(NSString*)typeEncoding
{
    if (typeEncoding.length <= 3) {
        return NULL;
    }
    NSString *classString = [typeEncoding substringWithRange:NSMakeRange(2, typeEncoding.length - 3)];
    return NSCLASS_FROM_STRING(classString);
}

+(id)respondsToSelector:(SEL)selector forTarget:(id)target
{
    if (selector == NULL || target == NULL) {
        return nil;
    }
    id obj = nil;
    if ([target respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        obj = [target performSelector:selector];
#pragma clang diagnostic pop
    }
    return obj;
}

+(id)respondsToSelector:(SEL)selector forTarget:(id)target withObject:(id)object
{
    if (selector == NULL || target == NULL) {
        return nil;
    }
    id obj = nil;
    if ([target respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        obj = [target performSelector:selector withObject:object];
#pragma clang diagnostic pop
    }
    return obj;
}

+(id)respondsToSelector:(SEL)selector forClass:(Class)cls
{
    if (selector == NULL || cls == NULL) {
        return nil;
    }
    id obj = nil;
    if([cls respondsToSelector:selector]){
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        obj = [cls performSelector:selector];
#pragma clang diagnostic pop
    }
    return obj;
}

+(id)respondsToSelector:(SEL)selector forClass:(Class)cls withObject:(id)object
{
    if (selector == NULL || cls == NULL) {
        return nil;
    }
    id obj = nil;
    if ([cls respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        obj = [cls performSelector:selector withObject:object];
#pragma clang diagnostic pop
    }
    return obj;
}

+(NSString*)_integerRegularExpressionPattern:(BOOL)firstCanBeZero
{
    if (firstCanBeZero) {
        return @"[+-]?\\d+";
    }
    return @"([+-]?[0-9]$)|([+-]?[1-9][0-9]*$)";
}

+(NSString*)_floatRegularExpressionPattern:(NSFloatPointType)floatPointType
{
    NSString *regular = @"";
    if (floatPointType == NSFloatPointTypeDefault) {
        return @"(([+-]?)(\\d+)(\\.\\d{0,}))|(([+-]?)(\\d{0,})(\\.\\d+))";
    }
    else{
        if (TYPE_AND(floatPointType, NSFloatPointTypeFirst)) {
            if (IS_AVAILABLE_NSSTRNG(regular)) {
                regular = NEW_STRING_WITH_FORMAT(@"%@|%@",regular,@"(([+-]?)(\\.\\d+))");
            }
            else{
                regular =@"(([+-]?)(\\.\\d+))";
            }
        }
        if (TYPE_AND(floatPointType, NSFloatPointTypeMid)) {
            if (IS_AVAILABLE_NSSTRNG(regular)) {
                regular = NEW_STRING_WITH_FORMAT(@"%@|%@",regular,@"(([+-]?)(\\d+)(\\.\\d+))");
            }
            else{
                regular = @"(([+-]?)(\\d+)(\\.\\d+))";
            }
        }
        if (TYPE_AND(floatPointType, NSFloatPointTypeLast)) {
            if (IS_AVAILABLE_NSSTRNG(regular)) {
                regular = NEW_STRING_WITH_FORMAT(@"%@|%@",regular,@"(([+-]?)(\\d+\\.))");
            }
            else{
                regular = @"(([+-]?)(\\d+\\.))";
            }
        }        
    }
    return regular;
}

+(BOOL)evaluateText:(NSString*)text withRegularExpressionPattern:(NSString*)pattern
{
    if (!IS_AVAILABLE_NSSTRNG(text)) {
        return NO;
    }
    if (pattern == nil) {
        return NO;
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",pattern];
    return [predicate evaluateWithObject:text];
}

+(BOOL)isNumberForString:(NSString*)text
{
    return ([[self class] isFloatNumberForString:text] || [[self class] isIntegerNumberForString:text]);
}

+(BOOL)isNumberForString:(NSString *)text numberType:(NSNumberType)numberType
{
    if (numberType == NSNumberTypeNumber) {
        return [Utils isNumberForString:text];
    }
    else if (numberType == NSNumberTypeInteger){
        return [Utils isIntegerNumberForString:text];
    }
    else if (numberType == NSNumberTypeFloat){
        return [Utils isFloatNumberForString:text];
    }
    return NO;
}

+(BOOL)isNumberForString:(NSString *)text firstDigitCanBeZero:(BOOL)firstCanBeZero
{
    if (firstCanBeZero) {
        return [Utils isNumberForString:text];
    }
    
    return ([[self class] isFloatNumberForString:text] || [[self class] isIntegerNumberForString:text firstDigitCanBeZero:NO]);
}

+(BOOL)isFloatNumberForString:(NSString*)text
{
    if (!IS_AVAILABLE_NSSTRNG(text)) {
        return NO;
    }
#if 1
    return [Utils evaluateText:text withRegularExpressionPattern:[Utils _floatRegularExpressionPattern:NSFloatPointTypeDefault]];
#else
    char c = [text characterAtIndex:0];
    BOOL hasSign = NO;
    if (c=='+'||c=='-') {
        hasSign = YES;
    }
    NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:@"[0-9]" options:0 error:nil];
    NSString *newText = [regularExpression stringByReplacingMatchesInString:text options:0 range:NSMakeRange(0, text.length) withTemplate:@""];
    
    BOOL isFloatValue = NO;
    
    NSInteger newLength = newText.length;
    if (newLength == 1 || newLength == 2) {
        if (newText.length == 1) {
            if ([newText characterAtIndex:0] == '.' && text.length > newText.length) {
                isFloatValue = YES;
            }
        }
        else if (newText.length == 2)
        {
            if (hasSign && [newText characterAtIndex:1] == '.' && text.length > newText.length+1 && [text characterAtIndex:1] != '.') {
                isFloatValue  = YES;
            }
        }
    }
    return isFloatValue;
#endif
}

+(BOOL)isFloatNumberForString:(NSString *)text floatPointType:(NSFloatPointType)floatPointType
{
    if (!IS_AVAILABLE_NSSTRNG(text)) {
        return NO;
    }
    return [Utils evaluateText:text withRegularExpressionPattern:[Utils _floatRegularExpressionPattern:floatPointType]];
}

+(CGFloat)floatNumberForString:(NSString*)text
{
    BOOL isFloatNumber = [Utils isNumberForString:text];
    if (isFloatNumber) {
        return [text floatValue];
    }
    return 0;
}

+(BOOL)isIntegerNumberForString:(NSString*)text
{
    if (!IS_AVAILABLE_NSSTRNG(text)) {
        return NO;
    }
#if 1
    return [Utils evaluateText:text withRegularExpressionPattern:[Utils _integerRegularExpressionPattern:YES]];
#else
    char c = [text characterAtIndex:0];
    BOOL hasSign = NO;
    if (c=='+'||c=='-') {
        hasSign = YES;
    }
    NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:@"[0-9]" options:0 error:nil];
    NSString *newText = [regularExpression stringByReplacingMatchesInString:text options:0 range:NSMakeRange(0, text.length) withTemplate:@""];
    
    if ((newText.length == 1 && hasSign && text.length > newText.length) || (newText.length == 0 && hasSign == NO)) {
        return YES;
    }
    return NO;
#endif
}


//如05，这样的数字
+(BOOL)isIntegerNumberForString:(NSString *)text firstDigitCanBeZero:(BOOL)firstCanBeZero
{
    if (!IS_AVAILABLE_NSSTRNG(text)) {
        return NO;
    }
#if 1
    return [Utils evaluateText:text withRegularExpressionPattern:[Utils _integerRegularExpressionPattern:firstCanBeZero]];
#else
    if (firstCanBeZero) {
        return [Utils isIntegerNumberForString:text];
    }
    BOOL isInteger = [Utils isIntegerNumberForString:text];
    if (!isInteger) {
        return NO;
    }
    if ([text integerValue] == 0) {
        return YES;
    }
    
    char c = [text characterAtIndex:0];
    BOOL hasSign = NO;
    if (c=='+'||c=='-') {
        hasSign = YES;
    }
    char first = 0;
    if (hasSign) {
        first = [text characterAtIndex:1];
    }
    else{
        first = [text characterAtIndex:0];
    }
    return first > '0' && first <= '9';
#endif
}

+(NSInteger)integerNumberForString:(NSString*)text
{
    BOOL isInteget = [Utils isIntegerNumberForString:text];
    if (isInteget) {
        return [text integerValue];
    }
    return 0;
}

+(BOOL)isHexIntegerNumberForString:(NSString *)text
{
    NSNumber *result = [Utils hexIntegerNumberForString:text];
    return result != nil;
}

+(NSNumber*)hexIntegerNumberForString:(NSString *)text
{
    if (!IS_AVAILABLE_NSSTRNG(text)) {
        return nil;
    }
    NSScanner *scaner = [[NSScanner alloc] initWithString:text];
    unsigned long long result = 0;
    [scaner scanHexLongLong:&result];
    return @(result);
}

//+(unsigned long long)hexIntegerNumberForString:(NSString*)text
//{
//    return [[Utils _hexIntegerNumberForString:text] unsignedLongLongValue];
//}

+(NSString*)getIntegerValueString:(NSInteger)value
{
    return NEW_STRING_WITH_FORMAT(@"%ld",(long)value);
}

+(NSString*)getFloatValueString:(CGFloat)value
{
    CGFloat diff = value - (NSInteger)value;
    if (fabs(diff) < 0.01) {
        return [[NSString alloc] initWithFormat:@"%ld",(long)value];
    }
    else
    {
//        NSInteger tmp = value * 100;
//        if (tmp % 10) {
//            return [[NSString alloc] initWithFormat:@"%.2f",value];
//        }
//        else{
//            return [[NSString alloc] initWithFormat:@"%.1f",value];
//        }
        NSString *oneString = NEW_STRING_WITH_FORMAT(@"%.1f",value);
        NSString *twoString = NEW_STRING_WITH_FORMAT(@"%.2f",value);
        NSString *newText = [twoString stringByReplacingOccurrencesOfString:oneString withString:@""];
        if ([newText floatValue] == 0) {
            return oneString;
        }
        return twoString;
    }
}

+(NSString*)getFloatValueString:(CGFloat)value decimal:(NSInteger)decimal
{
    if (decimal < 0) {
        decimal = 0;
    }
    NSString *format = NEW_STRING_WITH_FORMAT(@"%%.%ldf",decimal);
    CGFloat diff = value - (NSInteger)value;
    
    CGFloat d = 1 / powf(10, decimal);
    
    
    if (decimal == 0 || diff < d) {
        return [[NSString alloc] initWithFormat:@"%ld",(long)value];
    }
    else
    {
//        value += d / 2;
        return [[NSString alloc] initWithFormat:format, value];
    }
}

+(NSString*)getFloatValueString:(CGFloat)value lessThanZeroText:(NSString*)lessThanZeroText
{
    if (value < 0) {
        return lessThanZeroText;
    }
    return [[self class] getFloatValueString:value];
}

//+(CGRect)_getRectForPoints:(NSArray*)points
//{
//    if (!IS_AVAILABLE_NSSET_OBJ(points)) {
//        return CGRectZero;
//    }
//
//    UIEdgeInsets edgePoint = UIEdgeInsetsZero;
//    __block CGFloat top = 0;
//    __block CGFloat left = 0;
//    __block CGFloat bottom = 0;
//    __block CGFloat right = 0;
//
//    CGPoint firstPoint = CGPointZero;
//    id firstValue = [points firstObject];
//    if ([firstValue isKindOfClass:[NSValue class]]) {
//        firstPoint = [firstValue CGPointValue];
//    }
//    else if ([firstValue isKindOfClass:[NSWidgetPoint class]])
//    {
//        firstPoint = ((NSWidgetPoint*)firstValue).touchPoint;
//    }
//    edgePoint = UIEdgeInsetsMake(firstPoint.y, firstPoint.x, firstPoint.y, firstPoint.x);
//
//    left = edgePoint.left;
//    right = edgePoint.right;
//    top = edgePoint.top;
//    bottom = edgePoint.bottom;
//
//    [points enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        CGPoint pt = CGPointZero;
//        if ([obj isKindOfClass:[NSValue class]]) {
//            pt = [obj CGPointValue];
//        }
//        else if ([obj isKindOfClass:[NSWidgetPoint class]])
//        {
//            pt = ((NSWidgetPoint*)obj).touchPoint;
//        }
//
//        if (pt.x < left)
//        {
//            left = pt.x;
//        }
//        else if (pt.x > right)
//        {
//            right = pt.x;
//        }
//
//        if (pt.y < top) {
//            top = pt.y;
//        }
//        else if (pt.y > bottom)
//        {
//            bottom = pt.y;
//        }
//    }];
//
//    return CGRectMake(left, top, right-left, bottom-top);
//}

//+(CGRect)getRectForCGPoints:(NSArray<NSValue*>*)points
//{
//    return [Utils _getRectForPoints:points];
//}

//+(CGRect)getRectForNSWidgetPoints:(NSArray<NSWidgetPoint*>*)widgetPoints
//{
//    return [Utils _getRectForPoints:widgetPoints];
//}

//+(CGRect)getRectForEventPoints:(NSArray<NSArray<NSWidgetPoint*>*> *)eventPoints
//{
//    if (!IS_AVAILABLE_NSSET_OBJ(eventPoints)) {
//        return CGRectZero;
//    }
//
//    __block CGFloat x = 0;
//    __block CGFloat y = 0;
//    __block CGFloat r = 0;
//    __block CGFloat b = 0;
//    [eventPoints enumerateObjectsUsingBlock:^(NSArray<NSWidgetPoint *> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        CGRect rect = [Utils getRectForNSWidgetPoints:obj];
////        NSLog(@"rect=%@",NSStringFromCGRect(rect));
//        if (idx == 0) {
//            x = rect.origin.x;
//            y = rect.origin.y;
//            r = CGRectGetMaxX(rect);
//            b = CGRectGetMaxY(rect);
//        }
//        else
//        {
//            CGFloat maxX = CGRectGetMaxX(rect);
//            CGFloat maxY = CGRectGetMaxY(rect);
//            if (rect.origin.x < x) {
//                x = rect.origin.x;
//            }
//            if (rect.origin.y < y) {
//                y = rect.origin.y;
//            }
//            if (maxX > r) {
//                r = maxX;
//            }
//            if (maxY > b) {
//                b = maxY;
//            }
//        }
//    }];
////    return CGRectMake(left, top, right-left, bottom-top);
//    return CGRectMake(x, y, r - x, b - y);
//}

+(CGFloat)getAngleFromPoint:(CGPoint)from to:(CGPoint)to
{
    CGFloat shiftX = from.x - to.x;
    CGFloat shiftY = from.y - to.y;
    CGFloat distance = sqrt(shiftX * shiftX + shiftY * shiftY);
    if (distance == 0) {
        return 0;
    }
    shiftY = fabs(shiftY);
    return RADIANS_TO_DEGREES(asin(shiftY/distance));
}

//+(CGFloat)getAngleFromEventPoints:(NSArray<NSArray<NSWidgetPoint*>*> *)eventPoints
//{
//    if (!IS_AVAILABLE_NSSET_OBJ(eventPoints)) {
//        return -1;
//    }
//    NSWidgetPoint *first = [[eventPoints firstObject] firstObject];
//    NSWidgetPoint *last = [[eventPoints lastObject] lastObject];
//
//    return [Utils getAngleFromPoint:first.touchPoint to:last.touchPoint];
//}

+(CGFloat)getDistanceFromPoint:(CGPoint)from to:(CGPoint)to
{
    CGFloat shiftX = from.x - to.x;
    CGFloat shiftY = from.y - to.y;
    CGFloat distance = sqrt(shiftX * shiftX + shiftY * shiftY);
    return distance;
}


/*
 *0-top
 *1-left
 *2-botom
 *3-right
 */

//+(NSWidgetPoint*)_getPointFromWidgetPoints:(NSArray<NSWidgetPoint*> *)widgetPoints direction:(NSInteger)direction
//{
//    __block NSWidgetPoint *findObj = nil;
//    [widgetPoints enumerateObjectsUsingBlock:^(NSWidgetPoint * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        if (!findObj) {
//            findObj = obj;
//        }
//        else{
//            if (direction == 0) {
//                if (obj.touchPoint.y < findObj.touchPoint.y) {
//                    findObj = obj;
//                }
//            }
//            else if (direction == 2){
//                if (obj.touchPoint.y > findObj.touchPoint.y) {
//                    findObj = obj;
//                }
//            }
//            else if (direction == 1){
//                if (obj.touchPoint.x < findObj.touchPoint.x) {
//                    findObj = obj;
//                }
//            }
//            else if (direction == 3){
//                if (obj.touchPoint.x > findObj.touchPoint.x) {
//                    findObj = obj;
//                }
//            }
//        }
//    }];
//    return findObj;
//}

#if 1
//+(NSRecognizedTextType)_getTextTypeForWidgetPoints:(NSArray<NSWidgetPoint*> *)widgetPoints
//{
//    NSRecognizedTextType textType = NSRecognizedTextTypeATKText;
//    if (!IS_AVAILABLE_NSSET_OBJ(widgetPoints)) {
//        return textType;
//    }
//    CGPoint firstPoint = [widgetPoints firstObject].touchPoint;
//    CGPoint lastPoint = [widgetPoints lastObject].touchPoint;
//    CGPoint topPoint = [[self class] _getPointFromWidgetPoints:widgetPoints direction:0].touchPoint;
//    CGPoint botPoint = [[self class] _getPointFromWidgetPoints:widgetPoints direction:2].touchPoint;
//
//    CGFloat maxAngle = [Utils getAngleFromPoint:firstPoint to:lastPoint];
//
//    CGRect rect = [Utils getRectForNSWidgetPoints:widgetPoints];
//
//    if (IS_SLASH_FOR_ANGLE(maxAngle)) {
//        if (topPoint.x > botPoint.x) {
//            //正斜线
//            textType = NSRecognizedTextTypeIMForwardSlash;
//        }
//        else
//        {
//            //反斜线
//            textType = NSRecognizedTextTypeIMBackSlash;
//        }
//    }
//    else if (IS_HLINE_FOR_ANGLE(maxAngle))
//    {
//        if (rect.size.height > 0 && rect.size.width/rect.size.height > 3) {
//            textType = NSRecognizedTextTypeIMHLine;
//        }
//    }
//    else if (IS_VLINE_FOR_ANGLE(maxAngle))
//    {
//        if (rect.size.width > 0 && rect.size.height/rect.size.width > 3) {
//            textType = NSRecognizedTextTypeIMVLine;
//        }
//    }
//    return textType;
//}
//
//+(NSRecognizedTextType)getTextTypeForWidgetPoints:(NSArray<NSWidgetPoint*> *)widgetPoints
//{
//    NSRecognizedTextType textType = [Utils _getTextTypeForWidgetPoints:widgetPoints];
//    if (textType != NSRecognizedTextTypeATKText) {
//        NSInteger cnt = widgetPoints.count;
//        NSArray *half = [widgetPoints subarrayWithRange:NSMakeRange(cnt/2, cnt-cnt/2)];
//        NSRecognizedTextType textTypeT = [Utils _getTextTypeForWidgetPoints:half];
//        if (textTypeT != textType) {
//            return NSRecognizedTextTypeATKText;
//        }
//    }
//    return textType;
//}
#endif

//+(NSArray<NSArray<NSWidgetPoint*>*>*)getLastEventPointsFromEventPoints:(NSArray<NSArray<NSWidgetPoint*>*> *)eventPoints withEventRect:(CGRect)eventRect candidateEventPoints:(NSArray<NSArray<NSWidgetPoint*>*> **)candidatesEventPoints
//{
//    if (!IS_AVAILABLE_NSSET_OBJ(eventPoints)) {
//        return nil;
//    }
//    if (CGRectIsEmpty(eventRect)) {
//        return nil;
//    }
//
//#if 0
//    NSMutableArray<NSArray<NSWidgetPoint*>*> *intersectsEventPoints = [NSMutableArray array];
//    NSMutableArray<NSArray<NSWidgetPoint*>*> *newEventPoints = [NSMutableArray array];
//
//    for (NSArray<NSWidgetPoint*>* event in eventPoints) {
//        CGRect rect = [Utils getRectForNSWidgetPoints:event];
//        CGPoint centerPoint = CGRECT_CENTER_POINT(rect);
//        if (CGRectContainsPoint(eventRect, centerPoint)) {
//            [newEventPoints addObject:event];
//        }
//        else if (CGRectIntersectsRect(eventRect, rect))
//        {
//            CGFloat eventCenterY = CGRectGetMidY(eventRect);
//            CGFloat centerY = CGRectGetMidY(rect);
//            CGFloat diffY = fabs(eventCenterY - centerY);
//            CGFloat maxShiftY = MAX(CGRectGetHeight(eventRect), CGRectGetHeight(rect))/2;
//            if (diffY < maxShiftY) {
//                [intersectsEventPoints addObject:event];
//            }
//        }
//    }
//
//    CGRect newRect = [Utils getRectForEventPoints:newEventPoints];
//    NSMutableArray <NSArray<NSWidgetPoint*>*> *newIntersects = [NSMutableArray array];
//    for (NSArray<NSWidgetPoint*>* event in intersectsEventPoints) {
//        CGRect rect = [Utils getRectForNSWidgetPoints:event];
//        if (CGRectIntersectsRect(newRect, rect)) {
//            CGFloat newCenterY = CGRectGetMidY(newRect);
//            CGFloat centerY = CGRectGetMidY(rect);
//            CGFloat diffY = fabs(newCenterY - centerY);
//            CGFloat maxShiftY = MAX(CGRectGetHeight(newRect), CGRectGetHeight(rect))/2;
//            if (diffY < maxShiftY) {
//                [newIntersects addObject:event];
//            }
//        }
//    }
//    NSLog(@"newIntersects=%@",newIntersects);
//    [newEventPoints addObjectsFromArray:newIntersects];
//    return newEventPoints;
//#else
//    NSMutableArray<NSArray<NSWidgetPoint*>*> *newEventPoints = [NSMutableArray array];
//    NSMutableArray<NSArray<NSWidgetPoint*>*> *candidatePoints = [NSMutableArray array];
//    NSInteger i = 0;
//    NSInteger startIndex = -1;
//    NSInteger endIndex = -1;
//    CGFloat eventCenterY = CGRectGetMidY(eventRect);
//    for (NSArray<NSWidgetPoint*>* event in eventPoints) {
//        CGRect tmpRect = [Utils getRectForNSWidgetPoints:event];
//        CGPoint tmpCenter = CGRECT_CENTER_POINT(tmpRect);
//        NSTimeInterval timerInterval = [event firstObject].timerInterval;
//        if (CGRectContainsPoint(eventRect, tmpCenter)) {
//            if (startIndex < 0) {
//                startIndex = i;
//            }
//            else
//            {
//                //说明中间出现了“断裂”，把原来的清除掉，从断裂处重新开始计算。
//                if (i > endIndex + 1) {
//                    [newEventPoints removeAllObjects];
//                    [candidatePoints removeAllObjects];
//                    startIndex = i;
//                }
//            }
//            endIndex = i;
//            [newEventPoints addObject:event];
//        }
//        else if (CGRectIntersectsRect(eventRect, tmpRect))
//        {
//            BOOL addToNewEvents = NO;
//
//            CGFloat tmpCenterY = CGRectGetMidY(tmpRect);
//            if (IS_AVAILABLE_NSSET_OBJ(newEventPoints)) {
//                //判断是否和已经确认的最后一笔有交集，有的交集的话，则加入进来。
//                NSArray<NSWidgetPoint*> *lastEvent = [newEventPoints lastObject];
//                CGRect lastRect = [Utils getRectForNSWidgetPoints:lastEvent];
//                if (CGRectIntersectsRect(lastRect, tmpRect)) {
//                    CGFloat lastCenterY = CGRectGetMidY(lastRect);
//                    CGFloat diffY = fabs(lastCenterY - tmpCenterY);
//                    CGFloat maxShiftY = MAX(CGRectGetHeight(lastRect), CGRectGetHeight(tmpRect)) * 2/3;
//                    NSInteger lastTimerInterval = [lastEvent firstObject].timerInterval;
//                    if (diffY < maxShiftY && lastTimerInterval - timerInterval <= STROKE_TIMER_INTERVAL_TO_JOIN) {
//                        addToNewEvents = YES;
//                    }
//                }
//            }
//            else
//            {
//                //判断是否和eventRect有交集
//                CGFloat diffY = fabs(eventCenterY - tmpCenterY);
//                CGFloat maxShiftY = MAX(CGRectGetHeight(eventRect), CGRectGetHeight(tmpRect)) * 2/3;
//                if (diffY < maxShiftY) {
//                    //判断下一笔的中心点是否在eventRect，如果是的话，也将此笔画插入进来
//                    NSInteger nextId = i + 1;
//                    if (eventPoints.count > nextId) {
//                        NSArray<NSWidgetPoint*>* nextEvent = eventPoints[nextId];
//                        CGRect nextRect = [Utils getRectForNSWidgetPoints:nextEvent];
//                        CGPoint nextCenter = CGRECT_CENTER_POINT(nextRect);
//                        NSTimeInterval nextTimerInterval = [nextEvent firstObject].timerInterval;
//                        if (CGRectContainsPoint(eventRect, nextCenter) && nextTimerInterval - timerInterval <= STROKE_TIMER_INTERVAL_TO_JOIN) {
//                            addToNewEvents = YES;
//                        }
//                    }
//                }
//            }
//            if (addToNewEvents) {
//                endIndex = i;
//                [newEventPoints addObject:event];
//            }
//
//            [candidatePoints addObject:event];
//        }
//        ++i;
//    }
//    if (candidatesEventPoints) {
//        *candidatesEventPoints = candidatePoints;
//    }
//    return newEventPoints;
//#endif
//}

+(BOOL)isAtHorizontalLineForRect:(CGRect)firstRect nextRect:(CGRect)nextRect
{
    CGFloat firstH = firstRect.size.height;
    CGFloat nextH = nextRect.size.height;
    
    CGFloat maxH = MAX(firstH, nextH);
    CGFloat minH = MIN(firstH, nextH);
    if (minH > maxH/2) {
        CGFloat firstMinY = CGRectGetMinY(firstRect);
        CGFloat firstMaxY = CGRectGetMaxY(firstRect);
        CGFloat firstMidY = CGRectGetMidY(firstRect);
        
        CGFloat nextMinY = CGRectGetMinY(nextRect);
        CGFloat nextMaxY = CGRectGetMaxY(nextRect);
        CGFloat nextMidY = CGRectGetMidY(nextRect);
        
        if ((nextMidY >= firstMinY && nextMidY <= firstMaxY) || (firstMidY >= nextMinY && firstMidY <= nextMaxY) ) {
            return YES;
        }
    }
    else{
        if (CGRectIntersectsRect(firstRect, nextRect)) {
            return YES;
        }
        CGFloat minY = 0;
        CGFloat maxY = 0;
        CGFloat minMidY = 0;
        CGFloat shiftYRatio = 0.25;
        
        if (firstH > nextH) {
            minY = firstRect.origin.y - shiftYRatio * firstH;
            minY = MAX(minY, 0);
            maxY = CGRectGetMaxY(firstRect) + shiftYRatio * firstH;
            
            minMidY = CGRectGetMidY(nextRect);
        }
        else{
            minY = nextRect.origin.y - shiftYRatio * nextH;
            minY = MAX(minY, 0);
            maxY = CGRectGetMaxY(nextRect) + shiftYRatio * nextH;
            
            minMidY = CGRectGetMidY(firstRect);
        }
        
        if (minMidY >= minY && minMidY <= maxY) {
            return YES;
        }
    }
    return NO;
}

+(CGFloat)getHorizontalSpaceForRect:(CGRect)firstRect nextRect:(CGRect)nextRect
{
    if (CGRectGetMaxX(firstRect) <= CGRectGetMinX(nextRect)) {
        return CGRectGetMinX(nextRect) - CGRectGetMaxX(firstRect);
    }
    else if (CGRectGetMaxX(nextRect) <= CGRectGetMinX(firstRect))
    {
        return CGRectGetMinX(firstRect) - CGRectGetMaxX(nextRect);
    }
    return 0;
}

//+(CGFloat)getStrokeHorizontalSpaceForEventPoints:(NSArray<NSArray<NSWidgetPoint*>*> *)eventPoints
//{
//    __block CGFloat totalSpace = 0;
//    __block NSInteger cnt = 0;
//    __block CGRect lastRect = CGRectZero;
//    [eventPoints enumerateObjectsUsingBlock:^(NSArray<NSWidgetPoint *> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        CGRect rect = [Utils getRectForNSWidgetPoints:obj];
//        if (idx == 0) {
//            lastRect = rect;
//        }
//        else
//        {
//            if (!CGRectIntersectsRect(lastRect, rect) ) {
//
//                if (CGRectGetMinX(lastRect) < CGRectGetMinX(rect)) {
//                    CGFloat diffX = CGRectGetMinX(rect) - CGRectGetMaxX(lastRect);
//                    if (diffX > 0) {
//                        totalSpace += diffX;
//                        ++cnt;
//                    }
//                }
//                else
//                {
//                    CGFloat diffX = CGRectGetMinX(lastRect) - CGRectGetMaxX(rect);
//                    if (diffX > 0) {
//                        totalSpace += diffX;
//                        ++cnt;
//                    }
//                }
//            }
//        }
//    }];
//    if (cnt == 0) {
//        return 0;
//    }
//    return totalSpace/cnt;
//}

//+(CGFloat)getStrokeWidthForEventPoints:(NSArray<NSArray<NSWidgetPoint*>*> *)eventPoints
//{
//    if (!IS_AVAILABLE_NSSET_OBJ(eventPoints)) {
//        return 0;
//    }
//    CGRect rect = [Utils getRectForEventPoints:eventPoints];
//    CGFloat strokes = eventPoints.count * 0.83;
////    if (eventPoints.count == 1) {
////        strokes = 1;
////    }
//
//    return rect.size.width/strokes;
//}

+(CGRect)getOutRectForRect:(CGRect)firstRect nextRect:(CGRect)nextRect shouldIntersect:(BOOL)intersects
{
    CGFloat minX = 0;
    CGFloat maxX = 0;
    CGFloat minY = 0;
    CGFloat maxY = 0;
    
    if ((intersects && CGRectIntersectsRect(firstRect, nextRect)) || intersects== NO) {
        minX = MIN(firstRect.origin.x, nextRect.origin.x);
        maxX = MAX(CGRectGetMaxX(firstRect), CGRectGetMaxX(nextRect));
        minY = MIN(firstRect.origin.y, nextRect.origin.y);
        maxY = MAX(CGRectGetMaxY(firstRect), CGRectGetMaxY(nextRect));
    }
    return CGRectMake(minX, minY, maxX-minX, maxY-minY);
}

//+(BOOL)isFloatNumberForEventPoints:(NSArray<NSArray<NSWidgetPoint*>*> *)eventPoints floatPointAtIndex:(NSInteger*)pointAtIndex
//{
//    //1.这样写的格式
//    if (eventPoints.count < 2) {
//        return NO;
//    }
//    NSArray *firstStroke = [eventPoints firstObject];
//    CGRect prevRect = [Utils getRectForNSWidgetPoints:firstStroke];
//    NSInteger cnt = eventPoints.count;
//    BOOL isFloat = NO;
//    NSInteger index = 1;
//    for (index = 1; index < cnt; ++index) {
//        NSArray *stroke = eventPoints[index];
//        CGRect strokeRect = [Utils getRectForNSWidgetPoints:stroke];
////        NSLog(@"prevRect=%@,strokeRect=%@,center=%@",NSStringFromCGRect(prevRect),NSStringFromCGRect(strokeRect),NSStringFromCGPoint(CGRECT_CENTER_POINT(prevRect)));
////        NSLog(@"=================================ratio=%f",prevRect.size.height/strokeRect.size.height);
//        if (strokeRect.size.height < prevRect.size.height/5) {
//            CGFloat topY = prevRect.origin.y + prevRect.size.height/4;
////            NSLog(@"topY=%f,strokeMaxY=%f,StrokeSize=%@",topY,CGRectGetMaxY(strokeRect),NSStringFromCGSize(strokeRect.size));
//            if (topY < CGRectGetMaxY(strokeRect) && strokeRect.size.width <= 2 * strokeRect.size.height) {
//                isFloat = YES;
//                break;
//            }
//        }
//        else if (strokeRect.size.height < prevRect.size.height/2) {
////            NSLog(@"centerY=%f,strokeMaxY=%f,StrokeSize=%@",CGRECT_CENTER_POINT(prevRect).y,CGRectGetMaxY(strokeRect),NSStringFromCGSize(strokeRect.size));
//            if (strokeRect.size.width < strokeRect.size.height && CGRECT_CENTER_POINT(prevRect).y < CGRectGetMaxY(strokeRect) && CGRectGetMaxX(strokeRect) > CGRectGetMaxX(prevRect) && strokeRect.size.width <= 2 * strokeRect.size.height) {
//                isFloat = YES;
//                break;
//            }
//        }
//        NSArray<NSArray<NSWidgetPoint*>*> *sub = [eventPoints subarrayWithRange:NSMakeRange(0, index+1)];
//        prevRect = [Utils getRectForEventPoints:sub];
//    }
//    if (isFloat) {
//        if (pointAtIndex) {
//            *pointAtIndex = index;
//        }
//    }
//    return isFloat;
////    if (!isFloat) {
////        return NO;
////    }
////    if (isFloat) {
////        NSArray<NSWidgetPoint*> *stroke = eventPoints[index];
////        NSRecognizedTextType textType = [Utils getTextTypeForSingleStroke:stroke];
////        NSLog(@"floatPoint===========textType=%ld",textType);        
////    }
////    CGPoint firstPt = [stroke firstObject].touchPoint;
////    CGPoint lastPt = [stroke lastObject].touchPoint;
////
////    if (firstPt.x <= lastPt.x/* && firstPt.y <= lastPt.y*/) {
////        if (pointAtIndex) {
////            *pointAtIndex = index;
////        }
////        return isFloat;
////    }
////    return NO;
//}

//+(BOOL)isJointToFloatNumberForEventPoints:(NSArray<NSArray<NSWidgetPoint*>*>*)eventPoints stroke:(NSArray<NSWidgetPoint*>*)stroke
//{
//    if (!IS_AVAILABLE_NSSET_OBJ(eventPoints)) {
//        return NO;
//    }
//    if (!IS_AVAILABLE_NSSET_OBJ(stroke)) {
//        return NO;
//    }
//    BOOL prevIsFloat = [Utils isFloatNumberForEventPoints:eventPoints floatPointAtIndex:NULL];
//    if (prevIsFloat) {
//        return NO;
//    }
//    NSMutableArray *newEvent = [eventPoints mutableCopy];
//    [newEvent addObject:stroke];
//    return [Utils isFloatNumberForEventPoints:newEvent floatPointAtIndex:NULL];
//}

//+(NSArray<NSWidgetPoint*>*)getFloatPointStrokeForEventPoints:(NSArray<NSArray<NSWidgetPoint*>*> *)eventPoints floatPointStroke:(NSArray<NSWidgetPoint*>*)floatPointStroke
//{
//    BOOL isFloat = [Utils isJointToFloatNumberForEventPoints:eventPoints stroke:floatPointStroke];
//    if (!isFloat) {
//        return nil;
//    }
//
//    NSMutableArray<NSWidgetPoint*> *newStroke = [NSMutableArray array];
//    CGRect prevRect = [Utils getRectForEventPoints:eventPoints];
//#if 1
//    //这里进行一半截取
//    NSInteger totalCnt = floatPointStroke.count;
//    if (totalCnt >= 10) {
//        newStroke = [[floatPointStroke subarrayWithRange:NSMakeRange(0, totalCnt/2)] mutableCopy];
//        NSWidgetPoint *last = [newStroke lastObject];
//        last.touchStatus = UITouchStatusEnd;
//    }
//    else{
//        newStroke = [floatPointStroke mutableCopy];
//    }
//#else
//    //这里进行高度截取
//    CGRect floatPointRect = [Utils getRectForNSWidgetPoints:floatPointStroke];
//
//    CGFloat floatPointMaxHeight = prevRect.size.height/4;
//    if (floatPointRect.size.height > floatPointMaxHeight) {
//        CGFloat maxY = floatPointRect.origin.y + floatPointMaxHeight;
//        for (NSWidgetPoint *wdPt in floatPointStroke) {
//            if (wdPt.touchPoint.y <= maxY) {
//                [newStroke addObject:wdPt];
//            }
//        }
//        NSWidgetPoint *first = [newStroke firstObject];
//        first.touchStatus = UITouchStatusBegin;
//
//        NSWidgetPoint *last = [newStroke lastObject];
//        last.touchStatus = UITouchStatusEnd;
//    }
//    else{
//        newStroke = [floatPointStroke mutableCopy];
//    }
//#endif
//
//    //这里进行向下平移
//    CGFloat bottomY = [Utils _getPointFromWidgetPoints:newStroke direction:2].touchPoint.y;
//    CGFloat shift = CGRectGetMaxY(prevRect) - bottomY;
//    if (shift > 0) {
//        [newStroke enumerateObjectsUsingBlock:^(NSWidgetPoint * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//            obj.touchPoint = CGPointMake(obj.touchPoint.x, obj.touchPoint.y + shift);
//        }];
//    }
//    return newStroke;
//}

//+(NSArray<NSArray<NSWidgetPoint*>*>*)changeFloatNumberPointForEventPoints:(NSArray<NSArray<NSWidgetPoint*>*> *)eventPoints
//{
//    NSInteger index = -1;
//    BOOL isFloatNumber = [Utils isFloatNumberForEventPoints:eventPoints floatPointAtIndex:&index];
//    if (!isFloatNumber) {
//        return nil;
//    }
//    if (index < 0 || index >= eventPoints.count) {
//        return nil;
//    }
//    NSArray<NSWidgetPoint*> *floatStroke = eventPoints[index];
//    NSArray<NSArray<NSWidgetPoint*>*> *subEvent = [eventPoints subarrayWithRange:NSMakeRange(0, index)];
//
//    NSArray<NSWidgetPoint*> *newStroke = [Utils getFloatPointStrokeForEventPoints:subEvent floatPointStroke:floatStroke];
//    if (newStroke) {
//        NSMutableArray *oldEvent = [eventPoints mutableCopy];
//        oldEvent[index] = newStroke;
//        return oldEvent;
//    }
//    return nil;
//}

//+(BOOL)haveSingleLineText:(NSString*)text candidateWords:(NSArray<NSString*>*)candidateWords textType:(NSRecognizedTextType)textType
//{
//    NSRegularExpression *lineRegularExpression = nil;
//    if (textType == NSRecognizedTextTypeIMForwardSlash) {
//        lineRegularExpression = [NSRegularExpression regularExpressionWithPattern:@"/" options:0 error:nil];
//    }
//    else if (textType == NSRecognizedTextTypeIMBackSlash) {
//        lineRegularExpression = [NSRegularExpression regularExpressionWithPattern:@"\\\\" options:0 error:nil];
//    }
//    else if (textType == NSRecognizedTextTypeIMHLine) {
//        lineRegularExpression = [NSRegularExpression regularExpressionWithPattern:@"[-_]" options:0 error:nil];
//    }
//    else if (textType == NSRecognizedTextTypeIMVLine) {
//        lineRegularExpression = [NSRegularExpression regularExpressionWithPattern:@"[|1Il]" options:0 error:nil];
//    }
//
//    if (IS_AVAILABLE_NSSTRNG(text)) {
//        text = [lineRegularExpression stringByReplacingMatchesInString:text options:0 range:NSMakeRange(0, text.length) withTemplate:@""];
//        if (text.length == 0) {
//            return YES;
//        }
//    }
//    for (NSString *candidate in candidateWords) {
//        NSString *tmp = [lineRegularExpression stringByReplacingMatchesInString:candidate options:0 range:NSMakeRange(0, candidate.length) withTemplate:@""];
//        if (tmp.length == 0) {
//            NSLog(@"candidate=%@",candidate);
//            return YES;
//        }
//    }
//    return NO;
//}

//+(NSRecognizedTextType)getSingleLineTextTypeFromText:(NSString*)text candidateWords:(NSArray<NSString*>*)candidateWords eventPoints:(NSArray<NSArray<NSWidgetPoint*>*> *)eventPoints
//{
//    if (eventPoints.count != 1) {
//        return NSRecognizedTextTypeATKText;
//    }
//    NSArray<NSWidgetPoint*> *stroke = [eventPoints firstObject];
//    if (!IS_AVAILABLE_NSSET_OBJ(stroke)) {
//        return NSRecognizedTextTypeATKText;
//    }
//
//    NSRecognizedTextType textType = [Utils getTextTypeForSingleStroke:stroke];
//    if (!IS_SINGLE_LINE_FOR_TEXTTYPE(textType)) {
//        return NSRecognizedTextTypeATKText;
//    }
//    CGPoint firstPt = [stroke firstObject].touchPoint;
//    CGPoint lastPt = [stroke lastObject].touchPoint;
//
//    if (textType == NSRecognizedTextTypeIMForwardSlash && [Utils haveSingleLineText:text candidateWords:candidateWords textType:textType]) {
//        if (firstPt.x < lastPt.x && firstPt.y > lastPt.y) {
//            return textType;
//        }
//    }
//    else if (textType == NSRecognizedTextTypeIMBackSlash && [Utils haveSingleLineText:text candidateWords:candidateWords textType:textType]){
//        if (firstPt.x < lastPt.x && firstPt.y < lastPt.y) {
//            return textType;
//        }
//    }
//    else if (textType == NSRecognizedTextTypeIMHLine && [Utils haveSingleLineText:text candidateWords:candidateWords textType:textType]){
//        if (firstPt.x < lastPt.x) {
//            return textType;
//        }
//    }
//    else if (textType == NSRecognizedTextTypeIMVLine && [Utils haveSingleLineText:text candidateWords:candidateWords textType:textType]){
//        if (firstPt.y < lastPt.y) {
//            return textType;
//        }
//    }
//    return NSRecognizedTextTypeATKText;
//}

//+(CGLineEquation)getLineEquationForWidgetPoints:(NSArray<NSWidgetPoint*> *)widgetPoints
//{
//    if (!IS_AVAILABLE_NSSET_OBJ(widgetPoints) || widgetPoints.count < 2) {
//        return CGLineEquationZero;
//    }
//
//    CGPoint firstPt = [widgetPoints firstObject].touchPoint;
//    CGPoint lastPt = [widgetPoints lastObject].touchPoint;
//    CGFloat diffX = lastPt.x - firstPt.x;
//    CGFloat diffY = lastPt.y - firstPt.y;
//
//    CGLineEquation lineEquation = CGLineEquationZero;
//    if (diffX == 0) {
//        lineEquation.A = 1;
//        lineEquation.B = 0;
//    }
//    else{
//        lineEquation.A = diffY/diffX;
//        lineEquation.B = -1;
//    }
//    lineEquation.C = -lineEquation.A * firstPt.x - lineEquation.B * firstPt.y;
//    return lineEquation;
//}

+(CGFloat)getDistanceFromPoint:(CGPoint)point toLine:(CGLineEquation)lineEquation
{
    if (CGLineEquationIsNull(lineEquation)) {
        return -1;
    }
    CGFloat tmp = lineEquation.A * point.x + lineEquation.B * point.y + lineEquation.C;
//    NSLog(@"tmp=%f",tmp);
    return fabs(tmp)/sqrt(lineEquation.A * lineEquation.A + lineEquation.B * lineEquation.B);
}

//+(CGFloat)getLineWidthForWidgetPoints:(NSArray<NSWidgetPoint*>*)widgetPoints maxUpDistance:(CGFloat*)maxUpDistance maxDownDistance:(CGFloat*)maxDownDistance
//{
//    CGLineEquation leq = [[self class] getLineEquationForWidgetPoints:widgetPoints];
//    if (CGLineEquationIsNull(leq)) {
//        return 0;
//    }
////    NSLog(@"A=%f,B=%f,C=%f",leq.A,leq.B,leq.C);
//
//    CGFloat maxUD = 0;
//    CGFloat maxDD = 0;
//    NSInteger i = 1;
//    NSInteger totalCnt = widgetPoints.count;
//    for (i = 1; i < totalCnt-1; ++i) {
//        CGPoint p = widgetPoints[i].touchPoint;
//        CGFloat tmp = leq.A * p.x + leq.B * p.y + leq.C;
//        if (tmp > 0) {
//            maxUD = fmax(maxUD, tmp);
//        }
//        else{
//            maxDD = fmin(maxDD, tmp);
//        }
////        NSLog(@"p=%@,distance=%f",NSStringFromCGPoint(p),tmp);
//    }
//
//    NSInteger h = sqrt(leq.A * leq.A + leq.B * leq.B);
//    maxUD = maxUD / h;
//    maxDD = maxDD / h;
//
//    if (maxUpDistance) {
//        *maxUpDistance = maxUD;
//    }
//    if (maxDownDistance) {
//        *maxDownDistance = maxDD;
//    }
////    NSLog(@"maxDD=%f,maxUD=%f",maxDD,maxUD);
//    return fabs(maxUD) + fabs(maxDD);
//}

//+(NSRecognizedTextType)getTextTypeForSingleStroke:(NSArray<NSWidgetPoint *>*)stroke
//{
//    if (!IS_AVAILABLE_NSSET_OBJ(stroke)) {
//        return NSRecognizedTextTypeNull;
//    }
//    CGLineEquation leq = [[self class] getLineEquationForWidgetPoints:stroke];
//    if (CGLineEquationIsNull(leq)) {
//        return NSRecognizedTextTypeIMDot;
//    }
//
//    CGPoint firstPt = [stroke firstObject].touchPoint;
//    CGPoint lastPt = [stroke lastObject].touchPoint;
//
//    CGFloat maxUD = 0;
//    CGFloat maxDD = 0;
//    CGFloat lineLength = [[self class] getDistanceFromPoint:firstPt to:lastPt];
//    if (MIN_LINE_LEN > 0 && lineLength < MIN_LINE_LEN) {
//        return NSRecognizedTextTypeIMDot;
//    }
//    CGFloat lineWidth = [[self class] getLineWidthForWidgetPoints:stroke maxUpDistance:&maxUD maxDownDistance:&maxDD];
//    if (lineWidth <= 0) {
//        return NSRecognizedTextTypeATKText;
//    }
//    CGFloat maxAngle = [Utils getAngleFromPoint:firstPt to:lastPt];
//
//    CGPoint bottomPt = [[self class] _getPointFromWidgetPoints:stroke direction:2].touchPoint;
//
//    NSRecognizedTextType textType = NSRecognizedTextTypeATKText;
//
//    CGFloat lineLWRatio = lineLength/lineWidth;
//
//    CGFloat maxDDRatio = fabs(maxDD)/lineWidth;
////    NSLog(@"lineL=%f,lineW=%f,lineLWRatio=%f,maxUD=%f,maxDD=%f",lineLength,lineWidth,lineLWRatio,maxUD,maxDD);
//
////    NSLog(@"maxAngle=%f,maxDDRatio=%f",maxAngle,maxDDRatio);
//
//    if (lineLWRatio >= 3.0) {
//        if (IS_SLASH_FOR_ANGLE(maxAngle))
//        {
//            if (IS_FORWARD_SLASH(firstPt, lastPt)) {
//                if (IS_LDRU_FORWARD_SLASH(firstPt, lastPt) && LR_OPEN_INTERVA(bottomPt.x, firstPt.x, lastPt.x) && (maxDD < 0 && maxDDRatio > 0.8)) {
//                    textType = NSRecognizedTextTypeIMRightTick;
//                }
//                else{
//                    if (IS_RULD_FORWARD_SLASH(firstPt, lastPt)) {
//                        //和6做区分出来
//                        CGFloat distance = [[self class] getDistanceFromPoint:lastPt to:bottomPt];
//                        CGFloat ratio = distance / lineLength;
////                        NSLog(@"bottom-last.distance=%f,ratio=%f",distance,ratio);
//                        if (ratio < 0.08) {
//                            textType = NSRecognizedTextTypeIMForwardSlash;
//                        }
//                    }
//                    else{
//                        textType = NSRecognizedTextTypeIMForwardSlash;
//                    }
//                }
//            }
//            else if (IS_BACK_SLASH(firstPt, lastPt)){
//                textType = NSRecognizedTextTypeIMBackSlash;
//            }
//        }
//        else if (IS_HLINE_FOR_ANGLE(maxAngle)) {
//            textType = NSRecognizedTextTypeIMHLine;
//        }
//        else if (IS_VLINE_FOR_ANGLE(maxAngle)) {
//             textType = NSRecognizedTextTypeIMVLine;
//        }
//    }
//    if (textType == NSRecognizedTextTypeATKText && IS_SLASH_FOR_ANGLE(maxAngle)) {
//        if (IS_LDRU_FORWARD_SLASH(firstPt, lastPt) && LR_OPEN_INTERVA(bottomPt.x, firstPt.x, lastPt.x) && (maxDD < 0 && maxDDRatio > 0.8)) {
//            textType = NSRecognizedTextTypeIMRightTick;
//        }
//    }
//    return textType;
//}

//+(CGFloat)getContainsPointsRatioForRect:(CGRect)rect eventPints:(NSArray<NSArray<NSWidgetPoint*>*>*)eventPoints
//{
//    if (!IS_AVAILABLE_NSSET_OBJ(eventPoints)) {
//        return 0;
//    }
//
//    __block NSInteger containsCnt = 0;
//    __block NSInteger totalCnt = 0;
//    NSMutableArray *containsPoints = [NSMutableArray array];
//
//    [eventPoints enumerateObjectsUsingBlock:^(NSArray<NSWidgetPoint *> * _Nonnull widgetPoints, NSUInteger idx, BOOL * _Nonnull stop) {
//        totalCnt += widgetPoints.count;
//        [widgetPoints enumerateObjectsUsingBlock:^(NSWidgetPoint * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//            if (CGRectContainsPoint(rect, obj.touchPoint)) {
//                ++containsCnt;
//                [containsPoints addObject:obj];
//            }
//        }];
//    }];
//
//    CGRect eventSubRect = [Utils getRectForNSWidgetPoints:containsPoints];
//    if (CGRectContainsPoint(eventSubRect, CGRECT_CENTER_POINT(rect))) {
//        return 1.0;
//    }
//
//    CGFloat ratio = 0;
//    if (totalCnt > 0) {
//        ratio = containsCnt * 1.0/totalCnt;
//    }
////    if (eventSubRect.size.height > rect.size.height/2) {
////        return 0.5 + 0.5 * ratio;
////    }
//    return ratio;
//}

+(NSString*)changeIntegerStringForText:(NSString*)text changeValue:(NSInteger)changeValue
{
    if (changeValue == 0) {
        return text;
    }
    NSScanner *scanner = [NSScanner scannerWithString:text];
    NSString *skipString = nil;
    [scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&skipString];
    NSInteger integer = 0;
    BOOL haveNumber = [scanner scanInteger:&integer];
    if (haveNumber == NO) {
        return text;
    }
    NSInteger numberEndLocation = scanner.scanLocation;
    if ([scanner isAtEnd] == NO) {
        NSString *skipStringTmp = nil;
        NSInteger integetTmp = 0;
        [scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&skipStringTmp];
        haveNumber = [scanner scanInteger:&integetTmp];
        if (haveNumber) {
            return text;
        }
    }
    integer = integer + changeValue;
    NSString *newNumberText = [[NSString alloc] initWithFormat:@"%ld",integer];
    NSInteger startLocation = 0;
    if (skipString) {
        startLocation = skipString.length;
    }
    text = [text stringByReplacingCharactersInRange:NSMakeRange(startLocation, numberEndLocation-startLocation) withString:newNumberText];
    return text;
}

+(BOOL)isAvailableIntegerStringForText:(NSString *)text
{
    NSString *new = [[self class] changeIntegerStringForText:text changeValue:1];
    if ([new isEqualToString:text]) {
        return NO;
    }
    return YES;
}

+(NSInteger)integerValueForText:(NSString*)text
{
    NSScanner *scanner = [NSScanner scannerWithString:text];
    NSString *skipString = nil;
    [scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&skipString];
    NSInteger integer = 0;
    BOOL haveNumber = [scanner scanInteger:&integer];
    if (haveNumber == NO) {
        return -1;
    }
    return integer;
}


+(NSData*)UIImageToDataRepresentation:(UIImage*)image
{
    NSData *data = UIImagePNGRepresentation(image);
    if (data == nil) {
        data = UIImageJPEGRepresentation(image, 1.0);
    }
    return data;
}

+(NSInteger)mainQuestionIdForQuestionId:(NSString*)questionId
{
    NSArray *result = [questionId componentsSeparatedByString:@"."];
    if (IS_AVAILABLE_NSSET_OBJ(result)) {
        return [result[0] integerValue];
    }
    return 0;
}

+(NSInteger)subQuestionIdForQuestionId:(NSString*)questionId
{
    NSArray *result = [questionId componentsSeparatedByString:@"."];
    if (result.count > 1) {
        return [result[1] integerValue];
    }
    return 0;
}

+(BOOL)isMacStringForText:(NSString*)macText
{
    if (!IS_AVAILABLE_NSSTRNG(macText)) {
        return NO;
    }
    NSArray *array = [macText componentsSeparatedByString:@":"];
    if (array.count == 6) {
        for (NSString *sub in array) {
            if (![Utils isHexIntegerNumberForString:sub]) {
                return NO;
            }
        }
        return YES;
    }
    return NO;
}

+(NSString*)getMacStringForText:(NSString*)macText
{
    if (!IS_AVAILABLE_NSSTRNG(macText)) {
        return @"";
    }
    if ([Utils isMacStringForText:macText]) {
        return macText;
    }
    NSMutableString *mutString = [NSMutableString stringWithString:macText];
    NSInteger lenght = macText.length;
    for (NSInteger i = lenght-2; i > 0; i = i - 2) {
        [mutString insertString:@":" atIndex:i];
    }
    
    if ([Utils isMacStringForText:mutString]) {
        return [mutString copy];
    }
    return @"";
}
@end

