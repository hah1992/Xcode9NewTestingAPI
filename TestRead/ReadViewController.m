//
//  ReadViewController.m
//  TestRead
//
//  Created by 黄安华 on 2017/9/5.
//  Copyright © 2017年 sohu. All rights reserved.
//

#import "ReadViewController.h"

@interface ReadViewController ()
@property (weak, nonatomic) IBOutlet UILabel *contentLabel;

@end

@implementation ReadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib,
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(becomeForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self loadContent];
}

- (void)becomeForeground:(id)sender {
    [self loadContent];
}

- (void)loadContent {
    NSDictionary *contentDict = [NSDictionary dictionaryWithContentsOfFile:@"/Users/huanganhua/Desktop/TestNewAPI.plist"];
    NSString *text = contentDict[@"content"];
    if (text) {
        self.contentLabel.text = text;
    }
}


@end
