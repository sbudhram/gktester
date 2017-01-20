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

@end

@implementation SessionDetailViewController {
    GKGameSession *_session;
    NSURL *_shareUrl;
    BOOL _connected;
}

- (void)setIdentifier:(NSString *)identifier {

    _identifier = identifier;
    
    [GKGameSession loadSessionWithIdentifier:identifier completionHandler:^(GKGameSession * _Nullable session, NSError * _Nullable error) {
        _session = session;
        _identifierLabel.text = _session.identifier;
        NSLog(@"Session loaded.");
        
    }];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[GKManager sharedManager] addObserver:self];
    
}

- (void)dealloc {
    [[GKManager sharedManager] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
                [_connectButton setTitle:@"Disconnect from Stream" forState:UIControlStateNormal];
                
                [self updateConnectedPlayers];
                
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
                [_connectButton setTitle:@"Connect to Stream" forState:UIControlStateNormal];
            }
        }];
    }
    
}

- (void)updateConnectedPlayers {

    NSArray *players = [_session playersWithConnectionState:GKConnectionStateConnected];
    NSLog(@"DetailView: Connected Players: %@", players);

}

- (void)manager:(GKManager *)manager session:(GKGameSession *)session didAddPlayer:(GKCloudPlayer *)player {
    _session = session;
    [self updateConnectedPlayers];
}

- (void)manager:(GKManager *)manager session:(GKGameSession *)session didRemovePlayer:(GKCloudPlayer *)player {
    _session = session;
    [self updateConnectedPlayers];
}

- (void)manager:(GKManager *)manager session:(GKGameSession *)session player:(GKCloudPlayer *)player changedConnectionState:(GKConnectionState)state {
    [self updateConnectedPlayers];
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
