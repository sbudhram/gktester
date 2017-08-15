//
//  SessionDetailViewController.m
//  GKTester
//
//  Created by Shaun Budhram on 1/19/17.
//  Copyright © 2017 Shaun Budhram. All rights reserved.
//

#import "SessionDetailViewController.h"
#import <GameKit/GameKit.h>
#import "GKManager.h"

@interface SessionDetailViewController () <GKManagerDelegate>

@property (nonatomic) IBOutlet UILabel *identifierLabel;
@property (nonatomic) IBOutlet UILabel *shareUrlLabel;
@property (nonatomic) IBOutlet UIButton *shareUrlButton;
@property (nonatomic) IBOutlet UIButton *connectButton;
@property (nonatomic) IBOutlet UIButton *removeButton;
@property (nonatomic) IBOutlet UILabel *membersLabel;
@property (nonatomic) IBOutlet UILabel *connectedLabel;


@end

@implementation SessionDetailViewController {
    GKGameSession *_session;
    NSURL *_shareUrl;
    BOOL _connected;
    int _count;
}

- (void)setIdentifier:(NSString *)identifier {

    _identifier = identifier;
    [self refreshSession];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[GKManager sharedManager] addObserver:self];
    _count = 0;
    
}

- (void)dealloc {
    [[GKManager sharedManager] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)refreshSession {
    
    [[GKManager sharedManager] loadSessionWithIdentifier:_identifier withCompletionHandler:^(GKGameSession *session, NSError *error) {
        if (!error) {
            NSLog(@"Session loaded.");
            [self manager:nil sessionDidUpdate:session];
        }
    }];
}

- (IBAction)shareUrl:(id)sender {
    if (!_shareUrl) {
        _shareUrlLabel.text = @"Loading...";
        [_session getShareURLWithCompletionHandler:^(NSURL * _Nullable url, NSError * _Nullable error) {
            _shareUrl = url;
            _shareUrlLabel.text = url.absoluteString;
            [_shareUrlButton setTitle:@"Share this URL" forState:UIControlStateNormal];
        }];
    }
    else {
        UIActivityViewController *actView = [[UIActivityViewController alloc] initWithActivityItems:@[_shareUrl] applicationActivities:nil];
        actView.popoverPresentationController.sourceView = self.view;
        actView.popoverPresentationController.sourceRect = CGRectMake(0, 0, 10, 10);
        [self presentViewController:actView animated:YES completion:nil];
    }
}

- (IBAction)removeSession:(id)sender {
    [_removeButton setTitle:@"Removing..." forState:UIControlStateNormal];
    [[GKManager sharedManager] removeSessionWithIdentifier:_session.identifier withCompletionHandler:^(NSError *error) {
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

- (IBAction)connectToStream:(id)sender {

    if (!_connected) {
        [_connectButton setTitle:@"Connecting..." forState:UIControlStateNormal];
        [_session setConnectionState:GKConnectionStateConnected completionHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"Error: %@", error.description);
            }
            else {
                NSLog(@"Session connected.");
                _connected = TRUE;
                
                [self manager:nil sessionDidUpdate:_session];
                
            }
        }];
    }
    else {
        _connectButton.titleLabel.text = @"Disconnecting...";
        [_session setConnectionState:GKConnectionStateNotConnected completionHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"Error: %@", error.description);
            }
            else {
                NSLog(@"Session disconnected.");
                _connected = FALSE;

                [self manager:nil sessionDidUpdate:_session];
            }
        }];
    }
    
}

- (IBAction)sendTestData {
    NSString *msg = [NSString stringWithFormat:@"%d", _count++];
    NSData *data = [msg dataUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"Sending: %@", msg);
    [_session sendData:data withTransportType:GKTransportTypeReliable completionHandler:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"ERROR: %@", error.description);
        }
    }];
}

- (IBAction)sendTestData60 {
    
    //Send 60 messages in a row
    double timer = 0.0;
    for (int i = 0; i < 60; i++) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timer * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self sendTestData];
        });
        timer += .1;
    }
    
}

- (IBAction)sendTestDataUDP {
    NSString *msg = [NSString stringWithFormat:@"%d", _count++];
    NSData *data = [msg dataUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"Sending: %@", msg);
    [_session sendData:data withTransportType:GKTransportTypeUnreliable completionHandler:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"ERROR: %@", error.description);
        }
    }];
}

- (IBAction)sendTestData60UDP {
    
    //Send 60 messages in a row
    double timer = 0.0;
    for (int i = 0; i < 60; i++) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timer * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self sendTestDataUDP];
        });
        timer += .1;
    }
    
}

- (void)manager:(GKManager *)manager sessionDidUpdate:(GKGameSession *)session {
    if ([session.identifier isEqualToString:_identifier]) {
        _session = session;
        _identifierLabel.text = _session.identifier;
        _membersLabel.text = [self mapPlayersToString:_session.players];
        _connectedLabel.text = [self mapPlayersToString:[session playersWithConnectionState:GKConnectionStateConnected]];
        
        if ([[_session playersWithConnectionState:GKConnectionStateConnected] containsObject:[GKManager sharedManager].localPlayer]) {
            [_connectButton setTitle:@"Disconnect From Stream" forState:UIControlStateNormal];
        }
        else {
            [_connectButton setTitle:@"Connect to Stream" forState:UIControlStateNormal];
        }
    
    }
}

- (NSString*)mapPlayersToString:(NSArray<GKCloudPlayer*>*)array {
    NSMutableArray *ids = [NSMutableArray arrayWithCapacity:3];
    for (GKCloudPlayer *player in array) {
        [ids addObject:player.playerID];
    }
    return [ids componentsJoinedByString:@",\n"];
}

- (void)manager:(GKManager *)manager session:(GKGameSession *)session didAddPlayer:(GKCloudPlayer *)player {
}

- (void)manager:(GKManager *)manager session:(GKGameSession *)session didRemovePlayer:(GKCloudPlayer *)player {
}

- (void)manager:(GKManager *)manager session:(GKGameSession *)session player:(GKCloudPlayer *)player changedConnectionState:(GKConnectionState)state {
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
