//
//  CGPathQuery+FileIO.h
//  Thimble
//
//  Created by Vivek Gani on 8/30/16.
//
//

#import <Foundation/Foundation.h>
#import "CGPathQuery.h"

@interface CGPathQuery (FileIO)

- (NSError *) savePointValuesToFile:(NSString *)filePath;
- (NSError *) loadPointValuesFromFile:(NSString *)filePath;

@end
