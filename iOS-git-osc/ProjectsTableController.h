//
//  ProjectsTableController.h
//  iOS-git-osc
//
//  Created by chenhaoxiang on 14-6-30.
//  Copyright (c) 2014年 chenhaoxiang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProjectsTableController : UITableViewController <UIScrollViewDelegate>

@property NSMutableArray *projectsArray;
@property NSInteger projectsType;
@property NSInteger arrangeType;
@property int64_t userID;
//@property BOOL loadingMore;
- (void) reloadType:(NSInteger)newArrangeType;

@end
