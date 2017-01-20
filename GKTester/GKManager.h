//
//  GKManager.h
//  GKTester
//
//  Created by Shaun Budhram on 1/18/17.
//  Copyright © 2017 Shaun Budhram. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

@class GKManager;

@protocol GKManagerDelegate <NSObject>

@optional
//Use to process the final data received from the sender, after ROUSessionManager has processed it.
- (void)manager:(GKManager *)manager didSignInPlayer:(GKCloudPlayer *)player;
- (void)manager:(GKManager *)manager didLoadSessions:(NSArray <GKGameSession*> *)sessions;

@end

@interface GKManager : NSObject

@property (nonatomic, copy) GKCloudPlayer *localPlayer;
@property (nonatomic) NSArray <GKGameSession*> *sessions;

+ (GKManager*)sharedManager;

- (void)addObserver:(id<GKManagerDelegate>)observer;
- (void)removeObserver:(id<GKManagerDelegate>)observer;

- (void)createNewSessionWithCompletionHandler:(void(^)(GKGameSession *session, NSError *error))completionHandler;
- (void)removeSessionWithIdentifier:(NSString*)identifier withCompletionHandler:(void(^)(NSError *error))completionHandler;
@end
