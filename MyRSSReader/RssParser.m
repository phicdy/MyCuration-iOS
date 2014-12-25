//
//  RssParser.m
//  MyRSSReader
//
//  Created by Keisuke Yamaguchi on 2014/05/20.
//  Copyright (c) 2014年 Keisuke Yamaguchi. All rights reserved.
//

#import "RssParser.h"
#import "SQLiteHelper.h"

@implementation RssParser

NSString *feedTitle = @"";
NSString *articleTitle = @"";
NSString *articleUrl = @"";
NSDate *articleDate;
NSMutableArray* articles;
bool inFeedTitle = NO;
bool inArticleTitle = NO;
bool inItem = NO;
bool inLink = NO;
bool inDate = NO;

SQLiteHelper *sqliteHelper;

- (void)parseRSSXML:(NSData*)xmlData
{
    sqliteHelper = [SQLiteHelper sharedSQLite];
    
    articles = [[NSMutableArray alloc]init];
    NSXMLParser* parser = [[NSXMLParser alloc]initWithData:xmlData];
    [parser setDelegate:self];
    [parser setShouldProcessNamespaces:YES];
    [parser parse];
    NSLog(@"parseRSSXML end");
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict {
//    NSLog(@"elementName :%@", elementName);
//    NSLog(@"namespaceURI :%@", namespaceURI);
//    NSLog(@"qualifiedName :%@", qualifiedName);
    NSLog(@"Element : %@", elementName);
	if ([elementName isEqualToString:@"title"]) {
        if (inItem) {
            NSLog(@"inArticleTitle -> YES");
            inArticleTitle = YES;
        }else {
            NSLog(@"inFeedTitle -> YES");
            inFeedTitle = YES;
        }
	} else if ([elementName isEqualToString:@"item"]) {
        NSLog(@"inItem -> YES");
        inItem = YES;
	}else if ([elementName isEqualToString:@"link"] && inItem) {
        NSLog(@"inLink -> YES");
        inLink = YES;
	}else if ([elementName isEqualToString:@"pubDate"] && inItem) {
        NSLog(@"inDate -> YES");
        inDate = YES;
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if ([elementName isEqualToString:@"title"]) {
        if (inItem) {
            NSLog(@"inArticleTitle -> NO");
            inArticleTitle = NO;
        }else {
            NSLog(@"inFeedTitle -> NO");
            inFeedTitle = NO;
            if ([sqliteHelper isExistFeed:self.feedUrl] == NO) {
                [self.addedFeedParseDelegate onDidSetTitle:feedTitle];
            }
        }
	} else if ([elementName isEqualToString:@"item"]) {
        NSLog(@"inItem -> NO");
        inItem = NO;
        NSArray *newArticle = [[NSArray alloc]initWithObjects:articleTitle, articleUrl, articleDate, nil];
        [articles addObject:newArticle];
        articleTitle = @"";
        articleUrl = @"";
        articleDate = nil;
        NSLog(@"%@", articles);
	}else if ([elementName isEqualToString:@"link"] && inItem) {
        NSLog(@"inLink -> NO");
        inLink = NO;
	}else if ([elementName isEqualToString:@"pubDate"] && inItem) {
        NSLog(@"inDate -> NO");
        inDate = NO;
	}
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    NSLog(@"foundCharacters : %@", string);
//    NSLog(@"inItem : %@, inLink : %@, inTitle : %@, inDate : %@", inItem, inLink, inTitle, inDate);
    // Item title
    if (inItem) {
        if (inArticleTitle) {
            articleTitle = [articleTitle stringByAppendingString:string];
        }else if(inLink) {
            articleUrl = string;
            
            // If exist same article, save new articles and abort parsing
            if ([sqliteHelper isExistArticle:articleUrl]) {
                [self.addedFeedParseDelegate onDidFinishParsing:articles];
                [parser abortParsing];
            }
        }else if(inDate) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
            [formatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss ZZZZ"];
            articleDate = [formatter dateFromString:string];
            NSLog(@"articleDate: %@", articleDate);
//            double pubDateUnixtime = [pubDate timeIntervalSince1970];
//            NSLog(@"unixtime: %@", [NSNumber numberWithDouble:pubDateUnixtime]);
//            [article addObject:[NSNumber numberWithDouble:pubDateUnixtime]];
        }
    }else {
        // Feed title
        if (inFeedTitle) {
            feedTitle = [feedTitle stringByAppendingString:string];
            NSLog(@"set feed title:%@", feedTitle);
            
        }
    }
    
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
	NSLog(@"Finish parsing");
    [self.addedFeedParseDelegate onDidFinishParsing:articles];
}
@end
