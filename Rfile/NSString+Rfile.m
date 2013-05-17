//
// NSString+Rfile.m
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

#import "NSString+Rfile.h"


static NSString *kDigitNames[10] = { @"Zero", @"One", @"Two", @"Three", @"Four", @"Five", @"Six", @"Seven", @"Eight", @"Nine" };


static void replaceCharacters(NSMutableString *string, NSCharacterSet *set, NSString *replacement) {
    NSRange range = [string rangeOfCharacterFromSet:set];
    while (range.location != NSNotFound) {
        [string replaceCharactersInRange:range withString:replacement];
        range = [string rangeOfCharacterFromSet:set];
    }
}

static void insertBeforeCharacters(NSMutableString *string, NSCharacterSet *set, NSString *insert) {
    NSRange range = [string rangeOfCharacterFromSet:set];
    while (range.location != NSNotFound) {
        [string insertString:insert atIndex:range.location];
        NSUInteger index = range.location + 2;
        range = [string rangeOfCharacterFromSet:set options:0 range:NSMakeRange(index, [string length]-index)];
    }
}

static void ensureFirstCharacter(NSMutableString *string) {
    if (string.length) {
        unichar ch = [string characterAtIndex:0];
        if (ch >= '0' && ch <= '9') {
            // first char is a digit, e.g., "3DButtonTitle" => "ThreeDButtonTitle"
            NSUInteger digit = ch - '0';
            NSString *name = kDigitNames[digit];
            [string replaceCharactersInRange:NSMakeRange(0, 1) withString:name];
        } else if ((ch != '_') && (ch < 'a' || ch > 'z') && (ch < 'A' || ch > 'Z')) {
            // any other non-valid character
            [string insertString:@"A" atIndex:0];
        }
    }
}


@implementation NSString (Rfile)

- (NSString *)stringByConvertingToAscii {
    NSMutableString *mutable = [self mutableCopy];
    CFMutableStringRef cfmutable = (__bridge CFMutableStringRef) mutable;
    
    // converts non-latin characters to a close latin soundalike
    CFStringTransform(cfmutable, NULL, kCFStringTransformToLatin, false);
    
    // removes diacretics and some accents
    CFStringTransform(cfmutable, NULL, kCFStringTransformStripCombiningMarks, false);
    
    // lossy conversion to ascii gets rid of any leftover accents and random unicode entities
    NSData *data = [mutable dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *result = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    
    return result;
}

- (NSString *)stringByConvertingToCIdentifier {
    NSString *asciiString = [self stringByConvertingToAscii];
    
    // prevents the capitalize call from lowercasing existing uppercase letters in the middle of words
    NSMutableString *mutable = [asciiString mutableCopy];
    insertBeforeCharacters(mutable, [NSCharacterSet uppercaseLetterCharacterSet], @" ");
    
    // camel-case identifiers
    CFMutableStringRef cfmutable = (__bridge CFMutableStringRef) mutable;
    CFStringCapitalize(cfmutable, CFLocaleGetSystem());

    // leaves us with only valid identifier characters
    replaceCharacters(mutable, [[NSCharacterSet alphanumericCharacterSet] invertedSet], @"");
    
    // make sure first character is _ or a letter
    ensureFirstCharacter(mutable);
    
    return mutable;
}


- (NSString *)stringByAddingBackslashes {
    NSMutableString *result = [self mutableCopy];
    
    [result replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:0 range:NSMakeRange(0, result.length)];
    [result replaceOccurrencesOfString:@"\n" withString:@"\\n" options:0 range:NSMakeRange(0, result.length)];
    [result replaceOccurrencesOfString:@"\r" withString:@"\\r" options:0 range:NSMakeRange(0, result.length)];
    [result replaceOccurrencesOfString:@"\t" withString:@"\\t" options:0 range:NSMakeRange(0, result.length)];
    [result replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:0 range:NSMakeRange(0, result.length)];
    
    return [result copy];
}

- (NSString *)stringByPaddingToMinimumLength:(NSUInteger)length {
    if (self.length >= length) {
        return self;
    }

    return [self stringByPaddingToLength:length withString:@" " startingAtIndex:0];
}

@end
