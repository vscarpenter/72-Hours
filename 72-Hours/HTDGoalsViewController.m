//
//  ViewController.m
//  72-Hours
//
//  Created by Chi on 2/12/14.
//  Copyright (c) 2014 CHI. All rights reserved.
//

#import "HTDGoalsViewController.h"
#import "HTDGoalDetailViewController.h"
#import "HTDGoalCell.h"
#import "HTDGoal.h"
#import "HTDDatabase.h"
#import "HTDDefaultViewController.h"


// System Versioning Preprocessor Macros
#define SYSTEM_VERSION_EQUAL_TO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

@interface HTDGoalsViewController ()

@property (strong, nonatomic) NSArray *activeActions;
@property int goalID;

@end

@implementation HTDGoalsViewController


- (IBAction)save:(UIStoryboardSegue *)segue {
    
    [[[HTDDatabase alloc] init] updateNextActionName:self.action];
    [self dismissViewControllerAnimated:YES completion:nil];

}

- (instancetype)init {
    self = [super initWithStyle:UITableViewStylePlain];
    
    return self;
}


- (instancetype)initWithStyle:(UITableViewStyle)style {
    return [self init];
}


- (void)removeDefaultViewController {
    if ([[self.childViewControllers lastObject] isKindOfClass:[HTDDefaultViewController class]]) {
        UIViewController *defaultController = [self.childViewControllers lastObject];
        
        [defaultController willMoveToParentViewController:nil];
        [defaultController.view removeFromSuperview];
        [defaultController removeFromParentViewController];
        [self removeDefaultViewController];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    if ([self.activeActions count] != 0) {
        
        [self removeDefaultViewController];
        
        return 1;
    } else {
        // Display a message when the table is empty
        if (![[self.childViewControllers lastObject] isKindOfClass:[HTDDefaultViewController class]]) {
            HTDDefaultViewController *defaultController = [[HTDDefaultViewController alloc] init];
            
            [self addChildViewController:defaultController];
            
            CGFloat width = self.tableView.frame.size.width;
            CGFloat height = self.view.frame.size.height - [UIApplication sharedApplication].statusBarFrame.size.height - self.navigationController.navigationBar.frame.size.height - self.tabBarController.tabBar.bounds.size.height;
            CGRect frame = CGRectMake(0, 0, width, height);
            defaultController.view.frame = frame;
            defaultController.defaultText.text = @"Active tab collects goals you want to achieve.";
            [defaultController.defaultText setCenter:defaultController.view.center];
            //        defaultController.defaultText.layer.borderColor = [UIColor grayColor].CGColor;
            //        defaultController.defaultText.layer.borderWidth = 1.0;
            [self.view addSubview:defaultController.view];
        }
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.activeActions count];
}


- (IBAction)nextActionButton:(UIButton *)sender {
    HTDAction *action = self.activeActions[sender.tag];
    
    // flip action status
    [[[HTDDatabase alloc] init] flipActionStatus:action];
    
    [self performSegueWithIdentifier:@"addNextAction" sender:action];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HTDGoalCell *cell = [tableView dequeueReusableCellWithIdentifier:@"HTDGoalCell" forIndexPath:indexPath];
    
    HTDAction *action = [[HTDAction alloc] init];
    action = self.activeActions[indexPath.row];
    
    cell.actionName.text = action.action_name;
    cell.goalName.text = action.goal_name;
    
    NSDate *today = [NSDate date];
    NSTimeInterval distanceBetweenDates = [today timeIntervalSinceDate:action.date_start];
    double secondsInAnHour = 3600;
    int hoursBetweenDates = distanceBetweenDates / secondsInAnHour;
    cell.timeLeft.text = [NSString stringWithFormat:@"%d", (72-hoursBetweenDates)];
    
    
    if (action.highlight_indicate == 0) {
        cell.backgroundColor = [UIColor grayColor];
    }
    
    if (hoursBetweenDates <= 24) {
        UIImage *image = [UIImage imageNamed: @"Oval_green"];
        [cell.ovalImageView setImage:image];
    } else if (hoursBetweenDates <= 48) {
        UIImage *image = [UIImage imageNamed: @"Oval"];
        [cell.ovalImageView setImage:image];
    } else if (hoursBetweenDates < 72){
        UIImage *image = [UIImage imageNamed: @"Oval_red"];
        [cell.ovalImageView setImage:image];
    } else {
        // mark action dead and also mark goal dead
        [[[HTDDatabase alloc] init] markLastActionAndGoalDead:action];
        
        // update the actions in this view controller !!!
        self.activeActions = [[[HTDDatabase alloc] init] selectActionsWithStatus:1];

        [self refreshTable];
        
        // activate red dot on dead view
        [self showRedDotOnDeadTab];
    }
    
//    cell.timeLeft.frame = CGRectMake(cell.imageView.frame.origin.x, cell.imageView.frame.origin.y - cell.timeLeft.frame.size.height, cell.imageView.frame.size.width, cell.timeLeft.frame.size.height);
    cell.timeLeft.textAlignment = NSTextAlignmentCenter;
    
    
    cell.nextActionButton.tag = indexPath.row;
    [cell.nextActionButton addTarget:self action:@selector(nextActionButton:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    HTDAction *action = [[HTDAction alloc] init];
    action = self.activeActions[indexPath.row];
    
    [self performSegueWithIdentifier:@"showGoalDetail" sender:action];
}


- (void)refreshTable {
    // this may be too heavy to process
//    self.activeActions = [[[HTDDatabase alloc] init] selectActionsWithStatus:1];

    [self.tableView reloadData];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    // load the NIB file
    UINib *nib = [UINib nibWithNibName:@"HTDGoalCell" bundle:nil];
    
    // register this NIB, which contains the cell
    [self.tableView registerNib:nib forCellReuseIdentifier:@"HTDGoalCell"];
    
    // reload tableview every 10 min to update the timeleft
    [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(refreshTable) userInfo:nil repeats:YES];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.activeActions = [[[HTDDatabase alloc] init] selectActionsWithStatus:1];
    
    if ([self.activeActions count] > 0) {
        [self removeDefaultViewController];
    }
    
    // remove empty cells
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    [self.tableView reloadData];
    
    [self hideRedDotOnActiveTab];
    
}

- (void)HTDNewGoalViewController:(HTDNewGoalViewController *)controller didAddGoal:(HTDAction *)action {
    // Insert action to database
    [[[HTDDatabase alloc] init] insertNewAction:action];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)HTDNewGoalViewControllerDidCancel:(HTDNewGoalViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"addNewGoal"]) {
        
        UINavigationController *navigationController = segue.destinationViewController;
        HTDNewGoalViewController *newGoalViewController = [navigationController viewControllers][0];
        newGoalViewController.delegate = self;
    } else if ([segue.identifier isEqualToString:@"showGoalDetail"]) {
        // segue: show segue
        
        if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
            // works for iOS 7
            HTDGoalDetailViewController *goalDetailViewController = segue.destinationViewController;
            HTDAction *action = sender;
            goalDetailViewController.goalID = action.goal_id;
        } else {
        
        // works for iOS 8
            UINavigationController *navigationController = segue.destinationViewController;
            HTDGoalDetailViewController *goalDetailViewController = (HTDGoalDetailViewController *)navigationController.topViewController;
            HTDAction *action = sender;
            goalDetailViewController.goalID = action.goal_id;
        }
    } else if ([segue.identifier isEqualToString:@"addNextAction"]) {
        // segue: modally segue
        UINavigationController *navigationController = segue.destinationViewController;
        
        HTDNextActionViewController *nextActionViewController = (HTDNextActionViewController *)navigationController.topViewController;
        HTDAction *action = sender;
        nextActionViewController.delegate = self;
        nextActionViewController.goalID = action.goal_id;
    }
}


- (void)showRedDotOnDeadTab {
    UITabBarController *tabBarController = self.tabBarController;
    CGRect tabFrame = tabBarController.tabBar.frame;
    
    CGFloat x = ceilf(0.87 * tabFrame.size.width);
    CGFloat y = ceilf(0.1 * tabFrame.size.height);
    
    UIImageView *dotImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Dot"]];
    
    dotImage.backgroundColor = [UIColor clearColor];
    
    dotImage.frame = CGRectMake(x, y, 9, 9);
    
    dotImage.tag = 87;
    
    [tabBarController.tabBar addSubview:dotImage];
}


- (void)hideRedDotOnActiveTab {
    UIView *viewToRemove = [self.tabBarController.tabBar viewWithTag:20];
    if (viewToRemove) {
        [viewToRemove removeFromSuperview];
        [self hideRedDotOnActiveTab];
    }
}


- (void)showRedDotOnDoneTab:(HTDNextActionViewController *)controller {
    UITabBarController *tabBarController = self.tabBarController;
    CGRect tabFrame = tabBarController.tabBar.frame;
    
    CGFloat x = ceilf(0.53 * tabFrame.size.width);
    CGFloat y = ceilf(0.1 * tabFrame.size.height);
    
    UIImageView *dotImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Dot"]];
    
    dotImage.backgroundColor = [UIColor clearColor];
    
    dotImage.frame = CGRectMake(x, y, 9, 9);
    
    dotImage.tag = 53;
    
    [tabBarController.tabBar addSubview:dotImage];
    
    [self dismissViewControllerAnimated:YES completion:nil];

}

@end
