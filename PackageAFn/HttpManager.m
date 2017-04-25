//
//  HttpManager.m
//  PackageAFn
//
//  Created by 麦子金融 on 2017/4/12.
//  Copyright © 2017年 麦子金融. All rights reserved.
//

#import "HttpManager.h"

#define IS_TEST 1
#if IS_TEST
#define HTTPURL @"https://www.maizjr.com/"
#define isHTTPS 1

#else
#define HTTPURL @"http://www.mz-dev.com/"
#define isHTTPS 0
#endif

@interface HttpManager ()
{
    
}
@property (readwrite,retain,nonatomic)AFHTTPSessionManager *manger;

@end

@implementation HttpManager

+ (BOOL)extractIdentity:(SecIdentityRef *)outIdentity andTrust:(SecTrustRef*)outTrust fromPKCS12Data:(NSData *)inPKCS12Data {
    
    OSStatus securityError = errSecSuccess;
    
    NSDictionary *optionsDictionary = [NSDictionary dictionaryWithObject:@"123456" forKey:(id)CFBridgingRelease(kSecImportExportPassphrase)];
    
    CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
    securityError = SecPKCS12Import((CFDataRef)inPKCS12Data,(CFDictionaryRef)optionsDictionary,&items);
    
    if (securityError == 0) {
        CFDictionaryRef myIdentityAndTrust = CFArrayGetValueAtIndex (items, 0);
        const void *tempIdentity = NULL;
        tempIdentity = CFDictionaryGetValue (myIdentityAndTrust, kSecImportItemIdentity);
        *outIdentity = (SecIdentityRef)tempIdentity;
        const void *tempTrust = NULL;
        tempTrust = CFDictionaryGetValue (myIdentityAndTrust, kSecImportItemTrust);
        *outTrust = (SecTrustRef)tempTrust;
    } else {
        NSLog(@"Failed with error code %d",(int)securityError);
        return NO;
    }
    
    return YES;
}

- (instancetype)initWithRequestMode:(TRequestMode)mode{
    self = [self init];
    if (self) {
        m_requestMode = mode;
        _manger = [AFHTTPSessionManager manager];
    }
    return self;
}

- (void)setCachePolicy:(TURLRequestCachePolicy )cachePolicy {
    _cachePolicy = cachePolicy;
    switch (_cachePolicy) {
        case TURLRequestCachePolicy_Default:
        {
            self.manger.requestSerializer.cachePolicy =  NSURLRequestUseProtocolCachePolicy;
        }
            break;
        case TURLRequestCachePolicy_Ccache:
        {
            self.manger.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        }
            break;
            
        default:
        {
            self.manger.requestSerializer.cachePolicy =  NSURLRequestUseProtocolCachePolicy;
        }
            break;
    }
}

- (void)addHttps {
    [_manger setSessionDidBecomeInvalidBlock:^(NSURLSession * _Nonnull session, NSError * _Nonnull error) {
        NSLog(@"setSessionDidBecomeInvalidBlock");
    }];
    
    NSString *certFilePath = [[NSBundle mainBundle] pathForResource:@"client" ofType:@"cer"];
    NSData *certData = [NSData dataWithContentsOfFile:certFilePath];
    NSSet *certSet = [NSSet setWithObject:certData];
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate withPinnedCertificates:certSet];
    policy.allowInvalidCertificates = YES;
    policy.validatesDomainName = NO;
    
    //客服端请求验证 重写 setSessionDidReceiveAuthenticationChallengeBlock 方法
    __weak typeof(self)weakSelf = self;
    [_manger setSessionDidReceiveAuthenticationChallengeBlock:^NSURLSessionAuthChallengeDisposition(NSURLSession*session, NSURLAuthenticationChallenge *challenge, NSURLCredential *__autoreleasing*_credential) {
        NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        __autoreleasing NSURLCredential *credential =nil;
        if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
            if([weakSelf.manger.securityPolicy evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:challenge.protectionSpace.host]) {
                credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
                if(credential) {
                    disposition =NSURLSessionAuthChallengeUseCredential;
                } else {
                    disposition =NSURLSessionAuthChallengePerformDefaultHandling;
                }
            } else {
                disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
            }
        } else {
            // client authentication
            SecIdentityRef identity = NULL;
            SecTrustRef trust = NULL;
            NSString *p12 = [[NSBundle mainBundle] pathForResource:@"hejia" ofType:@"p12"];
            NSFileManager *fileManager =[NSFileManager defaultManager];
            
            if(![fileManager fileExistsAtPath:p12])
            {
                NSLog(@"client.p12:not exist");
            }
            else
            {
                NSData *PKCS12Data = [NSData dataWithContentsOfFile:p12];
                
                if ([[weakSelf class] extractIdentity:&identity andTrust:&trust fromPKCS12Data:PKCS12Data])
                {
                    SecCertificateRef certificate = NULL;
                    SecIdentityCopyCertificate(identity, &certificate);
                    const void*certs[] = {certificate};
                    CFArrayRef certArray =CFArrayCreate(kCFAllocatorDefault, certs,1,NULL);
                    credential =[NSURLCredential credentialWithIdentity:identity certificates:(__bridge  NSArray*)certArray persistence:NSURLCredentialPersistencePermanent];
                    disposition =NSURLSessionAuthChallengeUseCredential;
                }
            }
        }
        *_credential = credential;
        return disposition;
    }];
}

- (void)sendRequestForPOSTWithData:(NSDictionary *)dic
                              addr:(NSString *)addr
                     ResponseBlock:(requestResponce)response{
    
    if (!_manger) {
        _manger = [AFHTTPSessionManager manager];
    }
    
    _manger.requestSerializer = [AFJSONRequestSerializer serializer];
    [_manger.requestSerializer setValue:@"Content-Type" forHTTPHeaderField:@"application/x-www-form-urlencoded; encoding=utf-8"];
    [_manger.requestSerializer setValue:@"Accept" forHTTPHeaderField:@"application/json"];
    [_manger.requestSerializer setTimeoutInterval:30];
    
    if (isHTTPS) {
        [self addHttps];
    }
    
    NSString *urlString = [NSString stringWithFormat:@"%@%@",HTTPURL,addr];
    NSLog(@"urlString ----- %@",urlString);
    
    [_manger POST:urlString parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *dic = (NSDictionary *)responseObject;
        NSLog(@"responseObject -- %@",dic);
        response(dic,0);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@" error -- %@",error);
        response(nil,0);
    }];
}

- (void)sendRequestForGETWithData:(NSDictionary *)dic
                              addr:(NSString *)addr
                     ResponseBlock:(requestResponce)response{
    if (!_manger) {
        _manger = [AFHTTPSessionManager manager];
    }
    
    _manger.requestSerializer = [AFJSONRequestSerializer serializer];
    [_manger.requestSerializer setValue:@"Content-Type" forHTTPHeaderField:@"application/x-www-form-urlencoded; encoding=utf-8"];
    [_manger.requestSerializer setValue:@"Accept" forHTTPHeaderField:@"application/json"];
    [_manger.requestSerializer setTimeoutInterval:30];
    
//    if (isHTTPS) {
//        [self addHttps];
//    }
    
    NSString *urlString = [NSString stringWithFormat:@"%@%@",HTTPURL,addr];
    NSLog(@"urlString ----- %@",urlString);
    
    [_manger GET:urlString parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *dic = (NSDictionary *)responseObject;
        NSLog(@"responseObject -- %@",dic);
        response(dic,0);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error -- %@",error);
        response(nil,0);
    }];
    
}

- (void)sendRequestForPUTWithData:(NSDictionary *)dic
                             addr:(NSString *)addr
                    ResponseBlock:(requestResponce)response{
    if (!_manger) {
        _manger = [AFHTTPSessionManager manager];
    }
    
    _manger.requestSerializer = [AFJSONRequestSerializer serializer];
    [_manger.requestSerializer setValue:@"Content-Type" forHTTPHeaderField:@"application/x-www-form-urlencoded; encoding=utf-8"];
    [_manger.requestSerializer setValue:@"Accept" forHTTPHeaderField:@"application/json"];
    [_manger.requestSerializer setTimeoutInterval:30];
    
    if (isHTTPS) {
        [self addHttps];
    }
    
    NSString *urlString = [NSString stringWithFormat:@"%@%@",HTTPURL,addr];
    NSLog(@"urlString ----- %@",urlString);
    
    [_manger PUT:urlString parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *dic = (NSDictionary *)responseObject;
        NSLog(@"responseObject -- %@",dic);
        response(dic,0);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error -- %@",error);
        response(nil,0);
    }];
    
}


@end
