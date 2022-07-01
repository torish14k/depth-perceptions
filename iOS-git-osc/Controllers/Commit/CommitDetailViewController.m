//
//  CommitDetailViewController.m
//  Git@OSC
//
//  Created by 李萍 on 15/12/2.
//  Copyright © 2015年 chenhaoxiang. All rights reserved.
//

#import "CommitDetailViewController.h"
#import "GITAPI.h"
#import "Tools.h"
#import "AFHTTPRequestOperationManager+Util.h"
#import "GLDiff.h"
#import "UIColor+Util.h"

#import "DiffHeaderCell.h"

@interface CommitDetailViewController ()

@property (nonatomic, strong) NSMutableArray *commitDiffs;

@end

@implementation CommitDetailViewController

static NSString * const cellId = @"DiffHeaderCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _commitDiffs = [NSMutableArray new];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    UIView *footer =[[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.tableFooterView = footer;
    
    [self fetchForCommitDiff];
    
    [self.tableView registerClass:[DiffHeaderCell class] forCellReuseIdentifier:cellId];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

}

#pragma mark - 获取数据
- (void)fetchForCommitDiff
{
    NSString *strUrl = [NSString stringWithFormat:@"%@%@/%@/repository/commits/%@/diff",
                       GITAPI_HTTPS_PREFIX,
                       GITAPI_PROJECTS,
                       _projectNameSpace,
                       _commit.sha];
    if ([Tools getPrivateToken].length > 0) {
        strUrl = [NSString stringWithFormat:@"%@?private_token=%@", strUrl, [Tools getPrivateToken]];
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager GitManager];
    
    [manager GET:strUrl
      parameters:nil
         success:^(AFHTTPRequestOperation * operation, id responseObject) {
             if ([responseObject count] > 0) {
                 [responseObject enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL * _Nonnull stop) {
                     GLDiff *diff = [[GLDiff alloc] initWithJSON:obj];
                     
                     [_commitDiffs addObject:diff];
                     
                     dispatch_async(dispatch_get_main_queue(), ^{
                         [self.tableView reloadData];
                     });
                 }];
             }
             
         } failure:^(AFHTTPRequestOperation * operation, NSError * error) {
             NSLog(@"%@", error);
    }];
    
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    if (_commitDiffs.count > 0) {
        if (section == 0) {
            return 1;
        }
        return _commitDiffs.count;
    }
    return 10;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        UILabel *label = [UILabel new];
        label.numberOfLines = 0;
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.font = [UIFont boldSystemFontOfSize:16];
        label.text = _commit.title;
        CGFloat height = [label sizeThatFits:CGSizeMake(tableView.frame.size.width - 68, MAXFLOAT)].height;
        
        return height + 69;
    }
    return 60;
}

#pragma mark -- setupHeaderView
-(UIView*)setupHeaderViewWithTitle:(NSString*)title {
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), 35)];
    view.backgroundColor = [UIColor whiteColor];
    UILabel *opusPropertyHeaderLabel = [[UILabel alloc]initWithFrame:CGRectMake(13, 0, CGRectGetWidth(view.frame)-13, CGRectGetHeight(view.frame))];
    opusPropertyHeaderLabel.textColor = [UIColor colorWithHex:0x515151];
    opusPropertyHeaderLabel.font = [UIFont boldSystemFontOfSize:16];
    opusPropertyHeaderLabel.text = title;
    [view addSubview:opusPropertyHeaderLabel];
    
    return view;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 1) {
        NSString *str = [NSString stringWithFormat:@"%lu个文件发生了改变", (unsigned long)_commitDiffs.count];
        return [self setupHeaderViewWithTitle:str];
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 1 || section == 2 || section == 3) {
        return 35;
    }
    return 0.001;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        DiffHeaderCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId forIndexPath:indexPath];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [cell contentForProjectsCommit:_commit];
        
        return cell;
        
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
        
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
        }
        
        cell.backgroundColor = [UIColor uniformColor];
        
        if (_commitDiffs.count > 0) {
            GLDiff *diff = _commitDiffs[indexPath.row];
            NSArray *array = [diff.updatedPath componentsSeparatedByString:@"/"];
            NSString *lastString = array[array.count-1];
            cell.textLabel.textColor = [UIColor colorWithHex:0x515151];
            cell.detailTextLabel.textColor = [UIColor colorWithHex:0xb6b6b6];
            cell.textLabel.text = lastString;
            cell.detailTextLabel.text = [diff.updatedPath substringToIndex:diff.updatedPath.length-lastString.length-1];
        }
        
        return cell;
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
