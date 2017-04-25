//
//  HttpManager.h
//  PackageAFn
//
//  Created by 麦子金融 on 2017/4/12.
//  Copyright © 2017年 麦子金融. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking.h>
#import <Security/Security.h>
#import <QuartzCore/QuartzCore.h>

typedef enum requestMode {
    TRequestMode_Synchronous = 1,//同步
    TRequestMode_Asynchronous = 2,//异步
}TRequestMode;

typedef void(^requestResponce)(NSDictionary *responce,NSInteger errorCode);//errorCode  只表示  无网络  服务器错误  超时。如果服务器返回数据则这里将会是 0

//typedef enum URLRequestCachePolicy{
//    TURLRequestCachePolicy_Default = 1,//有缓存
//    TURLRequestCachePolicy_Ccache = 2,//无缓存
//    
//}TURLRequestCachePolicy;

typedef NS_ENUM(NSInteger ,TURLRequestCachePolicy) {
    TURLRequestCachePolicy_Default = 1,//有缓存
    TURLRequestCachePolicy_Ccache = 2,//无缓存
};

@interface HttpManager : NSObject
{
    
    TRequestMode m_requestMode;
    NSMutableDictionary *m_dicReceiveData;
    
}
@property (readonly)AFHTTPSessionManager *manger;
@property (nonatomic, assign)TURLRequestCachePolicy cachePolicy;
@property (nonatomic, copy)requestResponce responce;

- (instancetype)initWithRequestMode:(TRequestMode)mode;
+ (BOOL)extractIdentity:(SecIdentityRef *)outIdentity andTrust:(SecTrustRef*)outTrust fromPKCS12Data:(NSData *)inPKCS12Data;
- (void)sendRequestForPOSTWithData:(NSDictionary *)dic
                              addr:(NSString *)addr
                     ResponseBlock:(requestResponce)response;
- (void)sendRequestForGETWithData:(NSDictionary *)dic
                              addr:(NSString *)addr
                     ResponseBlock:(requestResponce)response;


@end
