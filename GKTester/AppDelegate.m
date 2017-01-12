//
//  AppDelegate.m
//  GKTester
//
//  Created by Shaun Budhram on 1/3/17.
//  Copyright © 2017 Shaun Budhram. All rights reserved.
//

#import "AppDelegate.h"
#import <GameKit/GameKit.h>

static int counter = 0;

@interface AppDelegate () <GKGameSessionEventListener>

@end

@implementation AppDelegate {

    GKGameSession *_origSession;
    GKGameSession *_session;
    GKCloudPlayer *_localPlayer;
    
    NSTimer *_sendTimer;
    
}

- (void)createSession {

    [GKGameSession createSessionInContainer:nil
                                  withTitle:@"My Session"
                        maxConnectedPlayers:4
                          completionHandler:^(GKGameSession * _Nullable session, NSError * _Nullable error) {
                              if (error != nil) {
                                  NSLog(@"Error: %@", error.description);
                              }
                              else {
                                  NSLog(@"Session Created: %@", session.identifier);
                                  _session = session;


                                  NSLog(@"Connecting...");
                                  [session setConnectionState:GKConnectionStateConnected completionHandler:^(NSError * _Nullable error) {
                                      if (error) {
                                          NSLog(@"Error: %@", error.description);
                                      }
                                      else {
                                          NSLog(@"Session connected.");
                                          
                                          _session = session;
                                          _sendTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(sendData:) userInfo:nil repeats:YES];
                                          
                                          NSLog(@"Original: %@", [_origSession playersWithConnectionState:GKConnectionStateConnected].description);
                                          NSLog(@"Loaded/Connected: %@", [_session playersWithConnectionState:GKConnectionStateConnected].description);
                                          
                                          dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                              NSLog(@"Disconnecting...");
                                              [session setConnectionState:GKConnectionStateNotConnected completionHandler:^(NSError * _Nullable error) {
                                                  if (error) {
                                                      NSLog(@"Error: %@", error.description);
                                                  }
                                                  else {
                                                      NSLog(@"Session disconnected.");
                                                      [_sendTimer invalidate];
                                                  }
                                              }];
                                          });
                                      }
                                  }];

                                  
                                  
                                  
//                                  [_session getShareURLWithCompletionHandler:^(NSURL * _Nullable url, NSError * _Nullable error) {
//
//                                      if (error) {
//                                          NSLog(@"Error: %@", error.description);
//                                      }
//                                      else {
//
//                                          NSLog(@"Share URL: %@", url.description);
//                                          
//                                      }
//                              
//                                  }];
                              }
                              
                          }];
}

- (void)loadSession {
    
    [GKGameSession loadSessionsInContainer:nil completionHandler:^(NSArray<GKGameSession *> * _Nullable sessions, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error retrieving sessions: %@", error.description);
        }
        else {
            
            NSLog(@"Sessions: %@", sessions.description);
            
            if (sessions.count > 0) {
                GKGameSession *session0 = sessions[0];
                _origSession = session0;
                [session0 getShareURLWithCompletionHandler:^(NSURL * _Nullable url, NSError * _Nullable error) {
                    if (!error) {
                        NSLog(@"Share URL: %@", url.description);

                        [GKGameSession loadSessionWithIdentifier:session0.identifier completionHandler:^(GKGameSession * _Nullable session, NSError * _Nullable error) {
                            
                            if (!error) {
                                
                                NSLog(@"Session loaded: %@", session.description);
                                
                                NSLog(@"Connecting...");
                                [session setConnectionState:GKConnectionStateConnected completionHandler:^(NSError * _Nullable error) {
                                    if (error) {
                                        NSLog(@"Error: %@", error.description);
                                    }
                                    else {
                                        NSLog(@"Session connected.");

                                        _session = session;
                                        _sendTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(sendData:) userInfo:nil repeats:YES];

                                        NSLog(@"Original: %@", [_origSession playersWithConnectionState:GKConnectionStateConnected].description);
                                        NSLog(@"Loaded/Connected: %@", [_session playersWithConnectionState:GKConnectionStateConnected].description);
                                        
                                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                            NSLog(@"Disconnecting...");
                                            [session setConnectionState:GKConnectionStateNotConnected completionHandler:^(NSError * _Nullable error) {
                                                if (error) {
                                                    NSLog(@"Error: %@", error.description);
                                                }
                                                else {
                                                    NSLog(@"Session disconnected.");
                                                    [_sendTimer invalidate];
                                                }
                                            }];
                                        });
                                    }
                                }];
                            }
                        }];
                        
                    }
                }];

           }
        }
    }];
}

- (void)sendData:(NSTimer*)timer {
    
    NSArray *players = [_session playersWithConnectionState:GKConnectionStateConnected];
    NSLog(@"Connected players: %@", players.description);
    if (players.count > 1) {
        NSString *sendString = [NSString stringWithFormat:@"%d", counter++];
        NSLog(@"Sending: %@", sendString);
        NSData *data = [sendString dataUsingEncoding:NSUTF8StringEncoding];
        [_session sendData:data withTransportType:GKTransportTypeReliable completionHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"Send data error: %@", error.description);
            }
            else {
//                NSLog(@"Data sent.");
            }
        }];
    }
}

- (void)removeAllSessions {
    
    [GKGameSession loadSessionsInContainer:nil completionHandler:^(NSArray<GKGameSession *> * _Nullable sessions, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error retrieving sessions: %@", error.description);
        }
        else {
        
            for (GKGameSession *session in sessions) {
                [GKGameSession removeSessionWithIdentifier:session.identifier completionHandler:^(NSError * _Nullable error) {
                    if (!error) {
                        NSLog(@"Session removed: %@", session.description);
                    }
                }];
            }
            
            
        }
    }];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.

    [GKGameSession addEventListener:self];
    
    [GKCloudPlayer getCurrentSignedInPlayerForContainer:nil
                                      completionHandler:^(GKCloudPlayer * _Nullable player, NSError * _Nullable error) {
                                          if (error) {
                                              NSLog(@"Error: %@", error.description);
                                          }
                                          else {
                                              NSLog(@"Current player: %@", player.description);
                                              _localPlayer = player;
                                          }
                                      }];
    
//    [self createSession];
    [self loadSession];
//    [self removeAllSessions];
    
    return YES;
}

#pragma mark - GKGameSessionEventListener Delgate Methods
- (void)session:(GKGameSession *)session
   didAddPlayer:(GKCloudPlayer *)player {
    NSLog(@"GAME: Player added: %@  to session: %@", player.displayName, session.identifier);
}

- (void)session:(GKGameSession *)session
didRemovePlayer:(GKCloudPlayer *)player {
    NSLog(@"GAME: Player removed: %@  from session: %@", player.displayName, session.identifier);
}

- (void)session:(GKGameSession *)session
         player:(GKCloudPlayer *)player
didChangeConnectionState:(GKConnectionState)newState {
    NSLog(@"GAME: Player: %@  Session: %@  Connection state changed: %d", player.description, session.identifier, (int)newState);
    NSLog(@"GAME: Active Players: %@", [session playersWithConnectionState:GKConnectionStateConnected].description);
    _session = session;
    
}

- (void)session:(GKGameSession *)session
didReceiveMessage:(NSString *)message
       withData:(NSData *)data
     fromPlayer:(GKCloudPlayer *)player {
    NSLog(@"GAME: Received message from Player: %@  Session: %@  Message: %@  Data: %@", player.displayName, session.identifier, message, [NSString stringWithUTF8String:[data bytes]]);
}

- (void)session:(GKGameSession *)session
 didReceiveData:(NSData *)data
     fromPlayer:(GKCloudPlayer *)player {
    NSLog(@"GAME: Received data from Player: %@  Data: %@", player.displayName, [NSString stringWithUTF8String:[data bytes]]);
}

- (void)session:(GKGameSession *)session
         player:(GKCloudPlayer *)player
    didSaveData:(NSData *)data {
    NSLog(@"GAME: Player: %@  Session: %@  Saved Data: %@", player.displayName, session.identifier, [NSString stringWithUTF8String:[data bytes]] );
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
