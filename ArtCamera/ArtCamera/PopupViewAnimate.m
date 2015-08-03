//
//  PopupViewAnimate.m
//  SlideShow
//
//  Created by Hung Cao Thanh on 5/9/15.
//  Copyright (c) 2015 HungCao. All rights reserved.
//

#import "PopupViewAnimate.h"

@implementation PopupViewAnimate

+(PopupViewAnimate *) shareInstance{
    static PopupViewAnimate *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,^{
        sharedInstance = [[PopupViewAnimate alloc] init];
    });
    return sharedInstance;
}


-(void)showView:(UIView *)showedView inView:(UIView *)superView{
    CATransform3D transform = CATransform3DMakeScale(0.1, 0.1, 0.1);
    showedView.layer.transform = transform;
    
    [UIView animateWithDuration:0.3 animations:^{
        [superView addSubview:showedView];
        showedView.alpha = 1.0;
        showedView.layer.transform = CATransform3DMakeScale(1.05, 1.05, 1.05);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 animations:^{
            showedView.layer.transform = CATransform3DMakeScale(0.95, 0.95, 0.95);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.2 animations:^{
                showedView.layer.transform = CATransform3DIdentity;
            }];
        }];
    }];
}

-(void)removeView:(UIView *)removedView withCompletionBlock:(void (^)(BOOL))completionBlock{
    [UIView animateWithDuration:0.2 animations:^{
        removedView.alpha = 0.0;
        removedView.layer.transform = CATransform3DMakeScale(0.1, 0.1, 0.1);
    } completion:^(BOOL finished) {
        [removedView removeFromSuperview];
        removedView.layer.transform = CATransform3DIdentity;
        completionBlock(YES);
    }];
}
@end
