//
//  ProjectsMembersViewController.m
//  Git@OSC
//
//  Created by 李萍 on 15/11/27.
//  Copyright © 2015年 chenhaoxiang. All rights reserved.
//

#import "ProjectsCommitsViewController.h"
#import "ProjectsCommitCell.h"
#import "UIView+Toast.h"
#import "UIColor+Util.h"
#import "Tools.h"
#import "GITAPI.h"
#import "AFHTTPRequestOperationManager+Util.h"
#import "GLCommit.h"
#import "HCDropdownView.h"

#import "MJRefresh.h"

@interface ProjectsCommitsViewController () <HCDropdownViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, assign) int64_t projectID;
@property (nonatomic, copy) NSString *projectNameSpace;
@property (nonatomic, strong) NSMutableArray *commits;
@property (nonatomic, assign) NSInteger page;

@property (nonatomic, assign) BOOL needRefresh;

@property (nonatomic, strong) HCDropdownView *branchTableView;
@property (nonatomic, strong) NSMutableArray *branchs;
@property (nonatomic, assign) NSInteger selectedRow;
@property (nonatomic, assign) BOOL didChangeSelecteItem;
@property (nonatomic) CGPoint origin;
@property (nonatomic, copy) NSString *branchName;

@end

@implementation ProjectsCommitsViewController

static NSString * const cellId = @"ProjectsCommitCell";

- (id)initWithProjectID:(int64_t)projectID  projectNameSpace:(NSString *)nameSpace
{
    self = [super init];
    if (self) {
        _projectID = projectID;
        _projectNameSpace = nameSpace;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _branchs = [NSMutableArray new];
    _branchName = @"master";
    
    _page = 1;
    
    self.navigationItem.title = @"master";
    _commits = [NSMutableArray new];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame)-64)];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
    [self.tableView registerClass:[ProjectsCommitCell class] forCellReuseIdentifier:cellId];
    UIView *footer =[[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.tableFooterView = footer;
    
    [self fetchForCommitDataOnRefresh:YES];
    [self fetchbranchs:@"branches"];
    [self fetchbranchs:@"tags"];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"分支" style:UIBarButtonItemStylePlain target:self action:@selector(clickBranch)];
    
    //下拉刷新
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [self fetchForCommitDataOnRefresh:YES];
    }];
    //上拉刷新
    self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
        [self fetchForCommitDataOnRefresh:NO];
    }];
    [(MJRefreshAutoNormalFooter *)self.tableView.mj_footer setTitle:@"已全部加载完毕" forState:MJRefreshStateNoMoreData];
    // 默认先隐藏footer
    self.tableView.mj_footer.hidden = YES;
    [self.tableView.mj_header beginRefreshing];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 侧栏列表
- (void)initBranchTableView
{
    self.branchTableView = [HCDropdownView dropdownView];
    self.branchTableView.delegate = self;

    self.branchTableView.menuRowHeight = 50;
    self.branchTableView.titles = _branchs;
    self.branchTableView.imageNameStr = @"projectDetails_fork";
    self.branchTableView.menuTabelView.frame = CGRectMake(CGRectGetWidth([[UIScreen mainScreen]bounds])/2, 0, CGRectGetWidth([[UIScreen mainScreen]bounds])/2, MIN(CGRectGetHeight([[UIScreen mainScreen]bounds])/2, self.branchTableView.menuRowHeight * self.branchTableView.titles.count));
    self.branchTableView.menuTabelView.rowHeight = self.branchTableView.menuRowHeight;
    _origin = _branchTableView.menuTabelView.frame.origin;
}

#pragma mark - 分支
- (void)clickBranch
{
    [self initBranchTableView];
    
    BOOL isOpenedState;
    if ([self.branchTableView isOpen]) {
        [self.branchTableView hide];
        isOpenedState = NO;
    }
    else {
        [self.branchTableView showFromNavigationController:self.navigationController menuTabelViewOrigin:_origin];
        isOpenedState = YES;
    }
}

#pragma mark - 获取数据
- (void)fetchForCommitDataOnRefresh:(BOOL)refresh
{
    if (![Tools isNetworkExist]) {
        
        [Tools toastNotification:@"网络连接失败，请检查网络设置" inView:self.view];
        return;
    }
    if (refresh) {
        _page = 1;
    } else {
        _page++;
        _needRefresh = NO;
    }
    
    if (_needRefresh) {
        [_commits removeAllObjects];
    }
    
    [self.view makeToastActivity];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager GitManager];
    
    NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
    NSString *privateToken = [user objectForKey:@"private_token"];
    
    NSString *strUrl;
    if (privateToken.length > 0) {
        strUrl = [NSString stringWithFormat:@"%@%@/%@/repository/commits?private_token=%@&page=%ld&ref_name=%@",
                  GITAPI_HTTPS_PREFIX,
                  GITAPI_PROJECTS,
                  _projectNameSpace,
                  [Tools getPrivateToken],
                  _page,
                  _branchName];
    } else {
        strUrl = [NSString stringWithFormat:@"%@%@/%@/repository/commits?page=%ld&ref_name=%@",
                  GITAPI_HTTPS_PREFIX,
                  GITAPI_PROJECTS,
                  _projectNameSpace,
                  _page,
                  _branchName];
    }


    [manager GET:strUrl
      parameters:nil
         success:^(AFHTTPRequestOperation * operation, id responseObject) {
             [self.view hideToastActivity];
             
             if (refresh) {
                 [_commits removeAllObjects];
             }
             
             if ([responseObject count]) {

                 [responseObject enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL * stop) {
                     GLCommit *commit = [[GLCommit alloc] initWithJSON:obj];
                     [_commits addObject:commit];
                 }];
                 
                 if (_commits.count < 20) {
                     [self.tableView.mj_footer endRefreshingWithNoMoreData];
                 } else {
                     [self.tableView.mj_footer endRefreshing];
                 }
                 
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [self.tableView reloadData];
                     [self.tableView.mj_header endRefreshing];
                 });
                 
             }

         } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
             [self.view hideToastActivity];
             
             if (error != nil) {
                 [Tools toastNotification:[NSString stringWithFormat:@"网络异常，错误码：%ld", (long)error.code] inView:self.view];
             } else {
                 [Tools toastNotification:@"网络错误" inView:self.view];
             }
             dispatch_async(dispatch_get_main_queue(), ^{
                 [self.tableView reloadData];
                 [self.tableView.mj_header endRefreshing];
                 [self.tableView.mj_footer endRefreshing];
             });
             
    }];
}

#pragma mark - 获取分支信息

- (void)fetchbranchs:(NSString *)branch
{
    if (![Tools isNetworkExist]) {
        [Tools toastNotification:@"网络连接失败，请检查网络设置" inView:self.view];
        return;
    }
    
    [self.view makeToastActivity];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager GitManager];
    
    NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
    NSString *privateToken = [user objectForKey:@"private_token"];
    
    NSString *strUrl = privateToken.length ? [NSString stringWithFormat:@"%@%@/%@/repository/%@?private_token=%@", GITAPI_HTTPS_PREFIX, GITAPI_PROJECTS, _projectNameSpace, branch, [Tools getPrivateToken]] : [NSString stringWithFormat:@"%@%@/%@/repository/%@", GITAPI_HTTPS_PREFIX, GITAPI_PROJECTS, _projectNameSpace, branch];
    
    [manager GET:strUrl
      parameters:nil
         success:^(AFHTTPRequestOperation * operation, id responseObject) {
             [self.view hideToastActivity];
             
             if ([responseObject count] == 0) {

             } else {
                 [responseObject enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                     NSString *name = [obj objectForKey:@"name"];
                    
                     [_branchs addObject:name];
                 }];
                 
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [self.tableView reloadData];
                     
                 });
             }

         } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
             [self.view hideToastActivity];
             
             if (error != nil) {
                 [Tools toastNotification:[NSString stringWithFormat:@"网络异常，错误码：%ld", (long)error.code] inView:self.view];
             } else {
                 [Tools toastNotification:@"网络错误" inView:self.view];
             }
             dispatch_async(dispatch_get_main_queue(), ^{

                 [self.tableView reloadData];
        
             });
             
         }];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _commits.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < _commits.count) {
        GLCommit *commit = _commits[indexPath.row];
        UILabel *label = [UILabel new];
        label.numberOfLines = 0;
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.font = [UIFont boldSystemFontOfSize:14];
        label.text = commit.title;
        CGFloat height = [label sizeThatFits:CGSizeMake(tableView.frame.size.width - 68, MAXFLOAT)].height;
        
        return height + 69;
    } else {
        return 60;
    }
    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < _commits.count) {
        ProjectsCommitCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId forIndexPath:indexPath];
        
        GLCommit *commit = _commits[indexPath.row];
        [cell contentForProjectsCommit:commit];
        
        return cell;
    }
    return [UITableViewCell new];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -- HCDropdownViewDelegate
- (void)dropdownViewWillHide:(HCDropdownView *)dropdownView {
    _didChangeSelecteItem = NO;
}
- (void)dropdownViewDidHide:(HCDropdownView *)dropdownView {
    if (_didChangeSelecteItem) {
        _needRefresh = YES;
        _branchName = _branchs[_selectedRow];
        [self fetchForCommitDataOnRefresh:YES];
        
        self.navigationItem.title = _branchName;
        
        [self.tableView reloadData];
    }
}
-(void)didSelectItemAtRow:(NSInteger)row
{
    _didChangeSelecteItem = YES;
    _selectedRow = row;
}

-(void)viewWillDisappear:(BOOL)animated {
    if (self.branchTableView) {
        [self.branchTableView hide];
    }
}

@end
