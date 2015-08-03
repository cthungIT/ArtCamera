//
//  HCPhoto.h
//  ArtCamera
//
//  Created by Hung Cao Thanh on 5/9/15.
//  Copyright (c) 2015 HungCao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DrawImage.h"

typedef NS_ENUM(NSInteger, HCPhotoState){
    HCPhotoStateNormal,
    HCPhotoStateBig,
    HCPhotoStateDraw,
    HCPhotoStateTogether
};

@class HCPhoto;
@protocol HCPhotoDelegate <NSObject>

-(void) doubleTapOnImage;
-(void) viewAnImage:(HCPhoto *) hcPhoto;
-(void) viewBigImage:(BOOL) isBigImage withHCPhoto:(HCPhoto *) hcPhoto;
@end

@interface HCPhoto : UIView

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) DrawImage *drawView;
@property (nonatomic, assign) float speed;
@property (nonatomic, assign) CGRect oldFrame;
@property (nonatomic, assign) float oldSpeed;
@property (nonatomic, assign) float oldAlpha;
@property (nonatomic, assign) int state;

@property (nonatomic, weak) id<HCPhotoDelegate> delegate;

-(void) updateImage:(UIImage *) image;
-(void) setImageAlphaAndSpeedAndSize:(float) alpha;
- (void)tapImage;
@end
