//
//  MCRuntimeURL.m
//  MCRuntimeJSON
//
//  Created by marco chen on 2016/12/1.
//  Copyright © 2016年 marco chen. All rights reserved.
//
#import "MCWebBridgeNative.h"
#import "MCURLBridgeNative.h"
#import <objc/message.h>

typedef enum : NSUInteger {
    ObjTypeDict = 0,
    ObjTypeArray = 1
}ObjType;

@implementation MCURLBridgeNative
+ (NSURLRequest *)MC_DESDecrypt:(NSURLRequest *)request key:(NSString *)key{
    NSString * url = [[request.URL absoluteString]substringFromIndex:MCScheme.length + 3];
    return [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@://%@",MCScheme,[MCEncrypt DESDecryptBase64:url key:key]]]];
}
#pragma mark - auto check execute func 
+ (BOOL)MC_autoExecute:(NSURLRequest *)request withReceiver:(id)receiver {
    if ([MCURLBridgeNative MC_checkScheme:request]) {
        if ([self MC_checkHostisEqualVc:request]) {
            [self MC_showViewControllerRequestURL:request];
            return NO;
        }else if([self MC_checkHostisEqualFunc:request]){
            [self MC_msgSendFuncRequestURL:request withReceiver:receiver];
            return NO;
        }
    }
    return YES;
}
#pragma mark - check url
+ (BOOL)MC_checkScheme:(NSURLRequest *)request {
    return [request.URL.scheme isEqualToString:MCScheme];
}
+ (BOOL)MC_checkHostisEqualVc:(NSURLRequest *)request {
    return [[[NSURLComponents alloc]initWithString:request.URL.absoluteString].host isEqualToString:MCHostVc];
}
+ (BOOL)MC_checkHostisEqualFunc:(NSURLRequest *)request {
    return [[[NSURLComponents alloc]initWithString:request.URL.absoluteString].host isEqualToString:MCHostFunc];
}
#pragma mark - find param
+ (id)SeparatedByqueryItems:(NSURLComponents *)urlComponents withType:(ObjType)type {
    NSMutableArray * tempArr = [NSMutableArray array];
    NSMutableDictionary * tempDict = [NSMutableDictionary dictionary];
    if ([urlComponents respondsToSelector:@selector(queryItems)]) {
        NSArray * quryItems = [urlComponents queryItems];
        for (NSURLQueryItem * oneItem in quryItems) {
            switch (type) {
                case ObjTypeDict:
                {
                    [tempDict setValue:oneItem.value forKey:oneItem.name];
                }
                    break;
                case ObjTypeArray:
                {
                    [tempArr addObject:@{oneItem.name:oneItem.value}];
                }
                    break;
                default:
                    break;
            }
        }
    }else {
        switch (type) {
            case ObjTypeDict:
                tempDict = [self SeparatedByUrlItems:urlComponents withType:type];
            case ObjTypeArray:
                tempArr = [self SeparatedByUrlItems:urlComponents withType:type];
            default:
                break;
        }
    }
    switch (type) {
        case ObjTypeDict:
            return tempDict;
        case ObjTypeArray:
            return tempArr;
        default:
            return nil;
            break;
    }
}
+ (id)SeparatedByUrlItems:(NSURLComponents *)urlComponents withType:(ObjType)type {
    NSMutableArray * tempArr = [NSMutableArray array];
    NSMutableDictionary * tempDict = [NSMutableDictionary dictionary];
    NSArray * quryItems = [[urlComponents query] componentsSeparatedByString:@"&"];
    for (NSString *oneItem in quryItems) {
        NSArray *queryNameValue = [oneItem componentsSeparatedByString:@"="];
        switch (type) {
            case ObjTypeDict:
            {
                [tempDict setValue:[queryNameValue lastObject] forKey:[queryNameValue firstObject]];
            }
                break;
            case ObjTypeArray:
            {
                [tempArr addObject:@{[queryNameValue firstObject]:[queryNameValue lastObject]}];
            }
                break;
            default:
                break;
        }
    }
    switch (type) {
        case ObjTypeDict:
            return tempDict;
        case ObjTypeArray:
            return tempArr;
        default:
            return nil;
            break;
    }
}

+ (NSArray *)SeparatedByqueryItemsArray:(NSURLComponents *)urlComponents {
    return (NSArray *)[self SeparatedByqueryItems:urlComponents withType:ObjTypeArray];
}
+ (NSDictionary *)SeparatedByqueryItemsDict:(NSURLComponents *)urlComponents {
    return (NSDictionary *)[self SeparatedByqueryItems:urlComponents withType:ObjTypeDict];
}

+ (NSString *)findKey:(NSString *)key withArray:(NSArray *)arr {
    for (NSDictionary * data in arr) {
        if ([data objectForKey:key]) {
            return [data objectForKey:key];
        }
    }
    return nil;
}
#pragma mark - executeFunc
+ (void)MC_msgSendFuncRequestURL:(NSURLRequest *)request withReceiver:(id)receiver {
    NSURLComponents *urlComponents = [[NSURLComponents alloc]initWithString:request.URL.absoluteString];
    NSDictionary * data = [self SeparatedByUrlItems:urlComponents withType:ObjTypeDict];
    [MCRuntimeKeyValue MC_msgSendFuncData:data withReceiver:receiver];
}
#pragma mark - showViewController
+ (id)MC_getViewControllerRequestURL:(NSURLRequest *)request {
    NSURLComponents *urlComponents = [[NSURLComponents alloc]initWithString:request.URL.absoluteString];
    NSDictionary * data = [self SeparatedByqueryItemsDict:urlComponents];
    return [MCRuntimeKeyValue MC_getViewControllerData:data];
}
+ (void)MC_pushViewControllerRequestURL:(NSURLRequest *)request {
    if ([[[[[UIApplication sharedApplication] delegate] window] rootViewController] isKindOfClass:[UINavigationController class]]) {
        UINavigationController * nav = (UINavigationController *)[[[[UIApplication sharedApplication] delegate] window] rootViewController];
        [nav pushViewController:[self MC_getViewControllerRequestURL:request] animated:YES];
    }else {
        [self MC_presentViewControllerRequestURL:request];
    }
}
+ (void)MC_presentViewControllerRequestURL:(NSURLRequest *)request {
    [[MCRuntimeKeyValue getCurrentVC] presentViewController:[self MC_getViewControllerRequestURL:request] animated:YES completion:nil];
}
+ (void)MC_showViewControllerRequestURL:(NSURLRequest *)request {
    NSURLComponents *urlComponents = [[NSURLComponents alloc]initWithString:request.URL.absoluteString];
    NSDictionary * data = [self SeparatedByqueryItemsDict:urlComponents];
    if ([[data objectForKey:MCShowType]isEqualToString:@"present"]) {
        [self MC_presentViewControllerRequestURL:request];
    }else {
        [self MC_pushViewControllerRequestURL:request];
    }
}
@end
