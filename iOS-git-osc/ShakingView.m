//
//  ShakingView.m
//  Git@OSC
//
//  Created by chenhaoxiang on 14-9-19.
//  Copyright (c) 2014年 chenhaoxiang. All rights reserved.
//

#import "ShakingView.h"
#import <CoreMotion/CoreMotion.h>
#import <AudioToolbox/AudioToolbox.h>
#import "NavigationController.h"
#import "GLGitlab.h"
#import "Tools.h"
#import "ProjectCell.h"
#import "ProjectDetailsView.h"

#define accelerationThreshold  0.4

@interface ShakingView ()

@property CMMotionManager *motionManager;
@property SystemSoundID soundID;

@property UILabel *luckMessage;
@property UIView *layer;
@property UIImageView *imageUp;
@property UIImageView *imageDown;
@property UIImageView *sweetPotato;

@property NSString *privateToken;
@property GLProject *project;
@property ProjectCell *projectCell;
@property BOOL shaking;

@end

@implementation ShakingView

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"摇一摇";
    [self.navigationController.navigationBar setTranslucent:NO];
    //self.view.backgroundColor = UIColorFromRGB(0x111111);
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"three_lines"]
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:(NavigationController *)self.navigationController
                                                                            action:@selector(showMenu)];
    [self setLayout];
    
    _motionManager = [CMMotionManager new];
    _motionManager.deviceMotionUpdateInterval = 0.5;
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"shake" ofType:@"wav"];
	AudioServicesCreateSystemSoundID((CFURLRef)CFBridgingRetain([NSURL fileURLWithPath:path]), &_soundID);
    
    
    _privateToken = [Tools getPrivateToken];
}

- (void)viewDidAppear:(BOOL)animated
{
    [_motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue]
                                        withHandler:^(CMDeviceMotion *motion, NSError *error) {
                                            [self motionMethod:motion];
                                        }
     ];
    
    [[GLGitlabApi sharedInstance] fetchLuckMessageSuccess:^(id responseObject) {
                                                                _luckMessage.text = responseObject;
                                                            }
                                                  failure:^(NSError *error) {}];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setLayout
{
    _luckMessage = [UILabel new];
    _luckMessage.backgroundColor = [UIColor whiteColor];
    _luckMessage.font = [UIFont systemFontOfSize:12];
    _luckMessage.numberOfLines = 0;
    _luckMessage.lineBreakMode = NSLineBreakByWordWrapping;
    [self.view addSubview:_luckMessage];
    
    _layer = [UIView new];
    //_layer.backgroundColor = UIColorFromRGB(0x111111);
    [self.view addSubview:_layer];
    
    _sweetPotato = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"shakehideimg_man"]];
    _sweetPotato.contentMode = UIViewContentModeScaleAspectFill;
    [_layer addSubview:_sweetPotato];
    
    _imageUp = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"shake_logo_up"]];
    _imageUp.contentMode = UIViewContentModeScaleAspectFill;
    [_layer addSubview:_imageUp];
    
    _imageDown = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"shake_logo_down"]];
    _imageDown.contentMode = UIViewContentModeScaleAspectFill;
    [_layer addSubview:_imageDown];
    
    _projectCell = [ProjectCell new];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapProjectCell)];
    [_projectCell addGestureRecognizer:tap];
    [_projectCell setHidden:YES];
    [self.view addSubview:_projectCell];
    
    for (UIView *subview in [self.view subviews]) {
        subview.translatesAutoresizingMaskIntoConstraints = NO;
    }
    
    for (UIView *subview in [_layer subviews]) {
        subview.translatesAutoresizingMaskIntoConstraints = NO;
    }
    
    NSDictionary *viewsDict = NSDictionaryOfVariableBindings(_luckMessage, _layer, _sweetPotato, _imageUp, _imageDown, _projectCell);
    
    
    // luckMessage
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[_luckMessage]"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:viewsDict]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-5-[_luckMessage]-5-|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:viewsDict]];
    
    
    // layer
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-80-[_layer(195)]"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:viewsDict]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|->=50-[_layer(168.75)]->=50-|"
                                                                      options:NSLayoutFormatAlignAllCenterX
                                                                      metrics:nil
                                                                        views:viewsDict]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_layer
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.f constant:0.f]];
    
    
    // sweetPotato
    
    [_layer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-60-[_sweetPotato(75)]"
                                                                   options:0
                                                                   metrics:nil
                                                                     views:viewsDict]];
    
    [_layer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-50-[_sweetPotato(56.25)]"
                                                                   options:0
                                                                   metrics:nil
                                                                     views:viewsDict]];
    
    
    // imageUp and imageDown
    
    [_layer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|->=1-[_imageUp(95.25)][_imageDown(95.25)]|"
                                                                      options:NSLayoutFormatAlignAllLeft | NSLayoutFormatAlignAllRight
                                                                      metrics:nil
                                                                        views:viewsDict]];
    
    [_layer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_imageUp(168.75)]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:viewsDict]];
    
    
    // projectCell
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_projectCell]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:viewsDict]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_projectCell]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:viewsDict]];
}

- (void)tapProjectCell
{
    [_motionManager stopDeviceMotionUpdates];
    
    ProjectDetailsView *projectDetails = [[ProjectDetailsView alloc] initWithProjectID:_project.projectId];
    [self.navigationController pushViewController:projectDetails animated:YES];
}

-(void)motionMethod:(CMDeviceMotion *)deviceMotion
{
    if (_shaking) {return;}
    
    _shaking = YES;
    
    CMAcceleration userAcceleration = deviceMotion.userAcceleration;
    if (fabs(userAcceleration.x) > accelerationThreshold ||
        fabs(userAcceleration.y) > accelerationThreshold ||
        fabs(userAcceleration.z) > accelerationThreshold)
    {
        [self shakeAnimation];
        if ([Tools isNetworkExist]) {
            [self requestProject];
        } else {
            [Tools toastNotification:@"网络连接失败，请检查网络设置" inView:self.view];
        }
    }
    
    _shaking = NO;
}

- (void)shakeAnimation
{
    [_projectCell setHidden:YES];
    
    AudioServicesPlaySystemSound(_soundID);
    
    //[self rotate:_layer];
    [self moveImage];
}

- (void)rotate:(UIView *)view
{
    CABasicAnimation *translation = [CABasicAnimation animationWithKeyPath:@"transform"];
    translation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    //view.layer.anchorPoint = CGPointMake(1, 0);
    translation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(-M_PI_4, 0, 0, 100)];
    
    translation.duration = 0.2;
    translation.repeatCount = 2;
    translation.autoreverses = YES;
    
    [view.layer addAnimation:translation forKey:@"translation"];
}

- (void)moveImage
{
    CABasicAnimation *moveUp = [CABasicAnimation animationWithKeyPath:@"position"];
    moveUp.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    moveUp.toValue = [NSValue valueWithCGPoint:CGPointMake(_imageUp.center.x, _imageUp.center.y - 50)];
    moveUp.duration = 0.5;
    moveUp.repeatCount = 1;
    moveUp.autoreverses = YES;
    
    CABasicAnimation *moveDown = [CABasicAnimation animationWithKeyPath:@"position"];
    moveDown.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    moveDown.toValue = [NSValue valueWithCGPoint:CGPointMake(_imageDown.center.x, _imageDown.center.y + 50)];
    moveDown.duration = 0.5;
    moveDown.repeatCount = 1;
    moveDown.autoreverses = YES;
    
    [_imageUp.layer addAnimation:moveUp forKey:@"moveUp"];
    [_imageDown.layer addAnimation:moveDown forKey:@"moveDown"];
}



- (void)requestProject
{
    [[GLGitlabApi sharedInstance] fetchARandomProjectWithPrivateToken:_privateToken
                                                              success:[self successBlock]
                                                              failure:[self failureBlock]];
}

- (GLGitlabSuccessBlock)successBlock
{
    return 

    ^(id responseObject) {
        if (responseObject == nil) {
            [Tools toastNotification:@"红薯跟你开了一个玩笑，没有为你找到项目" inView:self.view];
            return;
        }
        _project = responseObject;
        
        [Tools setPortraitForUser:_project.owner view:_projectCell.portrait cornerRadius:5.0];
        _projectCell.projectNameField.text = [NSString stringWithFormat:@"%@ / %@", _project.owner.name, _project.name];
        _projectCell.projectDescriptionField.text = _project.projectDescription.length > 0? _project.projectDescription: @"暂无项目介绍";
        _projectCell.languageField.text = _project.language ?: @"Unknown";
        _projectCell.forksCount.text = [NSString stringWithFormat:@"%i", _project.forksCount];
        _projectCell.starsCount.text = [NSString stringWithFormat:@"%i", _project.starsCount];
        
        [_projectCell setHidden:NO];
    };
}

- (GLGitlabFailureBlock)failureBlock
{
    return
    
    ^(NSError *error) {
        [Tools toastNotification:@"红薯跟你开了一个玩笑，没有为你找到项目" inView:self.view];
    };
}



@end
