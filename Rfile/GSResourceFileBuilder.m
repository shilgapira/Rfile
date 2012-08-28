//
// GSResourceFileBuilder.m
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

#import "GSResourceFileBuilder.h"
#import "NSString+Rfile.h"


static NSString *fullResourceKey(NSString *prefix, NSString *type, NSString *key) {
    NSString *result = [NSString stringWithFormat:@"%@ %@",type,key];
    result = [result stringByConvertingToCIdentifier];
    result = [prefix stringByAppendingString:result];
    return result;
}


@implementation GSResourceFileBuilder {
    NSMutableSet *_handlers;
}

@synthesize path = _path, target = _target, prefix = _prefix;

- (id)init {
    if (self = [super init]) {
        _path = [NSFileManager defaultManager].currentDirectoryPath;
        _target = [_path stringByAppendingPathComponent:@"Resources"];
        _prefix = @"r";
        _handlers = [NSMutableSet set];
    }
    return self;
}

- (void)addHandler:(id<GSResourceHandler>)handler {
    [_handlers addObject:handler];
}

- (void)addFile:(NSString *)file toResources:(NSMutableDictionary *)resources {
    for (id<GSResourceHandler> handler in _handlers) {
        NSDictionary *entries = [handler entriesForResourceAtPath:file];
        for (NSString *key in entries) {
            NSString *fullKey = fullResourceKey(self.prefix, handler.type, key);
            while (resources[fullKey]) {
                fullKey = [fullKey stringByAppendingString:@"X"];
            }
            resources[fullKey] = entries[key];
        }
    }
}

- (NSDictionary *)findResources {
    NSMutableDictionary *resources = [NSMutableDictionary dictionary];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *dirEnumerator = [fileManager enumeratorAtPath:self.path];
    for (NSString *subpath in dirEnumerator) {
        NSString *fullpath = [self.path stringByAppendingPathComponent:subpath];
        BOOL directory;
        if ([fileManager fileExistsAtPath:fullpath isDirectory:&directory] && !directory) {
            [self addFile:fullpath toResources:resources];
        }
    }
    
    return resources;
}

- (NSMutableArray *)createFileRepresentation {
    NSMutableArray *lines = [NSMutableArray new];
    
    NSString *time = [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle];
    
    [lines addObject:@"//"];
    [lines addObject:@"// Resource file"];
    [lines addObject:@"//"];
    [lines addObject:[NSString stringWithFormat:@"// Generated at: %@",time]];
    [lines addObject:@"//"];
    [lines addObject:@""];
    
    return lines;
}

- (void)writeFileRepresentation:(NSArray *)representation withExtension:(NSString *)extension {
    NSString *filename = [self.target stringByAppendingPathExtension:extension];
    NSString *output = [representation componentsJoinedByString:@"\n"];
    NSError *error = nil;
    [output writeToFile:filename atomically:NO encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        fprintf(stderr, "Couldn't write file %s: %s\n\r", [filename UTF8String], [[error localizedDescription] UTF8String]);
    }
}

- (void)build {
    NSDictionary *resources = [self findResources];
    
    NSArray *sortedKeys = [[resources allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    NSMutableArray *hLines = [self createFileRepresentation];
    NSMutableArray *mLines = [self createFileRepresentation];
    
    for (NSString *key in sortedKeys) {
        printf("'%s' => '%s'\n\r", [key UTF8String], [resources[key] UTF8String]);
        [hLines addObject:[NSString stringWithFormat:@"extern NSString * const %@;",key]];
        [mLines addObject:[NSString stringWithFormat:@"NSString * const %@ = \"%@\";",key,resources[key]]];
    }
    
    [self writeFileRepresentation:hLines withExtension:@"h"];
    [self writeFileRepresentation:mLines withExtension:@"m"];
}

@end
