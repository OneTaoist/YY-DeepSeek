//
//  NetworkService.h
//  YY-DeepSeek
//
//  Created by yinyao on 2025/2/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NetworkService : NSObject

+ (instancetype)shared;

- (void)sendMessageToDeepSeek:(NSString *)userMessage completion:(void (^)(NSString *response, NSError *error))completion;

@end

NS_ASSUME_NONNULL_END
