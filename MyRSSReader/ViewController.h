//
//  ViewController.h
//  MyRSSReader
//
//  Created by Keisuke Yamaguchi on 2014/05/16.
//  Copyright (c) 2014年 Keisuke Yamaguchi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ArticlesViewController.h"

@protocol AddedFeedParseDelegate <NSObject>

@required
- (void)onDidSetTitle:(NSString*)title;
- (void)onDidFinishParsing:(NSMutableArray*)articles;

@end

@interface ViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, AddedFeedParseDelegate>
{
    NSMutableArray *feeds;
    UIRefreshControl *refreshControl;
    
}

@end
