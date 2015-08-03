//
//  PopupViewAnimate.h
//  SlideShow
//
//  Created by Hung Cao Thanh on 5/9/15.
//  Copyright (c) 2015 HungCao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PopupViewAnimate : NSObject

+(PopupViewAnimate *) shareInstance;
-(void) showView:(UIView *) showedView inView:(UIView *) superView;
-(void) removeView:(UIView *) removedView withCompletionBlock:(void (^)(BOOL finished)) completionBlock;
@end
