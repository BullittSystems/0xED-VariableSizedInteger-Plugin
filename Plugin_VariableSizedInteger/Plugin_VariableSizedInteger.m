//
//  Plugin_VariableSizedInteger.m
//
//  Copyright (c) 2014 BullittSystems, Inc. All rights reserved.
//

#import "Plugin_VariableSizedInteger.h"

#define LOW_BYTE_MASK 0xFF
#define DATA_MASK 0x7F
#define BASE_128_SHIFT 0x7
#define HAS_MORE_DATA_BIT_MASK 0x80

@implementation Plugin_VariableSizedInteger

+ (NSObject<ValueTypePluginProtocol> *)initializeClass
{
    return [[[Plugin_VariableSizedInteger alloc] init] autorelease];
}

- (NSString *)name
{
    return @"Integer, Variable Sized Format";
}

- (NSString *)stringRep:(NSData *)data prefs:(NSDictionary *)prefs
{
    NSString *retVal = nil;

    BOOL       hasMoreData = NO;
    NSUInteger accumulator = 0;

    const unsigned char *bytes = (const unsigned char *)[data bytes];

    for (int i = 0; i < [data length]; i++)
    {
        unsigned char byte = bytes[i] & LOW_BYTE_MASK;

        hasMoreData = byte >> BASE_128_SHIFT;
        accumulator ^= (byte & DATA_MASK);

        if (hasMoreData)
        {
            accumulator <<= 7;
        }
        else
        {
            break;
        }
    }

    if (!hasMoreData)
    {
        retVal = [NSString stringWithFormat:@"%tu", accumulator];
    }

    return retVal;
}

- (BOOL)userEditable
{
    return YES;
}

- (NSData *)dataRep:(NSString *)str prefs:(NSDictionary *)prefs
{
    NSData *data = nil;

    if (str && ([str length] > 0))
    {
        NSInteger value;
        NSScanner *scanner = [NSScanner scannerWithString:str];

        if ([scanner scanInteger:&value] && [scanner isAtEnd])
        {
            NSMutableData *tempData = [NSMutableData new];
            unsigned char byte;

            do
            {
                byte = value & DATA_MASK;

                if ([tempData length] > 0)
                {
                    byte ^= HAS_MORE_DATA_BIT_MASK;
                }

                [tempData replaceBytesInRange:NSMakeRange(0, 0) withBytes:&byte length:1];

                value >>= BASE_128_SHIFT;
            }
            while (value > 0);

            data = [NSData dataWithData:tempData];
        }
    }

    return data;
}

@end
