//
//  RssParser.h
//  MyRSSReader
//
//  Created by Keisuke Yamaguchi on 2014/05/20.
//  Copyright (c) 2014年 Keisuke Yamaguchi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ViewController.h"

@interface RssParser : NSObject <UIApplicationDelegate, NSXMLParserDelegate>

@property id<AddedFeedParseDelegate> addedFeedParseDelegate;
@property NSString *feedUrl;

- (void)parseRSSXML:(NSData*)xmlData;

@end
