//
//  GKManager.m
//  GKTester
//
//  Created by Shaun Budhram on 1/18/17.
//  Copyright © 2017 Shaun Budhram. All rights reserved.
//

#import "GKManager.h"

@interface GKManager () <GKGameSessionEventListener>
@end

@implementation GKManager {
    
    NSHashTable *_delegates;
    
}

////////////////////////////////////////////////////////////
//
//  Shared Instance Setup
static GKManager *sharedManager = NULL;

+(void) initialize {
    
    @synchronized(self) {
        if (sharedManager == NULL)
            sharedManager = [[self alloc] init];
    }
    
}

+ (GKManager*)sharedManager {
    
    return(sharedManager);
    
}

- (id)init {
    self = [super init];
    if (self) {
        
        _delegates = [[NSHashTable alloc] initWithOptions:NSPointerFunctionsWeakMemory | NSPointerFunctionsObjectPointerPersonality capacity:3];
        
        [GKGameSession addEventListener:self];
        
        [GKCloudPlayer getCurrentSignedInPlayerForContainer:nil
                                          completionHandler:^(GKCloudPlayer * _Nullable player, NSError * _Nullable error) {
                                              if (error) {
                                                  NSLog(@"Error: %@", error.description);
                                              }
                                              else {
                                                  NSLog(@"Current player: %@", player.description);
                                                  _localPlayer = player;
                                                  for (id<GKManagerDelegate> delegate in _delegates) {
                                                      if ([delegate respondsToSelector:@selector(manager:didSignInPlayer:)])
                                                          [delegate manager:self didSignInPlayer:_localPlayer];
                                                  }
                                              }
                                          }];
        
    }
    return self;
}

- (void)reloadSessions {
    
    [GKGameSession loadSessionsInContainer:nil completionHandler:^(NSArray<GKGameSession *> * _Nullable sessions, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error retrieving sessions: %@", error.description);
        }
        else {
            _sessions = [NSMutableArray arrayWithArray:sessions];
            NSLog(@"Sessions:");
            for (GKGameSession *session in _sessions) {
                NSLog(@"%@", session.description);
                NSLog(@"--players: %@", session.players.description);
            }
            
            for (id<GKManagerDelegate> delegate in _delegates) {
                if ([delegate respondsToSelector:@selector(manager:didLoadSessions:)])
                    [delegate manager:self didLoadSessions:_sessions];
            }
            
        }
    }];
}

- (void)addObserver:(id<GKManagerDelegate>)observer {
    [_delegates addObject:observer];
}

- (void)removeObserver:(id<GKManagerDelegate>)observer {
    [_delegates removeObject:observer];
}

- (void)createNewSessionWithCompletionHandler:(void(^)(GKGameSession *session, NSError *error))completionHandler {

    [GKGameSession createSessionInContainer:nil
                                  withTitle:[NSString stringWithFormat:@"Session %lu - %@", _sessions.count + 1, _localPlayer.displayName]
                        maxConnectedPlayers:4
                          completionHandler:^(GKGameSession * _Nullable session, NSError * _Nullable error) {
                              if (error != nil) {
                                  NSLog(@"Error: %@", error.description);
                              }
                              else {
                                  NSLog(@"Session Created: %@", session.identifier);
                                  
                                  if (completionHandler) {
                                      completionHandler(session, error);
                                  }
                                  
                                  //Reload our sessions
                                  [self reloadSessions];
                                  
                              }
                          }];
}

- (void)loadSessionWithIdentifier:(NSString*)identifier withCompletionHandler:(void(^)(GKGameSession *session, NSError *error))completionHandler {
    
    [GKGameSession loadSessionWithIdentifier:identifier completionHandler:^(GKGameSession *session, NSError * _Nullable error) {
        if (!error) {
            if (completionHandler) {
                
                for (id<GKManagerDelegate> delegate in _delegates) {
                    if ([delegate respondsToSelector:@selector(manager:sessionDidUpdate:)])
                        [delegate manager:self sessionDidUpdate:session];
                }

                completionHandler(session, error);
            }
        }
        else {
            if (completionHandler) {
                completionHandler(nil, error);
            }
        }
    }];
    
}

- (void)removeSessionWithIdentifier:(NSString*)identifier withCompletionHandler:(void(^)(NSError *error))completionHandler {
    
    [GKGameSession removeSessionWithIdentifier:identifier completionHandler:^(NSError * _Nullable error) {
        if (!error) {
            if (completionHandler) {
                completionHandler(error);
            }
        }
    }];

}




#pragma mark - GKGameSessionEventListener Delgate Methods
- (void)session:(GKGameSession *)session
   didAddPlayer:(GKCloudPlayer *)player {
    NSLog(@"GAME: Player added: %@, id:%@, to session: %@", player.displayName, player.playerID, session.identifier);

    [self validateSession:session];

    for (id<GKManagerDelegate> delegate in _delegates) {
        if ([delegate respondsToSelector:@selector(manager:session:didAddPlayer:)])
            [delegate manager:self session:session didAddPlayer:player];
    }


    //Reload our sessions, since we may have been added to one.
    [self reloadSessions];


}

- (void)session:(GKGameSession *)session
didRemovePlayer:(GKCloudPlayer *)player {
    NSLog(@"GAME: Player removed: %@ id:%@  from session: %@", player.displayName, player.playerID, session.identifier);

    [self validateSession:session];
    
    if (_localPlayer == player) {
        NSLog(@"GAME: WE were removed from this session!  Reloading sessions...");
        [self reloadSessions];
    }
    
    for (id<GKManagerDelegate> delegate in _delegates) {
        if ([delegate respondsToSelector:@selector(manager:session:didRemovePlayer:)])
            [delegate manager:self session:session didRemovePlayer:player];
    }
    
    
}

- (void)session:(GKGameSession *)session
         player:(GKCloudPlayer *)player
didChangeConnectionState:(GKConnectionState)newState {
    NSLog(@"GAME: Player: %@ id:%@ Session: %@  Connection state changed: %d", player.description, player.playerID, session.identifier, (int)newState);
    NSLog(@"GAME: Active Players: %@", [session playersWithConnectionState:GKConnectionStateConnected].description);

    [self validateSession:session];

    for (id<GKManagerDelegate> delegate in _delegates) {
        if ([delegate respondsToSelector:@selector(manager:session:player:changedConnectionState:)])
            [delegate manager:self session:session player:player changedConnectionState:newState];
    }

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
    static int lastVal = -1;
    NSString *strVal = [NSString stringWithUTF8String:[data bytes]];
    int val = [strVal intValue];
    if (val != lastVal + 1) {
        NSLog(@"******************** VALUE SKIPPED *************************");
    }
    NSLog(@"GAME: Received data from Player: %@  Data: %@", player.displayName, strVal);
    lastVal = val;
}

- (void)session:(GKGameSession *)session
         player:(GKCloudPlayer *)player
    didSaveData:(NSData *)data {
    NSLog(@"GAME: Player: %@  Session: %@  Saved Data: %@", player.displayName, session.identifier, [NSString stringWithUTF8String:[data bytes]] );
}

- (void)validateSession:(GKGameSession*)session {
    for ( int i = 0; i < _sessions.count; i++) {
        GKGameSession *curSession = _sessions[i];
        if ([curSession.identifier isEqualToString:session.identifier]) {
            //Ok, we've found a matching session.  Make sure the player counts are equal.
            if (curSession.players != session.players ||
                [curSession playersWithConnectionState:GKConnectionStateConnected] != [session playersWithConnectionState:GKConnectionStateConnected])
            {
                NSLog(@"*** BUG *** Player counts not equal.");
                NSLog(@"Old Session Players: %@", curSession.players.description);
                NSLog(@"New Session Players: %@", session.players.description);
                NSLog(@"Old Connected Players: %@", [curSession playersWithConnectionState:GKConnectionStateConnected].description);
                NSLog(@"New Connected Players: %@", [session playersWithConnectionState:GKConnectionStateConnected].description);

                //Swap out this session
                NSLog(@"Swapping out session.");
                [_sessions replaceObjectAtIndex:i withObject:session];
                
                for (id<GKManagerDelegate> delegate in _delegates) {
                    if ([delegate respondsToSelector:@selector(manager:sessionDidUpdate:)])
                        [delegate manager:self sessionDidUpdate:session];
                }
                
                break;
                
            }
        }
    }
}


@end
