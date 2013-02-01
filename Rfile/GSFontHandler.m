//
// GSFontHandler.m
//
// Copyright (c) 2013 Gil Shapira
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

#import "GSFontHandler.h"
#import "GSFontLists.h"
#import "NSString+Rfile.h"


#define kEpsilon 0.00001f


@implementation GSFontHandler

- (NSString *)type {
    return @"font";
}

- (NSDictionary *)commonEntries {
    NSMutableArray *fonts = [NSMutableArray array];

    NSDictionary *fontLists = GSFontLists();
    [fontLists enumerateKeysAndObjectsUsingBlock:^(NSNumber *osVersion, NSArray *fontList, BOOL *stop) {
        if (self.osVersion >= [osVersion floatValue] - kEpsilon) {
            [fonts addObjectsFromArray:fontList];
        }
    }];

    NSMutableDictionary *entries = [NSMutableDictionary new];
    for (NSString *font in fonts) {
        NSString *key = [font stringByConvertingToCIdentifier];
        if (key.length && font.length) {
            entries[key] = font;
        }
    }

    return entries;
}

- (NSDictionary *)entriesForResourceAtPath:(NSString *)path {
    NSString *ext = [[path pathExtension] lowercaseString];
    if ([ext isEqualToString:@"ttf"] || [ext isEqualToString:@"otf"]) {
        NSString *filename = [path lastPathComponent];
        NSString *font = [filename stringByDeletingPathExtension];
        NSString *key = [font stringByConvertingToCIdentifier];
        if (key.length && font.length) {
            return @{key : font};
        }
    }
    return nil;
}

@end
