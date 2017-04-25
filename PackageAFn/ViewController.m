//
//  ViewController.m
//  PackageAFn
//
//  Created by 麦子金融 on 2017/4/12.
//  Copyright © 2017年 麦子金融. All rights reserved.
//

#import "ViewController.h"
#import <AFNetworking.h>
#import "HttpManager.h"

@interface ViewController ()

@property (nonatomic, strong)NSURLConnection *connection;
@property (nonatomic, strong)NSArray *trustedCertificates;
@property (nonatomic, strong)AFHTTPSessionManager *manager;

@end

@implementation ViewController
- (IBAction)btnClick:(id)sender {
    HttpManager *manager = [[HttpManager alloc] initWithRequestMode:TRequestMode_Asynchronous];
    manager.cachePolicy = TURLRequestCachePolicy_Ccache;
    [manager sendRequestForGETWithData:nil addr:@"v280/home.json" ResponseBlock:^(NSDictionary *responce, NSInteger errorCode) {
        NSLog(@"responce ---------- %@",responce);
    }];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
