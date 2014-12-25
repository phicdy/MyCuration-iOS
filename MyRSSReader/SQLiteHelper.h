//
//  SQLiteHelper.h
//  MyRSSReader
//
//  Created by Keisuke Yamaguchi on 2014/05/23.
//  Copyright (c) 2014年 Keisuke Yamaguchi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SQLiteHelper : NSObject

+ (SQLiteHelper*)sharedSQLite;
+ (NSString*)path;
- (id)addFeed:(NSString*)title url:(NSString*)url;
- (id)addArticle:(NSString*)title url:(NSString*)url status:(NSString*)status date:(NSDate*)date feedId:(int)feedId;
- (NSMutableArray*)getAllFeeds;
- (int)getFeedId:(NSString*)urlString;
- (NSMutableArray*)getAllArticles:(int)feedId;
- (BOOL)isExistArticle:(NSString*)urlString;
- (BOOL)isExistFeed:(NSString*)urlString;
@end
