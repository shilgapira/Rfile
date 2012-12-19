//
// GSRfileGlobalsWriter.m
//
// Copyright (c) 2012 Gil Shapira
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "GSRfileGlobalsWriter.h"
#import "NSString+Rfile.h"


#define $(...)  [NSString stringWithFormat:__VA_ARGS__]


#define kKeyPadding  50


@implementation GSRfileGlobalsWriter {
    NSMutableDictionary *_resources;
}

- (id)init {
    if (self = [super init]) {
        _resources = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSString *)fullResourceKey:(NSString *)key type:(NSString *)type {
    NSString *result = $(@"%@ %@",type,key);
    result = [result stringByConvertingToCIdentifier];
    result = [self.prefix stringByAppendingString:result];
    return result;
}

- (void)addResource:(NSString *)resource key:(NSString *)key type:(NSString *)type {
    NSString *fullKey = [self fullResourceKey:key type:type];
    while (_resources[fullKey]) {
        fullKey = [fullKey stringByAppendingString:@"X"];
    }
    _resources[fullKey] = resource;
}

- (void)writeToTarget:(NSString *)target {
    NSArray *sortedKeys = [[_resources allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

    NSMutableArray *hLines = [self createFileLines];
    NSMutableArray *mLines = [self createFileLines];

    for (NSString *key in sortedKeys) {
        printf("'%s' => '%s'\n", [key UTF8String], [_resources[key] UTF8String]);
        if (self.defines) {
            [hLines addObject:$(@"#define %@ @\"%@\"",[key stringByPaddingToMinimumLength:kKeyPadding],_resources[key])];
        } else {
            [hLines addObject:$(@"extern NSString * const %@;",key)];
            [mLines addObject:$(@"NSString * const %@ = @\"%@\";",[key stringByPaddingToMinimumLength:kKeyPadding],_resources[key])];
        }
    }

    [hLines addObject:@""];
    [mLines addObject:@""];

    [self writeFileLines:hLines toFileAtPath:[target stringByAppendingPathExtension:@"h"]];
    if (!self.defines) {
        [self writeFileLines:mLines toFileAtPath:[target stringByAppendingPathExtension:@"m"]];
    }
}

@end
