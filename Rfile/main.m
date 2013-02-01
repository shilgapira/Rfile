//
// main.c
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

#import <Foundation/Foundation.h>
#import "GSImageHandler.h"
#import "GSStringsHandler.h"
#import "GSFontHandler.h"
#import "GSRfileBuilder.h"


int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if (![defaults objectForKey:@"dir"] || ![defaults objectForKey:@"target"]) {
            printf("Usage: Rfile -dir path -target file [-prefix <prefix>] [-fonts <os version>]\n");
            return 0;
        }
        
        GSRfileBuilder *builder = [GSRfileBuilder new];
        [builder addHandler:[GSStringsHandler new]];
        [builder addHandler:[GSImageHandler new]];

        builder.path = [defaults objectForKey:@"dir"];
        builder.target = [defaults objectForKey:@"target"];
        
        if ([defaults stringForKey:@"prefix"]) {
            builder.prefix = [defaults stringForKey:@"prefix"];
        }
        
        if ([defaults floatForKey:@"fonts"] > 0.0f) {
            GSFontHandler *fontHandler = [GSFontHandler new];
            fontHandler.osVersion = [defaults floatForKey:@"fonts"];
            [builder addHandler:fontHandler];
        }

        [builder build];
    }
    return 0;
}
