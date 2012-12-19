//
// GSRfileBuilder.m
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

#import "GSRfileBuilder.h"
#import "GSRfileStructWriter.h"
#import "GSRfileGlobalsWriter.h"


@interface GSRfileBuilder ()

@property (nonatomic,strong) NSMutableSet *handlers;

@property (nonatomic,strong) GSRfileWriter *writer;

@end


@implementation GSRfileBuilder

- (id)init {
    if (self = [super init]) {
        self.handlers = [NSMutableSet set];
        self.prefix = @"";
        self.format = GSRfileFormatStruct;
    }
    return self;
}

- (void)setTarget:(NSString *)target {
    if ([target.pathExtension isEqualToString:@".h"] || [target.pathExtension isEqualToString:@".m"]) {
        _target = [target stringByDeletingPathExtension];
    } else {
        _target = [target copy];
    }
}

- (void)setPrefix:(NSString *)prefix {
    _prefix = prefix;
    _writer.prefix = prefix;
}

- (void)setFormat:(GSRfileFormat)format {
    _format = format;
    switch (_format) {
        case GSRfileFormatStruct: {
            _writer = [GSRfileStructWriter new];
            break;
        }

        case GSRfileFormatDefine:
        case GSRfileFormatExtern: {
            GSRfileGlobalsWriter *writer = [GSRfileGlobalsWriter new];
            writer.defines = (_format == GSRfileFormatDefine);
            _writer = writer;
            break;
        }
    }
    _writer.prefix = _prefix;
}

- (void)addHandler:(id<GSResourceHandler>)handler {
    [self.handlers addObject:handler];
}

- (NSString *)cmdLine {
    NSMutableString *line = [@"Rfile" mutableCopy];

    NSString *prefix = nil;
    if (![self.path isEqualToString:self.target]) {
        prefix = [self.path commonPrefixWithString:self.target options:0];
        prefix = [prefix stringByDeletingLastPathComponent];
    }
    prefix = prefix ?: @"";

    NSArray *args = NSProcessInfo.processInfo.arguments;
    for (int i = 1; i < args.count; i++) {
        NSString *arg = args[i];
        if ([arg hasPrefix:prefix]) {
            arg = [@"..." stringByAppendingString:[arg substringFromIndex:prefix.length]];
        }
        [line appendString:@" "];
        [line appendString:arg];
    }

    return line;
}

- (void)build {
    printf("Scanning for resources in: %s\n", [self.path UTF8String]);
    [self collectResources];
    self.writer.cmdLine = [self cmdLine];
    [self.writer writeToTarget:self.target];
}

- (void)collectResources {
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSDirectoryEnumerator *dirEnumerator = [fileManager enumeratorAtPath:self.path];
    for (NSString *subpath in dirEnumerator) {
        NSString *fullpath = [self.path stringByAppendingPathComponent:subpath];
        BOOL directory;
        if ([fileManager fileExistsAtPath:fullpath isDirectory:&directory] && !directory) {
            [self addResourcesFromFile:fullpath];
        }
    }
}

- (void)addResourcesFromFile:(NSString *)file {
    for (id<GSResourceHandler> handler in self.handlers) {
        NSDictionary *entries = [handler entriesForResourceAtPath:file];
        [entries enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
            [self.writer addResource:value key:key type:handler.type];
        }];
    }
}

@end
