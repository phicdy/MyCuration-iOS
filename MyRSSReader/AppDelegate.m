//
//  AppDelegate.m
//  MyRSSReader
//
//  Created by Keisuke Yamaguchi on 2014/05/16.
//  Copyright (c) 2014年 Keisuke Yamaguchi. All rights reserved.
//

#import "AppDelegate.h"
#import "SQLiteHelper.h"
#import "RssParser.h"

@interface AppDelegate ()

@property NSString* parseURLString;

@end

SQLiteHelper *sqliteHelper;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    sqliteHelper = [SQLiteHelper sharedSQLite];
    NSMutableArray *feeds = [sqliteHelper getAllFeeds];
    for (NSArray *feed in feeds) {
        NSString *urlString = [feed objectAtIndex:2];
        self.parseURLString = urlString;
        NSURL *url = [NSURL URLWithString:urlString];
        
        NSURLRequest* request = [NSURLRequest requestWithURL:url];
        NSOperationQueue *queue = [NSOperationQueue new];
        NSLog(@"before");
        [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *res, NSData *data, NSError *error) {
            NSLog(@"done");
            
            // Error Handling
            
            NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            //        RssParser* parser = [[RssParser alloc]init];
            
            if ([responseString length] > 0) {
                //                NSLog(@"%@",responseString);
                RssParser *parser = [[RssParser alloc]init];
                parser.addedFeedParseDelegate = self;
                parser.feedUrl = urlString;
                [parser parseRSSXML:data];
            }else {
                NSLog(@"responce is null");
            }
            
            
            //            NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
            //            [mainQueue addOperationWithBlock:^{
            // ここにUIの処理を記述
            //                [self.tableView reloadData];
            //            }];
        }];
    }
    
    UILocalNotification *notification = [[UILocalNotification alloc]init];
    
    notification.fireDate = [NSDate date];    // すぐに通知
    notification.timeZone = [NSTimeZone defaultTimeZone];
    notification.alertBody = @"更新！";
    notification.alertAction = @"Open";       // 通知メッセージタップ時の動作
    notification.soundName = UILocalNotificationDefaultSoundName;
    
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    
    completionHandler(UIBackgroundFetchResultNewData);
    
}

- (void)onDidFinishParsing:(NSMutableArray*)articles
{
    int feedId = [sqliteHelper getFeedId:self.parseURLString];
    for (NSMutableArray *article in articles) {
        //        continue;
        [sqliteHelper addArticle:[article objectAtIndex:0] url:[article objectAtIndex:1] status:@"unread" date:[article objectAtIndex:2] feedId:feedId];
    }
}

@end
