//
// GSRfileStructWriter.m
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

#import "GSRfileStructWriter.h"
#import "NSString+Rfile.h"


#define $(...)  [NSString stringWithFormat:__VA_ARGS__]


#define kDefinePadding  50
#define kMacroPadding   30


@implementation GSRfileStructWriter {
    NSMutableDictionary *_types;
}

- (id)init {
    if (self = [super init]) {
        _types = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)addResource:(NSString *)resource key:(NSString *)key type:(NSString *)type {
    NSMutableDictionary *resources = _types[type];
    if (!resources) {
        _types[type] = resources = [NSMutableDictionary dictionary];
    }

    while (resources[key]) {
        key = [key stringByAppendingString:@"X"];
    }
    resources[key] = resource;
}

- (void)appendDefinesForType:(NSString *)type toLines:(NSMutableArray *)lines {
    NSString *name = [type stringByConvertingToCIdentifier];
    NSDictionary *resources = _types[type];

    [resources enumerateKeysAndObjectsUsingBlock:^(NSString *resourceKey, NSString *resourceValue, BOOL *stop) {
        NSString *resourceName = [resourceKey stringByConvertingToCIdentifier];
        NSString *defineName = $(@"_%@Res%@%@",self.prefix,name,resourceName);

        printf("    '%s' => '%s'\n", [resourceName UTF8String], [resourceValue UTF8String]);

        [lines addObject:$(@"#define %@ @\"%@\"",[defineName stringByPaddingToMinimumLength:kDefinePadding],resourceValue)];
    }];
}

- (void)appendStructForType:(NSString *)type toLines:(NSMutableArray *)lines {
    NSString *name = [type stringByConvertingToCIdentifier];
    NSDictionary *resources = _types[type];
    NSString *structName = $(@"_%@%@Resources",self.prefix,name);

    [lines addObject:$(@"typedef struct %@ {",structName)];

    [resources enumerateKeysAndObjectsUsingBlock:^(NSString *resourceKey, NSString *resourceValue, BOOL *stop) {
        NSString *resourceName = [resourceKey stringByConvertingToCIdentifier];
        [lines addObject:$(@"    void *%@;",resourceName)];
    }];

    [lines addObject:$(@"} %@;",structName)];
}

- (void)appendResourcesStructWithTypes:(NSArray *)types toLines:(NSMutableArray *)lines {
    [lines addObject:$(@"typedef struct _%@Resources {",self.prefix)];

    for (NSString *type in types) {
        NSString *name = [type stringByConvertingToCIdentifier];
        [lines addObject:$(@"    _%@%@Resources %@;",self.prefix,name,name)];
    }

    [lines addObject:$(@"} _%@Resources;",self.prefix)];
}

- (void)appendMacrosWithTypes:(NSArray *)types toLines:(NSMutableArray *)lines {
    if (_types[@"str"]) {
        NSString *defineFunc = $(@"%@String(NAME)",self.prefix);
        [lines addObject:$(@"#define %@ NSLocalizedString(%@StrResource(NAME), nil)",[defineFunc stringByPaddingToMinimumLength:kMacroPadding],self.prefix)];
    }

    if (_types[@"img"]) {
        NSString *defineFunc = $(@"%@Image(NAME)",self.prefix);
        [lines addObject:$(@"#define %@ [UIImage imageNamed:%@ImgResource(NAME)]",[defineFunc stringByPaddingToMinimumLength:kMacroPadding],self.prefix)];
    }

    [lines addObject:@""];

    for (NSString *type in _types) {
        NSString *name = [type stringByConvertingToCIdentifier];
        NSString *defineFunc = $(@"%@%@Resource(NAME)",self.prefix,name);
        [lines addObject:$(@"#define %@ %@Resource(%@, NAME)",[defineFunc stringByPaddingToMinimumLength:kMacroPadding],self.prefix,name)];
    }
    
    [lines addObject:@""];

    [lines addObject:$(@"#define %@Resource(TYPE, NAME)         \\",self.prefix)];
    [lines addObject:$(@"    (((void)(NO && ((void)((_%@Resources *) NULL)->TYPE.NAME, NO)), \\",self.prefix)];
    [lines addObject:$(@"    _%@Res##TYPE##NAME))",self.prefix)];
}

- (void)writeToTarget:(NSString *)target {
    NSMutableArray *lines = [self createFileLines];

    NSArray *types = [[_types allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

    [lines addObject:@""];
    [lines addObject:@"/////////////////////"];
    [lines addObject:@"#pragma mark - Macros"];
    [lines addObject:@"/////////////////////"];
    [lines addObject:@""];

    [self appendMacrosWithTypes:types toLines:lines];

    [lines addObject:@""];
    [lines addObject:@""];
    [lines addObject:@"////////////////////////"];
    [lines addObject:@"#pragma mark - Resources"];
    [lines addObject:@"////////////////////////"];
    [lines addObject:@""];

    for (NSString *type in types) {
        printf("'%s':\n", [type UTF8String]);
        [self appendDefinesForType:type toLines:lines];
        [lines addObject:@""];
    }

    [lines addObject:@""];
    [lines addObject:@"//////////////////////////////"];
    [lines addObject:@"#pragma mark - Code-completion"];
    [lines addObject:@"//////////////////////////////"];
    [lines addObject:@""];

    for (NSString *type in types) {
        [self appendStructForType:type toLines:lines];
        [lines addObject:@""];
    }

    [self appendResourcesStructWithTypes:types toLines:lines];
    [lines addObject:@""];

    [self writeFileLines:lines toFileAtPath:[target stringByAppendingPathExtension:@"h"]];
}

@end
