//
//  CommitDiscussesViewController.m
//  Git@OSC
//
//  Created by 李萍 on 15/12/14.
//  Copyright © 2015年 chenhaoxiang. All rights reserved.
//

#import "CommitDiscussesViewController.h"
#import "Tools.h"
#import "AFHTTPRequestOperationManager+Util.h"
#import "GITAPI.h"
#import "GLComment.h"
#import "NoteCell.h"

#import "MJRefresh.h"
#import "DataSetObject.h"

@interface CommitDiscussesViewController ()

@property (nonatomic, strong) NSMutableArray *comments;
@property (nonatomic,strong) DataSetObject *emptyDataSet;
@property (nonatomic, assign) NSInteger page;

@end

@implementation CommitDiscussesViewController

static NSString * const NoteCellId = @"NoteCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"评论";
    _comments = [NSMutableArray new];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    UIView *footer =[[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.tableFooterView = footer;
    
    //下拉刷新
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [self fetchForDiscuss:YES];
    }];
    //上拉刷新
    self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
        [self fetchForDiscuss:NO];
    }];
    [(MJRefreshAutoNormalFooter *)self.tableView.mj_footer setTitle:@"已全部加载完毕" forState:MJRefreshStateNoMoreData];
    // 默认先隐藏footer
    self.tableView.mj_footer.hidden = YES;
    _page = 1;

    [self.tableView registerClass:[NoteCell class] forCellReuseIdentifier:NoteCellId];
    [self fetchForDiscuss:YES];
    
    self.emptyDataSet = [[DataSetObject alloc]initWithSuperScrollView:self.tableView];
    __weak CommitDiscussesViewController *weakSelf = self;
    self.emptyDataSet.reloading = ^{
        [weakSelf fetchForDiscuss:YES];
    };
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -获取数据
- (void)fetchForDiscuss:(BOOL)refresh
{
    self.emptyDataSet.state = loadingState;
    
    if (refresh) {
        _page = 1;
    } else {
        _page++;
    }
    
    NSString *strUrl = [NSString stringWithFormat:@"%@%@/%@/repository/commits/%@/comment", GITAPI_HTTPS_PREFIX,
                                                                                            GITAPI_PROJECTS,
                                                                                            _projectNameSpace,
                                                                                            _commitID];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                      @"projectid"     : @(_projectID),
                                                                                      @"page"           : @(_page),
                                                                                      @"private_token" : [Tools getPrivateToken]
                                                                                      }];
    
    if ([Tools getPrivateToken].length == 0) {
        [parameters removeObjectForKey:@"private_token"];
    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager GitManager];
    
    [manager GET:strUrl
      parameters:parameters
         success:^(AFHTTPRequestOperation * operation, id responseObject) {
             if (refresh) {
                 [_comments removeAllObjects];
             }
             
             if ([responseObject count] == 0) { } else {
                 [responseObject enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL * _Nonnull stop) {
                     GLComment *comment = [[GLComment alloc] initWithJSON:obj];
                     
                     [_comments addObject:comment];
                 }];
             }
             
             if (_comments.count < 20) {
                 [self.tableView.mj_footer endRefreshingWithNoMoreData];
             } else {
                 [self.tableView.mj_footer endRefreshing];
             }
             
             if (_comments.count == 0) {
                 self.emptyDataSet.state = noDataState;
                 self.emptyDataSet.respondString = @"还没有评论";
             }
             dispatch_async(dispatch_get_main_queue(), ^{
                 [self.tableView.mj_header endRefreshing];
                 [self.tableView reloadData];
             });
         } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
             dispatch_async(dispatch_get_main_queue(), ^{
                 self.emptyDataSet.state = netWorkingErrorState;
                 [self.tableView reloadData];
                 [self.tableView.mj_header endRefreshing];
                 [self.tableView.mj_footer endRefreshing];
             });
    }];
    
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _comments.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_comments.count > 0) {
        GLComment *comment = _comments[indexPath.row];
        UILabel *label = [UILabel new];
        label.numberOfLines = 0;
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.font = [UIFont systemFontOfSize:16];
        label.text = [Tools flattenHTML:comment.noteString];
        
        CGSize size = [label sizeThatFits:CGSizeMake(tableView.frame.size.width - 8, MAXFLOAT)];
        
        return size.height + 54;
    }
    return 60;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_comments.count > 0) {
        NoteCell *cell = [tableView dequeueReusableCellWithIdentifier:NoteCellId forIndexPath:indexPath];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        GLComment *comment = _comments[indexPath.row];
        [cell contentForProjectsComment:comment];
        
        return cell;
    }
    return [UITableViewCell new];
}

@end
