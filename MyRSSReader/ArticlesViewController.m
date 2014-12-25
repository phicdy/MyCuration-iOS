//
//  ArticlesViewController.m
//  MyRSSReader
//
//  Created by Keisuke Yamaguchi on 2014/06/03.
//  Copyright (c) 2014年 Keisuke Yamaguchi. All rights reserved.
//

#import "ArticlesViewController.h"
#import "WebViewController.h"
#import "SQLiteHelper.h"

@interface ArticlesViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation ArticlesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _tableView.dataSource = self;
    _tableView.delegate = self;
    
	// Do any additional setup after loading the view.
    SQLiteHelper *sqliteHelper = [SQLiteHelper sharedSQLite];
    self.articles = [sqliteHelper getAllArticles:self.feedId];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Set each cell
    static NSString *identifier = @"ArticleCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    // No need to initialize, because of storyboard
    //    if(cell == nil) {
    //        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    //    }
    
    //    cell. = [items objectAtIndex:indexPath.row];
    UILabel *articleTitle = (UILabel *)[cell viewWithTag:2];
    NSArray *article = [self.articles objectAtIndex:indexPath.row];
    articleTitle.text = [article objectAtIndex:1];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.articles count];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"openArticleUrl"]) {
        WebViewController *webViewController = [segue destinationViewController];
        NSArray *selectedArticle = [self.articles objectAtIndex:[self.tableView indexPathForSelectedRow].row];
        webViewController.url = [NSURL URLWithString:[selectedArticle objectAtIndex:2]];
    }
}

@end
