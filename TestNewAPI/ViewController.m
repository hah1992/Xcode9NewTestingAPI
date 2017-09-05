//
//  ViewController.m
//  TestNewAPI
//
//  Created by 黄安华 on 2017/9/4.
//  Copyright © 2017年 sohu. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *textField;

@property (weak, nonatomic) IBOutlet UIButton *send;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.textField.delegate = self;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)didClickedSend:(id)sender {
    
    if (self.textField.text.length == 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Warning" message:@"内容不能为空" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:ok];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    NSDictionary *content = @{
                              @"content" : self.textField.text
                              };
    if ([content writeToFile:@"/Users/huanganhua/Desktop/TestNewAPI.plist" atomically:YES]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"success" message:@"" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:ok];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
