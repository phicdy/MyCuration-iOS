//
//  ArticlesViewController.h
//  MyRSSReader
//
//  Created by Keisuke Yamaguchi on 2014/06/03.
//  Copyright (c) 2014年 Keisuke Yamaguchi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ArticlesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property NSMutableArray *articles;
@property int feedId;

@end
