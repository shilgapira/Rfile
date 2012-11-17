//
// GSResourceHandler.m
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

#import "GSResourceHandler.h"
#import "NSString+Rfile.h"


@implementation GSStringsResourceHandler

- (NSString *)type {
    return @"str";
}

- (NSDictionary *)entriesForResourceAtPath:(NSString *)path {
    NSString *ext = [[path pathExtension] lowercaseString];
    if (![ext isEqualToString:@"strings"]) {
        return nil;
    }
    
    NSError *error;
    NSStringEncoding encoding;
    NSString *stringsFile = [NSString stringWithContentsOfFile:path usedEncoding:&encoding error:&error];
    if (error) {
        NSLog(@"Error opening strings file '%@': %@", path, error);
    }
    
    NSDictionary *strings = [stringsFile propertyListFromStringsFileFormat];
    
    NSMutableDictionary *entries = [NSMutableDictionary dictionary];
    for (NSString *key in strings) {
        if ([key length]) {
            entries[key] = [key stringByAddingBackslashes];
        }
    }
    
    return entries;
}

@end


@implementation GSImageResourceHandler

- (NSString *)type {
    return @"img";
}

- (NSDictionary *)entriesForResourceAtPath:(NSString *)path {
    NSString *ext = [[path pathExtension] lowercaseString];
    if ([ext isEqualToString:@"png"] || [ext isEqualToString:@"jpg"]) {
        NSString *filename = [[path lastPathComponent] stringByDeletingPathExtension];
        if ([filename length]) {
            return @{filename : filename};
        }
    }
    
    return nil;
}

@end


@implementation GSSoundResourceHandler

- (NSString *)type {
    return @"aud";
}

- (NSDictionary *)entriesForResourceAtPath:(NSString *)path {
    NSString *ext = [[path pathExtension] lowercaseString];
    if ([ext isEqualToString:@"ogg"] || [ext isEqualToString:@"mp3"] || [ext isEqualToString:@"wav"]) {
        NSString *filename = [[path lastPathComponent] stringByDeletingPathExtension];
        if ([filename length]) {
            return @{filename : filename};
        }
    }
    
    return nil;
}

@end
