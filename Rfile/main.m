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
#import "GSResourceHandler.h"
#import "GSResourceFileBuilder.h"


int main(int argc, const char * argv[])
{
    for (int i = 0; i < argc; i++) {
        if (strncasecmp(argv[i], "--help", 6) == 0) {
            printf("Usage: Rfile [-dir <path>] [-target <file>] [-prefix <prefix>]\n\r");
            return 0;
        }
    }
    
    @autoreleasepool {
        GSResourceFileBuilder *builder = [GSResourceFileBuilder new];
        [builder addHandler:[GSStringsResourceHandler new]];
        [builder addHandler:[GSImageResourceHandler new]];
        [builder addHandler:[GSSoundResourceHandler new]];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if ([defaults objectForKey:@"dir"]) {
            builder.path = [defaults objectForKey:@"dir"];
        }
        if ([defaults objectForKey:@"target"]) {
            builder.target = [defaults objectForKey:@"target"];
        }
        if ([defaults objectForKey:@"prefix"]) {
            builder.prefix = [defaults objectForKey:@"prefix"];
        }
        
        [builder build];
    }
    return 0;
}
