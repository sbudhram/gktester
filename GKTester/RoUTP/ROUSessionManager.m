//
//  ROUSessionManager.m
//  GKTester
//
//  Created by Shaun Budhram on 1/12/17.
//  Copyright © 2017 Shaun Budhram. All rights reserved.
//

#import "ROUSessionManager.h"

@implementation ROUSessionManager

////////////////////////////////////////////////////////////
//
//  Shared Instance Setup
static ROUSessionManager *sharedROUManager = NULL;

+(void) initialize {
    
    @synchronized(self) {
        if (sharedROUManager == NULL)
            sharedROUManager = [[self alloc] init];
    }
    
}

+ (ROUSessionManager*)sharedManager {
    
    return(sharedROUManager);

}

- (void)reset {
}
- (void)addSender:(NSString*)sender {
}
- (void)addRecipient:(NSString*)recipient {
}
- (void)removeRecipient:(NSString*)recipient {
}
- (void)sendData:(NSData *)data toRecipients:(NSArray<NSString*>*)recipients reliably:(BOOL)reliable immediately:(BOOL)immediately {
}
- (void)didReceiveData:(NSData *)data {
}

@end
