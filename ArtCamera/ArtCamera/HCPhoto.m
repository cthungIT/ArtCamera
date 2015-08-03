//
//  HCPhoto.m
//  ArtCamera
//
//  Created by Hung Cao Thanh on 5/9/15.
//  Copyright (c) 2015 HungCao. All rights reserved.
//

#import "HCPhoto.h"
#import "PopupViewAnimate.h"

@interface HCPhoto ()<UIGestureRecognizerDelegate>{
    UIView *currentShowedView;
}

@end
@implementation HCPhoto
@synthesize delegate;

-(id) initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        //Initialization code
        
        self.backgroundColor = [UIColor blackColor];
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.drawView = [[DrawImage alloc]initWithFrame:self.bounds];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.drawView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:self.drawView];
        [self addSubview:self.imageView];
        
        NSTimer *timer = [NSTimer timerWithTimeInterval:1/10 target:self selector:@selector(movePhotos) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:@"NSDefaultRunLoopMode"];
        
        self.layer.borderWidth = 2;
        self.layer.borderColor = [[UIColor whiteColor] CGColor];
    
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapImage)];
        [tap setNumberOfTapsRequired:1];
        [tap setDelegate:self];
        [self addGestureRecognizer:tap];
        
        /*UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTap)];
        [doubleTap setNumberOfTapsRequired:2];
        [doubleTap setDelegate:self];
        [self addGestureRecognizer:doubleTap];
        [tap requireGestureRecognizerToFail:doubleTap];
        
        [tap setDelaysTouchesBegan:YES];
        [doubleTap setDelaysTouchesBegan:YES];*/
        
        UISwipeGestureRecognizer *swip = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipImage)];
        [swip setDirection:UISwipeGestureRecognizerDirectionLeft | UISwipeGestureRecognizerDirectionRight];
        [self addGestureRecognizer:swip];
    }
    return self;
}

-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    return YES;
}

-(void) doubleTap{
    [UIView animateWithDuration:0.5 animations:^{
        
        if (self.state == HCPhotoStateNormal) {
//            self.oldFrame = self.frame;
//            self.oldAlpha = self.alpha;
//            self.oldSpeed = self.speed;
//            self.frame = CGRectMake(20, 20, self.superview.bounds.size.width - 40, self.superview.bounds.size.height - 40);
//            self.imageView.frame = self.bounds;
//            self.drawView.frame = self.bounds;
//            [self.superview bringSubviewToFront:self];
//            self.speed = 0;
//            self.alpha = 1;
//            self.state = HCPhotoStateBig;
            
            if (delegate && [delegate respondsToSelector:@selector(doubleTapOnImage)]) {
                [delegate doubleTapOnImage];
            }
            
        } else if (self.state == HCPhotoStateBig) {
            self.frame = self.oldFrame;
            self.alpha = self.oldAlpha;
            self.speed = self.oldSpeed;
            self.imageView.frame = self.bounds;
            self.drawView.frame = self.bounds;
            self.state = HCPhotoStateNormal;
        }
        
    }];
}
- (void)tapImage {
    
    [UIView animateWithDuration:0.5 animations:^{
        
        if (self.state == HCPhotoStateNormal) {
            self.oldFrame = self.frame;
            self.oldAlpha = self.alpha;
            self.oldSpeed = self.speed;
            self.frame = CGRectMake(20, 20, self.superview.bounds.size.width - 40, self.superview.bounds.size.height - 40);
            self.imageView.frame = self.bounds;
            self.drawView.frame = self.bounds;
            [self.superview bringSubviewToFront:self];
            self.speed = 0;
            self.alpha = 1;
            self.state = HCPhotoStateBig;
            
            if (delegate && [delegate respondsToSelector:@selector(viewBigImage:withHCPhoto:)]) {
                [delegate viewBigImage:YES withHCPhoto:self];
            }
            
        } else if (self.state == HCPhotoStateBig) {
            self.frame = self.oldFrame;
            self.alpha = self.oldAlpha;
            self.speed = self.oldSpeed;
            self.imageView.frame = self.bounds;
            self.drawView.frame = self.bounds;
            self.state = HCPhotoStateNormal;
            
            if (delegate && [delegate respondsToSelector:@selector(viewBigImage:withHCPhoto:)]) {
                [delegate viewBigImage:NO withHCPhoto:self];
            }
        }else{
            if (self.state == HCPhotoStateTogether) {
                NSLog(@"\nTogether");
                /*self.oldFrame = self.frame;
                self.oldAlpha = self.alpha;
                self.oldSpeed = self.speed;
                self.frame = CGRectMake(20, 20, self.superview.bounds.size.width - 40, self.superview.bounds.size.height - 40);
                self.imageView.frame = self.bounds;
                self.drawView.frame = self.bounds;
                [self.superview bringSubviewToFront:self];
                self.speed = 0;
                self.alpha = 1;
                self.state = HCPhotoStateBig;*/
        
                if (delegate && [delegate respondsToSelector:@selector(viewAnImage:)]) {
                    [delegate viewAnImage:self];
                }
            }
        }
        
    }];
    
}


- (void)swipImage {
    
    if (self.state == HCPhotoStateBig) {
        [self exchangeSubviewAtIndex:0 withSubviewAtIndex:1];
        self.state = HCPhotoStateDraw;
    } else if (self.state == HCPhotoStateDraw){
        [self exchangeSubviewAtIndex:0 withSubviewAtIndex:1];
        self.state = HCPhotoStateBig;
    }
}


- (void)updateImage:(UIImage *)image {
    self.imageView.image = image;
    NSLog(@"image......");
}


- (void)setImageAlphaAndSpeedAndSize:(float)alpha {
    self.alpha = alpha;
    self.speed = alpha/2;
    self.transform = CGAffineTransformScale(self.transform, alpha, alpha);
}

- (void)movePhotos {
    self.center = CGPointMake(self.center.x + self.speed, self.center.y);
    if (self.center.x > self.superview.bounds.size.width + self.frame.size.width/2) {
        self.center = CGPointMake(-self.frame.size.width/2, arc4random()%(int)(self.superview.bounds.size.height - self.bounds.size.height) + self.bounds.size.height/2);
    }
}

@end
