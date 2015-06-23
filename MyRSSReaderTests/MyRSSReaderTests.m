//
//  MyRSSReaderTests.m
//  MyRSSReaderTests
//
//  Created by phicdy on 2015/06/23.
//  Copyright (c) 2015年 phicdy All rights reserved.
//

#import <UIKit/UIKit.h>
#import <KIF/KIF.h>

@interface MyRSSReaderTests : KIFTestCase

@end

@implementation MyRSSReaderTests

- (void)beforeEach
{
}

- (void)afterEach
{
}

- (void)testSample
{
    [tester tapViewWithAccessibilityLabel:@"Add"];
    [tester enterTextIntoCurrentFirstResponder:@"http://rss.dailynews.yahoo.co.jp/fc/rss.xml"];
    [tester tapViewWithAccessibilityLabel:@"OK"];
    [tester waitForTimeInterval:10];
}
@end
