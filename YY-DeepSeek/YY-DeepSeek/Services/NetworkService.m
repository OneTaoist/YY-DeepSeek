//
//  NetworkService.m
//  YY-DeepSeek
//
//  Created by yinyao on 2025/2/6.
//

#import "NetworkService.h"
#import "APIConfig.h"

@implementation NetworkService

+ (instancetype)shared {
    static NetworkService *instance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        instance = [[NetworkService alloc] init];
    });
    return instance;
}


- (void)sendMessageToDeepSeek:(NSString *)userMessage completion:(void (^)(NSString *response, NSError *error))completion {
    // 设置请求的 URL
    NSURL *url = [NSURL URLWithString:API_BASE_URL];
    
    // 创建请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    // 设置请求方法
    [request setHTTPMethod:@"POST"];
    
    // 设置请求头
    [request setValue:[NSString stringWithFormat:@"Bearer %@", API_KEY] forHTTPHeaderField:@"Authorization"];
    
    // 设置 Content-Type
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    // 设置请求体内容
    NSDictionary *parameters = @{
        @"model"    : @"deepseek-chat",      // 选择聊天模型，这里可以根据 DeepSeek 的文档指定模型名称（deepseek-chat, deepseek-reasoner）
        @"messages" : @[
            @{ @"role": @"system",  @"content": @"You are a helpful assistant." },
            @{ @"role": @"user",    @"content": userMessage } // 用户发送的消息
        ]
    };
    
    // 将参数转化为 JSON 数据并设置到请求体中
    NSError *error;
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:&error];
    if (error) {
        NSLog(@"Error serializing JSON: %@", error.localizedDescription);
        if (completion) {
            completion(nil, error);
        }
        return;
    }
    
    [request setHTTPBody:bodyData];
    
    // 发起请求
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error.localizedDescription);
            if (completion) {
                completion(nil, error);
            }
            return;
        }
        
        // 处理返回的数据
        NSError *jsonError;
        NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError) {
            NSLog(@"Error parsing JSON: %@", jsonError.localizedDescription);
            
            // 将 NSData 转换为 NSString，指定编码类型（通常使用 UTF-8 编码）
            NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"Error parsing 字符串: %@", string);
            
            if (completion) {
                completion(nil, jsonError);
            }
            return;
        }
        
        // 打印返回的消息
        NSString *chatResponse = responseDict[@"choices"][0][@"message"][@"content"];
        NSLog(@"Received response: %@", chatResponse);
        
        //
        if (completion) {
            completion(chatResponse, nil);
        }

    }];
    
    // 启动任务
    [task resume];
}

@end
