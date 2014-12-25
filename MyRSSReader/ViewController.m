//
//  ViewController.m
//  MyRSSReader
//
//  Created by Keisuke Yamaguchi on 2014/05/16.
//  Copyright (c) 2014年 Keisuke Yamaguchi. All rights reserved.
//

#import "ViewController.h"
#import <CoreData/CoreData.h>
#import "SQLiteHelper.h"
#import "RssParser.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property NSString* parseURLString;

@end

@implementation ViewController

SQLiteHelper* sqliteHelper;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.title = @"table view";
    
    _tableView.dataSource = self;
    _tableView.delegate = self;

    sqliteHelper = [SQLiteHelper sharedSQLite];
    feeds = [sqliteHelper getAllFeeds];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    refreshControl = [[UIRefreshControl alloc] init];
    
    [refreshControl addTarget:self action:@selector(refreshFeeds) forControlEvents:UIControlEventValueChanged];
    [_tableView addSubview:refreshControl];

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
//    [self.tableView setEditing:YES animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Set each cell
    static NSString *identifier = @"FeedCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    // No need to initialize, because of storyboard
//    if(cell == nil) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
//    }
    
//    cell. = [items objectAtIndex:indexPath.row];
    UILabel *feedTitle = (UILabel *)[cell viewWithTag:1];
    
    NSArray* feed = [feeds objectAtIndex:indexPath.row];
    feedTitle.text = [feed objectAtIndex:1];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [feeds count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // After clicked
//    NSString *message = [items objectAtIndex:indexPath.row];
//    UIAlertView* alert = [[UIAlertView alloc] init];
//    alert.message = message;
//    [alert addButtonWithTitle:@"OK"];
//    [alert show];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:YES];
    [self.tableView setEditing:editing animated:YES];
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    NSInteger fromRow = sourceIndexPath.row;
    NSInteger toRow = destinationIndexPath.row;
    while (fromRow < toRow) {
        [feeds exchangeObjectAtIndex:fromRow withObjectAtIndex:fromRow+1];
        fromRow++;
    }
    while (fromRow > toRow) {
        [feeds exchangeObjectAtIndex:fromRow withObjectAtIndex:fromRow-1];
        fromRow--;
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Not allow to move to last cell("Add")
//    return (feeds.count > indexPath.row + 1);
    return NO;
}

- (NSIndexPath*) tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    // Not allow to move to last cell("Add")
    if (feeds.count > proposedDestinationIndexPath.row + 1) {
        return proposedDestinationIndexPath;
    }else {
        return sourceIndexPath;
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Set last cell to insert
    if (tableView.editing) {
        return UITableViewCellEditingStyleDelete;
    }else {
        return UITableViewCellEditingStyleDelete;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [feeds removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

- (IBAction)tapAddButton:(id)sender {
//    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Add new feed" message:@"Input feed URL" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
//    alert.delegate = self;
//    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
//    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if( buttonIndex == alertView.cancelButtonIndex ) { return; }
    
    NSString* textValue = [[alertView textFieldAtIndex:0] text];
    if( [textValue length] > 0 )
    {
//        [sqliteHelper addFeed:textValue url:textValue];
        feeds = [sqliteHelper getAllFeeds];
        //
        
        self.parseURLString = textValue;
        [self startParsingXmlOfUrl:self.parseURLString];
        NSLog(@"after");

    }
}

- (void)startParsingXmlOfUrl:(NSString*)urlString
{
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

- (IBAction)selectAddButton:(id)sender {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Add new feed" message:@"Input feed URL" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    alert.delegate = self;
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];

}

- (void)onDidSetTitle:(NSString*)title
{
    NSLog(@"onDidSetTitle");
    NSLog(@"title: %@", title);
    [sqliteHelper addFeed:title url:self.parseURLString];
    feeds = [sqliteHelper getAllFeeds];
    [self.tableView reloadData];
}

- (void)onDidFinishParsing:(NSMutableArray*)articles
{
    int feedId = [sqliteHelper getFeedId:self.parseURLString];
    for (NSMutableArray *article in articles) {
//        continue;
        [sqliteHelper addArticle:[article objectAtIndex:0] url:[article objectAtIndex:1] status:@"unread" date:[article objectAtIndex:2] feedId:feedId];
    }
    [refreshControl endRefreshing];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"goArticlesViewSegue"]) {
        ArticlesViewController *articlesViewController = [segue destinationViewController];
        NSArray *selectedFeed = [feeds objectAtIndex:[self.tableView indexPathForSelectedRow].row];
        articlesViewController.feedId = [[selectedFeed objectAtIndex:0]intValue];
    }
}

- (void)refreshFeeds
{
    for (NSArray *feed in feeds) {
        [self startParsingXmlOfUrl:[feed objectAtIndex:2]];
    }
}

- (NSString *)tableView:(UITableView *)tableView
titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"削除";
}

@end
