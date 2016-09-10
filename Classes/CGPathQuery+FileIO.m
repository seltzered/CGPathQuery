//
//  CGPathQuery+FileIO.m
//  Thimble
//
//  Created by Vivek Gani on 8/30/16.
//
//

#import "CGPathQuery+FileIO.h"
#import "CGPathQuery+Protected.h"
#import "CGPathQueryData.h"

@implementation CGPathQuery (FileIO)

- (NSError *) savePointValuesToFile:(NSString *)filePath
{
    NSError * error;
    
    //split queryData into two separate nsnumber arrays
    NSMutableArray * queryDataX, *queryDataY;
    queryDataX = [[NSMutableArray alloc] initWithCapacity:[self.cgPathQueryData.queryData count]];
    queryDataY = [[NSMutableArray alloc] initWithCapacity:[self.cgPathQueryData.queryData count]];
    [self.cgPathQueryData.queryData enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [queryDataX addObject:[NSNumber numberWithDouble: [obj pointValue].x]];
        [queryDataY addObject:[NSNumber numberWithDouble: [obj pointValue].y]];
    }];
    
    NSDictionary * dict = [NSDictionary
                           dictionaryWithObjectsAndKeys:
                           queryDataX, @"queryDataX",
                           queryDataY, @"queryDataY",
                           [NSNumber numberWithDouble:self.cgPathQueryData.delta], @"delta",
                           [NSNumber numberWithDouble:self.cgPathQueryData.zeroToOneCompletionEnd], @"zeroToOneCompletionEnd",
                           [NSNumber numberWithDouble:self.cgPathQueryData.zeroToOneCompletionStart], @"zeroToOneCompletionStart",nil];
    
    NSData *plistData = [NSPropertyListSerialization dataFromPropertyList:dict
                                                                   format:NSPropertyListXMLFormat_v1_0
                                                         errorDescription:&error];
    
    if(plistData) {
        [plistData writeToFile:filePath atomically:YES];
    }
    else {
        DDLogError(@"[%@] %@", [self class], [error description] );
    }
    
    return error;
}

- (NSError *) loadPointValuesFromFile:(NSString *)filePath
{
    CGPathQueryData *loadedQueryData;
    NSError * error;
    NSString * errorDomain = [[NSString alloc] initWithFormat:@"%@", [self class]];

    //load plist
    NSDictionary * pathQueryPlist = [self pathQueryPlistForPath:filePath];
    if(!pathQueryPlist)
    {
        error = [[NSError alloc] initWithDomain:errorDomain code:-1 userInfo:nil];
        return error;
    }
    
    //load values
    loadedQueryData = [[CGPathQueryData alloc] init];
    
    NSArray * queryDataX = [pathQueryPlist objectForKey:@"queryDataX"];
    NSArray * queryDataY = [pathQueryPlist objectForKey:@"queryDataY"];
    NSMutableArray * queryData = [[NSMutableArray alloc] initWithCapacity:[queryDataX count]];
    [queryDataX enumerateObjectsUsingBlock:^(NSNumber * dataXNum, NSUInteger idx, BOOL * _Nonnull stop) {
        NSNumber * dataYNum = [queryDataY objectAtIndex:idx];
        [queryData setObject:[NSValue valueWithPoint:NSMakePoint([dataXNum doubleValue], [dataYNum doubleValue])] atIndexedSubscript:idx];
    }];
    loadedQueryData.queryData = queryData;
    
    loadedQueryData.zeroToOneCompletionStart = [(NSNumber *)[pathQueryPlist objectForKey:@"zeroToOneCompletionStart"] doubleValue];
    loadedQueryData.zeroToOneCompletionEnd = [(NSNumber *) [pathQueryPlist objectForKey:@"zeroToOneCompletionEnd"] doubleValue];
    loadedQueryData.delta = [(NSNumber *) [pathQueryPlist objectForKey:@"delta"] doubleValue];
    
    [self loadCachedPointValues:loadedQueryData];
    return nil;
}


- (NSDictionary *) pathQueryPlistForPath:(NSString *) path
{
    NSPropertyListFormat format;
    NSError * error;
    
    if(path == nil)
    {
        NSLog(@"[%@] Error - toolPrefsPListPath is nil", [self class]);
        return nil;
    }
    
    NSData * plistXML = [[NSFileManager defaultManager] contentsAtPath:path];
    
    NSDictionary * plist = [NSPropertyListSerialization propertyListWithData:plistXML
                                                         options:NSPropertyListMutableContainersAndLeaves
                                                          format:&format
                                                           error:&error];
    
    if (!plist) {
        DDLogError(@"[%@] Error reading plist: %@", [self class], error.localizedDescription);
        return nil;
    }
    
    return plist;
}

@end
