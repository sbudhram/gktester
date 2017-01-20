//
//  SessionTableViewController.m
//  GKTester
//
//  Created by Shaun Budhram on 1/18/17.
//  Copyright © 2017 Shaun Budhram. All rights reserved.
//

#import "SessionTableViewController.h"
#import <GameKit/GameKit.h>
#import "GKManager.h"
#import "SessionDetailViewController.h"

@interface SessionTableViewController () <GKManagerDelegate>

@end

@implementation SessionTableViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[GKManager sharedManager] addObserver:self];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [[GKManager sharedManager] reloadSessions];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [GKManager sharedManager].sessions.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"sessionCell" forIndexPath:indexPath];

    if (indexPath.row == [GKManager sharedManager].sessions.count) {
        cell.textLabel.text = @"Create New Session...";
    }
    else {
        cell.textLabel.text = [GKManager sharedManager].sessions[indexPath.row].title;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == [GKManager sharedManager].sessions.count) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        cell.textLabel.text = @"Creating...";
        
        [[GKManager sharedManager] createNewSessionWithCompletionHandler:^(GKGameSession *session, NSError *error) {
            [tableView reloadData];
        }];
    }
    else {
        GKGameSession *session = [GKManager sharedManager].sessions[indexPath.row];
        
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        SessionDetailViewController *detailCtrlr = [sb instantiateViewControllerWithIdentifier:@"SessionDetailViewController"];
        
        detailCtrlr.title = session.title;
        detailCtrlr.identifier = session.identifier;
        [self.navigationController pushViewController:detailCtrlr animated:YES];
        
    }
    
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark GKManagerDelegate methods
- (void)manager:(GKManager *)manager didSignInPlayer:(GKCloudPlayer *)player {
}

- (void)manager:(GKManager *)manager didLoadSessions:(NSArray<GKGameSession *> *)sessions {
    [self.tableView reloadData];
}

@end
