//
// GSRfileWriter.m
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

#import "GSRfileWriter.h"
#import "GRMustache.h"
#import "GSRfileTemplate.h"
#import "NSString+Rfile.h"


@interface GSRfileWriter ()

@property (nonatomic,strong) NSMutableDictionary *types;

@end


@implementation GSRfileWriter

- (id)init {
    if (self = [super init]) {
        self.types = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)addResource:(NSString *)resource key:(NSString *)key type:(NSString *)type {
    NSMutableDictionary *resources = self.types[type];
    if (!resources) {
        self.types[type] = resources = [NSMutableDictionary dictionary];
    }
    resources[key] = resource;
}

- (NSDictionary *)templateData {
    NSMutableArray *types = [NSMutableArray array];

    [self.types.allKeys enumerateObjectsUsingBlock:^(NSString *type, NSUInteger idx, BOOL *stop) {
        NSMutableArray *resources = [NSMutableArray array];

        [self.types[type] enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *resource, BOOL *stop) {
            NSString *helper = [key stringByConvertingToCIdentifier];
            
            NSString *identifier = [[NSString stringWithFormat:@"%@ %@",type,helper] stringByConvertingToCIdentifier];
            printf("    [%s]  =>  %s\n", [identifier UTF8String], [resource UTF8String]);
            
            NSString *define = [identifier stringByPaddingToMinimumLength:50];
            [resources addObject:@{ @"define" : define, @"helper" : helper, @"resource" : resource }];
        }];

        NSArray *sortedResources = [resources sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *r1, NSDictionary *r2) {
            return [r1[@"define"] compare:r2[@"define"]];
        }];

        type = [type stringByConvertingToCIdentifier];

        [types addObject:@{ @"type" : type, @"resources" : sortedResources }];
    }];

    NSArray *sortedTypes = [types sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *t1, NSDictionary *t2) {
        return [t1[@"type"] compare:t2[@"type"]];
    }];

    NSUInteger fonts = [self.types[@"font"] count];

    NSDictionary *data = @{ @"cmdline" : self.cmdLine, @"p" : self.prefix, @"fonts" : @(fonts), @"types" : sortedTypes };

    return data;
}

- (void)writeOutput:(NSString *)output toFileAtPath:(NSString *)path {
    printf("Writing file: %s\n",[path UTF8String]);

    __autoreleasing NSError *error = nil;
    BOOL success = [output writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:&error];
    if (!success) {
        fprintf(stderr, "Couldn't write file %s: %s\n", [path UTF8String], [error.description UTF8String]);
    }
}

- (void)writeToTarget:(NSString *)target {
    NSDictionary *data = [self templateData];

    __autoreleasing NSError *error = nil;
    NSString *output = [GRMustacheTemplate renderObject:data fromString:GSRfileTemplate error:&error];
    if (!output) {
        fprintf(stderr, "Couldn't generate template: %s\n", [error.description UTF8String]);
    }

    [self writeOutput:output toFileAtPath:[target stringByAppendingPathExtension:@"h"]];
}

@end
