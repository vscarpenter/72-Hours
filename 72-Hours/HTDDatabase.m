//
//  HTDDatabase.m
//  72-Hours
//
//  Created by Chi on 11/12/14.
//  Copyright (c) 2014 CHI. All rights reserved.
//

#import "HTDDatabase.h"
#import "HTDGoal.h"
#import "HTDAction.h"

@interface HTDDatabase()

@property NSString *databasePath;

@end


@implementation HTDDatabase

- (instancetype)init {
    
    self = [super init];
    
    if (self) {
        //Get the document directory
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        self.databasePath = [documentsDirectory stringByAppendingPathComponent:@"/72Hours.sqlite"];
//        NSLog(@"%@", self.databasePath);
    }
    return self;
}


- (int)selectGoalDeadCount:(int)goalID {
    
    int count = 0;
    FMDatabase *db = [FMDatabase databaseWithPath:self.databasePath];
    
    [db open];
    
    FMResultSet *result = [db executeQuery:@"SELECT dead_count FROM goal WHERE goal.goal_ID = ?", [NSNumber numberWithInt:goalID]];
    while([result next])
    {
        count = [result intForColumn:@"dead_count"];
    }
    [db close];
    return count;

}



- (NSArray *)selectGoalsWithStatus:(int)state {
    NSMutableArray *selectedGoals = [[NSMutableArray alloc] init];
    FMDatabase *db = [FMDatabase databaseWithPath:self.databasePath];
    
    [db open];
    
    FMResultSet *result = [db executeQuery:@"SELECT * FROM goal WHERE status = ? ORDER BY date_end DESC", [NSNumber numberWithInt:state]];
    while([result next])
    {
        HTDGoal *goal = [[HTDGoal alloc] init];
        goal.duration = [result doubleForColumn:@"duration"];
        goal.goal_name = [result stringForColumn:@"name"];
        goal.goal_id = [result intForColumn:@"goal_ID"];
        goal.dead_count = [result intForColumn:@"dead_count"];
        goal.status = [result intForColumn:@"status"];
        [selectedGoals addObject:goal];
    }
    [db close];
    
    return [selectedGoals copy];

}


- (NSArray *)selectActionsWithStatus:(int)state {

    NSMutableArray *selectedActions = [[NSMutableArray alloc] init];
    
    FMDatabase *db = [FMDatabase databaseWithPath:self.databasePath];
    
    [db open];
    
    FMResultSet *result = [db executeQuery:@"SELECT *,(SELECT name FROM goal WHERE goal.goal_ID = action.goal_ID) AS goal_name, (SELECT highlight_indicate FROM goal WHERE goal.goal_ID = action.goal_ID) AS goal_indicator FROM action WHERE status = ? ORDER BY action.date_start DESC", [NSNumber numberWithInt:state]];
    while([result next])
    {
        HTDAction *action = [[HTDAction alloc] init];
        action.date_start = [result dateForColumn:@"date_start"];
        action.date_end = [result dateForColumn:@"date_end"];
        action.action_name = [result stringForColumn:@"name"];
        action.goal_name = [result stringForColumn:@"goal_name"];
        action.action_id = [result intForColumn:@"action_ID"];
        action.goal_id = [result intForColumn:@"goal_ID"];
        action.status = [result intForColumn:@"status"];
        action.highlight_indicate = [result intForColumn:@"goal_indicator"];
        [selectedActions addObject:action];
    }
    [db close];
    
    return [selectedActions copy];
}

- (NSArray *)selectActionsWithGoalID:(int)goalID {
    NSMutableArray *selectedActions = [[NSMutableArray alloc] init];
    
    FMDatabase *db = [FMDatabase databaseWithPath:self.databasePath];
    
    [db open];
    
    // SELECT *, goal.name as goal_name, goal.highlight_indicate FROM action JOIN goal ON action.goal_ID = goal.goal_ID WHERE action.goal_ID = 1 ORDER BY action.date_start DESC
    FMResultSet *result = [db executeQuery:@"SELECT *,(SELECT name FROM goal WHERE goal.goal_ID = ?) AS goal_name, (SELECT highlight_indicate FROM goal WHERE goal.goal_ID = ?) AS goal_indicator from action WHERE goal_ID = ? ORDER BY action.date_start DESC", [NSNumber numberWithInt:goalID], [NSNumber numberWithInt:goalID], [NSNumber numberWithInt:goalID]];
    while([result next])
    {
        HTDAction *action = [[HTDAction alloc] init];
        action.date_start = [result dateForColumn:@"date_start"];
        action.date_end = [result dateForColumn:@"date_end"];
        action.action_name = [result stringForColumn:@"name"];
        action.goal_name = [result stringForColumn:@"goal_name"];
        action.action_id = [result intForColumn:@"action_ID"];
        action.goal_id = [result intForColumn:@"goal_ID"];
        action.status = [result intForColumn:@"status"];
        action.highlight_indicate = [result intForColumn:@"goal_indicator"];
        [selectedActions addObject:action];
    }
    [db close];
    
    return [selectedActions copy];
}



- (NSString *)selectActionNameWithActionID:(int)actionID {
    FMDatabase *db = [FMDatabase databaseWithPath:self.databasePath];
    
    NSString *actionName = @"";
    [db open];
    
    FMResultSet *result = [db executeQuery:@"SELECT name FROM action WHERE action_ID = ?", [NSNumber numberWithInt:actionID]];
    while([result next])
    {
        actionName = [result stringForColumn:@"name"];
    }
    [db close];
    
    return actionName;
}


/*
 
For Date, may need to convert to human-readable format. Currently date is stored in Unix time seconds.
 
*/

- (void)insertNewAction:(HTDAction *)action {
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    FMDatabase *db = [FMDatabase databaseWithPath:self.databasePath];
    
    [db open];
    [db executeUpdate:@"INSERT INTO goal (name,status,dead_count) VALUES (?,?,?)", action.goal_name, [NSNumber numberWithInt:1], [NSNumber numberWithInt:0], nil];
    

    FMResultSet *result = [db executeQuery:@"SELECT goal_ID FROM goal WHERE name = ?",action.goal_name];
    int goal_ID = 0;
    while ([result next]) {
        goal_ID = [result intForColumn:@"goal_ID"];
    }
    
    [db executeUpdate:@"INSERT INTO action (name,goal_ID,status,date_start) VALUES (?,?,?,?)", action.action_name, [NSNumber numberWithInt:goal_ID], [NSNumber numberWithInt:1],[NSDate date], nil];
    
    [db close];
}



- (void)updateNextActionName:(HTDAction *)newNextAction {
        
    FMDatabase *db = [FMDatabase databaseWithPath:self.databasePath];
    
    [db open];
    [db executeUpdate:@"UPDATE action SET name = ? WHERE action_ID = ?", newNextAction.action_name, [NSNumber numberWithInt:newNextAction.action_id]];
    
    [db close];
}


- (void)highlightGoalIndicator:(HTDAction *)action {
    
    FMDatabase *db = [FMDatabase databaseWithPath:self.databasePath];
    
    [db open];
    
    FMResultSet *result = [db executeQuery:@"SELECT goal_ID FROM action WHERE name = ? ORDER BY date_start DESC LIMIT 1", [NSString stringWithString:action.action_name] ] ;
    
    int goal_ID = 0;
    while ([result next]) {
        goal_ID = [result intForColumn:@"goal_ID"];
    }
    
    [db executeUpdate:@"UPDATE goal SET highlight_indicate = ? WHERE goal_ID = ?",[NSNumber numberWithInt:1], [NSNumber numberWithInt:goal_ID]];

    [db close];

}


- (void)unhighlightAllGoalsIndicator {
    
    FMDatabase *db = [FMDatabase databaseWithPath:self.databasePath];
    
    [db open];
//    NSLog(@"Unhighlight all indicators");

    [db executeUpdate:@"UPDATE goal SET highlight_indicate = 0"];
    
    [db close];
    
}


- (void)flipActionStatus:(HTDAction *)action {
    
    FMDatabase *db = [FMDatabase databaseWithPath:self.databasePath];
    
    [db open];
    
    if (action.status) {
        // make action as finished and insert date_end
        [db executeUpdate:@"UPDATE action SET status = ? WHERE action_ID = ?", [NSNumber numberWithInt:0], [NSNumber numberWithInt:action.action_id]];
        [db executeUpdate:@"UPDATE action SET date_end = ? WHERE action_ID = ?", [NSDate date], [NSNumber numberWithInt:action.action_id]];
    } else {
        // make action as active and delete date_end
        [db executeUpdate:@"UPDATE action SET status = ? WHERE action_ID = ?", [NSNumber numberWithInt:1], [NSNumber numberWithInt:action.action_id]];
        [db executeUpdate:@"UPDATE action SET date_end = NULL WHERE action_ID = ?", [NSDate date], [NSNumber numberWithInt:action.action_id]];
    }
    
    [db close];
}

- (void)markGoalAchieved:(int)goalID {
    FMDatabase *db = [FMDatabase databaseWithPath:self.databasePath];
    
    [db open];
    [db executeUpdate:@"UPDATE goal SET status = 0, date_end = ? WHERE goal_ID = ?", [NSDate date], [NSNumber numberWithInt:goalID]];
    
    [db close];
}


- (void)insertNewNextAction:(HTDAction *)action {

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    FMDatabase *db = [FMDatabase databaseWithPath:self.databasePath];
    
    [db open];
    
    [db executeUpdate:@"INSERT INTO action (name,goal_ID,status,date_start) VALUES (?,?,?,?)", action.action_name, [NSNumber numberWithInt:action.goal_id], [NSNumber numberWithInt:1],[NSDate date], nil];
    
    [db close];
}


- (void)markLastActionAndGoalDead:(HTDAction *)action {
    
//    NSLog(@"This is running");
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    FMDatabase *db = [FMDatabase databaseWithPath:self.databasePath];
    
    [db open];
    
    // mark action dead
    [db executeUpdate:@"UPDATE action SET status = 2 WHERE action_ID = ?", [NSNumber numberWithInt:action.action_id]];
    
    // mark last action dead
    [db executeUpdate:@"UPDATE action SET date_end = ? WHERE action_ID = ?", [NSDate date],[NSNumber numberWithInt:action.action_id]];

    // mark goal dead
    [db executeUpdate:@"UPDATE goal SET status = 2, date_end = ? WHERE goal_ID = ?", [NSDate date], [NSNumber numberWithInt:action.goal_id]];
    
    // add dead_count
    [db executeUpdate:@"UPDATE goal SET dead_count = dead_count + 1 WHERE goal_ID = ?", [NSNumber numberWithInt:action.goal_id]];

    [db close];
    
}


- (void)markDeadGoalDeadActionAlive:(HTDAction *)action {
    FMDatabase *db = [FMDatabase databaseWithPath:self.databasePath];
    
    [db open];
    
    
    [db executeUpdate:@"UPDATE goal SET status = 1 WHERE goal_ID = ?", [NSNumber numberWithInt:action.goal_id]];
    
    
    [db executeUpdate:@"UPDATE action SET status = 1, date_start = ? WHERE action_ID = ?", [NSDate date], [NSNumber numberWithInt:action.action_id]];
    
    [db close];

}


- (void)deleteGoalWithActions:(int)goalID {
    FMDatabase *db = [FMDatabase databaseWithPath:self.databasePath];
    
    [db open];
    
    [db executeUpdate:@"DELETE FROM goal WHERE goal_ID = ?", [NSNumber numberWithInt:goalID]];
    [db executeUpdate:@"DELETE FROM action WHERE goal_ID = ?", [NSNumber numberWithInt:goalID]];

    [db close];
}



@end
