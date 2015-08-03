//
//  MainViewController.m
//  ArtCamera
//
//  Created by Hung Cao Thanh on 5/9/15.
//  Copyright (c) 2015 HungCao. All rights reserved.
//

#import "MainViewController.h"
#import "HCPhoto.h"
#import "PopupViewAnimate.h"
#import <QuartzCore/QuartzCore.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "PopupBackgroundView.h"

//Filter image
#import <INK/INK.h>
#import "AFPhotoEditorController.h"
#import "AFPhotoEditorCustomization.h"
#import "AFOpenGLManager.h"

//end
#define IMAGEWIDTH 120
#define IMAGEHEIGHT 160

@interface MainViewController ()<HCPhotoDelegate, AFPhotoEditorControllerDelegate, UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>{
    UIView *currentViewShowed;
    HCPhoto *currentHCPhoto;
}

@property(nonatomic, strong) NSMutableArray * photos;
@property (nonatomic, strong) IBOutlet UIScrollView *photosView;
@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    currentViewShowed = nil;
    currentHCPhoto = nil;
    
    [self setupAddBarButton];
    
    self.photos = [[NSMutableArray alloc]init];
    NSMutableArray *photoPaths = [[NSMutableArray alloc]init];
    
    NSString *path = [[NSBundle mainBundle] bundlePath];
    
    NSLog(@"path =%@", path);
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSArray *fileNames = [fm contentsOfDirectoryAtPath:path error:nil];
    for (NSString *fileName in fileNames ) {
        if ([fileName hasSuffix:@"jpg"] || [fileName hasSuffix:@"JPG"]) {
            NSString *photoPath = [path stringByAppendingPathComponent:fileName];
            [photoPaths addObject:photoPath];
        }
    }
    
    
    //添加9个图片到界面中
    if (photoPaths) {
        for (int i = 0; i < photoPaths.count; i++) {
            float X = arc4random()%((int)self.view.bounds.size.width - IMAGEWIDTH);
            float Y = arc4random()%((int)self.view.bounds.size.height - IMAGEHEIGHT);
            float W = IMAGEWIDTH;
            float H = IMAGEHEIGHT;
            
            HCPhoto *photo = [[HCPhoto alloc]initWithFrame:CGRectMake(X, Y, W, H)];
            [photo setDelegate:self];
            [photo updateImage:[UIImage imageWithContentsOfFile:photoPaths[i]]];
            [self.photosView addSubview:photo];
            
            float alpha = i*1.0/10 + 0.2;
            [photo setImageAlphaAndSpeedAndSize:alpha];
            
            [self.photos addObject:photo];
        }
    }
    
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTap)];
    [doubleTap setNumberOfTapsRequired:2];
    [self.view addGestureRecognizer:doubleTap];
}

-(void) addNewImage:(UIImage *) image index:(NSInteger) i{
    float X = arc4random()%((int)self.view.bounds.size.width - IMAGEWIDTH);
    float Y = arc4random()%((int)self.view.bounds.size.height - IMAGEHEIGHT);
    float W = IMAGEWIDTH;
    float H = IMAGEHEIGHT;
    
    HCPhoto *photo = [[HCPhoto alloc]initWithFrame:CGRectMake(X, Y, W, H)];
    [photo setDelegate:self];
    [photo updateImage:image];
    [self.photosView addSubview:photo];
    
    float alpha = i*1.0/10 + 0.2;
    [photo setImageAlphaAndSpeedAndSize:alpha];
    
    [self.photos addObject:photo];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)doubleTap {
    
    NSLog(@"DoubleTap...........");
    
    for (HCPhoto *photo in self.photos) {
        if (photo.state == HCPhotoStateDraw || photo.state == HCPhotoStateBig) {
            return;
        }
    }
    
    float W = self.view.bounds.size.width / 3;
    float H = self.view.bounds.size.height / 3;
    
    [UIView animateWithDuration:1 animations:^{
        for (int i = 0; i < self.photos.count; i++) {
            HCPhoto *photo = [self.photos objectAtIndex:i];
            
            if (photo.state == HCPhotoStateNormal) {
                photo.oldAlpha = photo.alpha;
                photo.oldFrame = photo.frame;
                photo.oldSpeed = photo.speed;
                photo.alpha = 1;
                photo.frame = CGRectMake(i%3*W, i/3*H, W, H);
                photo.imageView.frame = photo.bounds;
                photo.drawView.frame = photo.bounds;
                photo.speed = 0;
                photo.state = HCPhotoStateTogether;
                
                //set content size
                [self.photosView setContentSize:CGSizeMake(self.photosView.frame.size.width, photo.frame.size.height + photo.frame.origin.y + 100)];
            } else if (photo.state == HCPhotoStateTogether) {
                photo.alpha = photo.oldAlpha;
                photo.frame = photo.oldFrame;
                photo.speed = photo.oldSpeed;
                photo.imageView.frame = photo.bounds;
                photo.drawView.frame = photo.bounds;
                photo.state = HCPhotoStateNormal;
                
                //Set content size again
                [self.photosView setContentOffset:CGPointMake(0, 0) animated:YES];
                [self.photosView setContentSize:CGSizeMake(self.photosView.frame.size.width, self.photosView.frame.size.height)];
            }
        }
        
    }];
    
}

-(UIView *) copyAView:(HCPhoto *) hcPhoto{
    UIView *view = [[UIView alloc] initWithFrame:hcPhoto.frame];
     [view setFrame:CGRectMake(40, 60, self.view.frame.size.width - 80, self.view.frame.size.height - 120)];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 20, view.frame.size.width - 20, view.frame.size.height - 30)];
    [imageView setContentMode:UIViewContentModeScaleAspectFit];
    [imageView setImage:hcPhoto.imageView.image];
    imageView.center = CGPointMake(view.frame.size.width/2, view.frame.size.height/2);
    [view addSubview:imageView];
    
    //Close button
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeButton setFrame:CGRectMake(view.frame.size.width - 70, 20, 50, 50)];
    [closeButton setImage:[UIImage imageNamed:@"closeIcon"] forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(closePopup) forControlEvents:UIControlEventTouchDown];
    [view addSubview:closeButton];
    
    [view setBackgroundColor:[UIColor colorWithRed:192/255.0 green:192/255.0 blue:192/255.0 alpha:0.8]];
    //end
    return view;
}

#pragma mark - Bar button 
-(void) removePopup{
    if (currentViewShowed) {
        [[PopupViewAnimate shareInstance] removeView:currentViewShowed withCompletionBlock:^(BOOL finished) {
            [UIView animateWithDuration:0.2 animations:^{
                currentViewShowed.alpha = 0;
            } completion:^(BOOL finished) {
                [currentViewShowed removeFromSuperview];
                currentViewShowed = nil;
            }];
        }];
    }
}
-(void) addImageToApp{
    [self removePopup];
    
    UIView *backgroundView = [[PopupBackgroundView alloc] initWithFrame:CGRectMake(40, 60, self.view.frame.size.width - 80, self.view.frame.size.height - 120)];
    backgroundView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    
    //Label
    UILabel *titleView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, backgroundView.frame.size.width, 60)];
    [titleView setTextAlignment:NSTextAlignmentCenter];
    [titleView setText:@"Choose Type Photos"];
    [titleView setBackgroundColor:[UIColor lightGrayColor]];
    [backgroundView addSubview:titleView];
    
    //Other
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 60, backgroundView.frame.size.width, backgroundView.frame.size.height - 60)];
    [tableView setDataSource:self];
    [tableView setDelegate:self];
    [tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    [backgroundView addSubview:tableView];
    
    //set current
    currentViewShowed = backgroundView;
    //Show pop up
    [[PopupViewAnimate shareInstance] showView:backgroundView inView:self.view];
}

-(void) setupAddBarButton{
    UIBarButtonItem *addImageBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addImageToApp)];
    self.navigationItem.rightBarButtonItems = nil;
    self.navigationItem.rightBarButtonItem = addImageBarButton;
}

-(void) filterImage{
    [currentHCPhoto tapImage];
    [self launchEditorWithAsset:nil];
}
-(void) shareImage{
    
}
-(void) setupShareAndFilterImageButtonBar{
    NSMutableArray *arrRightBarItems = [[NSMutableArray alloc] init];
    UIButton *filterImageButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [filterImageButton setImage:[UIImage imageNamed:@"filterIcon"] forState:UIControlStateNormal];
    filterImageButton.frame = CGRectMake(0, 0, 32, 32);
    filterImageButton.showsTouchWhenHighlighted=YES;
    [filterImageButton addTarget:self action:@selector(filterImage) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:filterImageButton];
    [arrRightBarItems addObject:barButtonItem];
    
    UIButton *shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [shareButton setImage:[UIImage imageNamed:@"shareIcon"] forState:UIControlStateNormal];
    shareButton.frame = CGRectMake(0, 0, 32, 32);
    shareButton.showsTouchWhenHighlighted=YES;
    [shareButton addTarget:self action:@selector(shareImage) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barButtonItem2 = [[UIBarButtonItem alloc] initWithCustomView:shareButton];
    [arrRightBarItems addObject:barButtonItem2];
    
    self.navigationItem.rightBarButtonItems = arrRightBarItems;
}
#pragma mark - HCPhotoDelegate

-(void)viewBigImage:(BOOL)isBigImage withHCPhoto:(HCPhoto *)hcPhoto{
    currentHCPhoto = nil;
    currentHCPhoto = hcPhoto;
    if (isBigImage) {//view
        [self setupShareAndFilterImageButtonBar];
    }else{
        //close
        [self setupAddBarButton];
    }
}
-(void)doubleTapOnImage{
    [self doubleTap];
}
-(void) closePopup{
    if (currentViewShowed) {
        [[PopupViewAnimate shareInstance] removeView:currentViewShowed withCompletionBlock:^(BOOL finished) {
            [UIView animateWithDuration:0.2 animations:^(void){
                
                currentViewShowed.alpha = 0.0;
                
            } completion:^(BOOL finished){
                
                [currentViewShowed removeFromSuperview];
                currentViewShowed = nil;
            }];
        }];
        
        //Setup button navigation bar
        [self setupAddBarButton];
        
    }
}
-(void)viewAnImage:(HCPhoto *)hcPhoto{
    
    if (currentViewShowed) {
        [[PopupViewAnimate shareInstance] removeView:currentViewShowed withCompletionBlock:^(BOOL finished) {
            [UIView animateWithDuration:0.2 animations:^(void){
                
                currentViewShowed.alpha = 0.0;
                
            } completion:^(BOOL finished){
                
                [currentViewShowed removeFromSuperview];
                currentViewShowed = nil;
                [self setupAddBarButton];
            }];
        }];
    }else{
        UIView *viewedShow = [self copyAView:hcPhoto];

        currentViewShowed = viewedShow;
        [[PopupViewAnimate shareInstance] showView:viewedShow inView:self.view];
        
        //set up filter and share
        [self setupShareAndFilterImageButtonBar];
    }
    
}


#pragma mark - Photo Editor Launch Methods

- (void) launchEditorWithBlob:(INKBlob *)blob action:(INKAction*)action error:(NSError*)error
{
    //When we're launched via Ink, the left and right nav buttons bring up Ink to take the user
    //back to where they came from, so the language on the buttons should reflect that.
    [AFPhotoEditorCustomization setLeftNavigationBarButtonTitle:kAFLeftNavigationTitlePresetExit];
    [AFPhotoEditorCustomization setRightNavigationBarButtonTitle:kAFRightNavigationTitlePresetDone];
    
    //Constructing the image with the data out of the blob. Pretty darn easy.
    UIImage *photo = [UIImage imageWithData:blob.data];
    
    //Launch the photo editor
    [self launchPhotoEditorWithImage:photo highResolutionImage:nil];
}

- (void) launchEditorWithAsset:(ALAsset *)asset
{
    //When the editor is launched via the edit button, the left button closes the editor but remains in the app,
    //and the right button saves the edited image to the camera roll
    [AFPhotoEditorCustomization setLeftNavigationBarButtonTitle:kAFLeftNavigationTitlePresetCancel];
    [AFPhotoEditorCustomization setRightNavigationBarButtonTitle:kAFRightNavigationTitlePresetSave];
    UIImage * editingResImage = currentHCPhoto.imageView.image;
    UIImage * highResImage = currentHCPhoto.imageView.image;
//    [[StandaloneStatsEmitter sharedEmitter] sendStat:@"editor_pressed" withAdditionalStatistics:nil];
    
    [self launchPhotoEditorWithImage:editingResImage highResolutionImage:highResImage];
}

- (void) saveBlob:(INKBlob *)blob action:(INKAction*)action error:(NSError*)error
{
    //Saving the data to the camera roll
    UIImage *image = [UIImage imageWithData:blob.data];
    [self saveNewUIImage:image];
}

//Takes a UIImage and saves it to the camera roll as the most recent object
- (void) saveNewUIImage:(UIImage*) image{
    //Cần phải lưu cái ảnh mà mình vừa chỉnh sửa lại
    //Và thực hiện load lại sau ở lần sau khi mở app lên.
}

#pragma mark - Photo Editor Creation and Presentation
- (void) launchPhotoEditorWithImage:(UIImage *)editingResImage highResolutionImage:(UIImage *)highResImage
{
    // Initialize the photo editor and set its delegate
    AFPhotoEditorController * photoEditor = [[AFPhotoEditorController alloc] initWithImage:editingResImage];
    [photoEditor setDelegate:self];
    
    // Customize the editor's apperance. The customization options really only need to be set once in this case since they are never changing, so we used dispatch once here.
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self setPhotoEditorCustomizationOptions];
    });
    
    // If a high res image is passed, create the high res context with the image and the photo editor.
    if (highResImage) {
        [self setupHighResContextForPhotoEditor:photoEditor withImage:highResImage];
    }
    
    // Present the photo editor.
    [self presentViewController:photoEditor animated:NO completion:nil];
}


- (void) setupHighResContextForPhotoEditor:(AFPhotoEditorController *)photoEditor withImage:(UIImage *)highResImage
{
    // Capture a reference to the editor's session, which internally tracks user actions on a photo.
    __block AFPhotoEditorSession *session = [photoEditor session];
    
    // Add the session to our sessions array. We need to retain the session until all contexts we create from it are finished rendering.
//    [[self editorSessions] addObject:session];
    
    // Create a context from the session with the high res image.
    AFPhotoEditorContext *context = [session createContextWithImage:highResImage];
    
    __block MainViewController * blockSelf = self;
    
    // Call render on the context. The render will asynchronously apply all changes made in the session (and therefore editor)
    // to the context's image. It will not complete until some point after the session closes (i.e. the editor hits done or
    // cancel in the editor). When rendering does complete, the completion block will be called with the result image if changes
    // were made to it, or `nil` if no changes were made. In this case, we write the image to the user's photo album, and release
    // our reference to the session.
    [context render:^(UIImage *result) {
        if (result) {
            UIImageWriteToSavedPhotosAlbum(result, nil, nil, NULL);
        }
        
//        [[blockSelf editorSessions] removeObject:session];
        
        blockSelf = nil;
        session = nil;
        
    }];
}

#pragma Photo Editor Delegate Methods

// This is called when the user taps "Done" in the photo editor.
- (void) photoEditor:(AFPhotoEditorController *)editor finishedWithImage:(UIImage *)image
{
    BOOL *displayInk = [Ink appShouldReturn] && image;
    //If showing ink, don't animate because Ink will animate up.
    [self dismissViewControllerAnimated:!displayInk completion:^{
        
        [self addNewImage:image index:self.photos.count];
        if (displayInk) {
            //Wait for the view controller to go away so we don't add on top of that while it's closing
            NSData *imageData = UIImagePNGRepresentation(image);
            INKBlob *blob = [INKBlob blobFromData:imageData];
            //We make up a filename. We could lead this off, but we're being a better citizen by adding it.
            blob.filename = @"EditedPhoto.png";
            blob.uti = @"public.png";
            //We're done! Return the data
            [Ink returnBlob:blob];
        } else {
            [self saveNewUIImage:image];
        }
    }];
}

// This is called when the user taps "Cancel" in the photo editor.
- (void) photoEditorCanceled:(AFPhotoEditorController *)editor
{
//    [[StandaloneStatsEmitter sharedEmitter] sendStat:@"cancel_pressed" withAdditionalStatistics:nil];
    
    BOOL *displayInk = [Ink appShouldReturn];
    [self dismissViewControllerAnimated:!displayInk completion:^{
        if (displayInk) {
            //We want to show Ink when we cancel as well to allow the user to go back
            [Ink return];
        }
    }];
}

#pragma mark - Photo Editor Customization

- (void) setPhotoEditorCustomizationOptions
{
    // Set Tool Order
    NSArray * toolOrder = @[kAFEffects, kAFFocus, kAFFrames, kAFStickers, kAFEnhance, kAFOrientation, kAFCrop, kAFAdjustments, kAFSplash, kAFDraw, kAFText, kAFRedeye, kAFWhiten, kAFBlemish, kAFMeme];
    [AFPhotoEditorCustomization setToolOrder:toolOrder];
    
    // Set Custom Crop Sizes
    [AFPhotoEditorCustomization setCropToolOriginalEnabled:NO];
    [AFPhotoEditorCustomization setCropToolCustomEnabled:YES];
    NSDictionary * fourBySix = @{kAFCropPresetHeight : @(4.0f), kAFCropPresetWidth : @(6.0f)};
    NSDictionary * fiveBySeven = @{kAFCropPresetHeight : @(5.0f), kAFCropPresetWidth : @(7.0f)};
    NSDictionary * square = @{kAFCropPresetName: @"Square", kAFCropPresetHeight : @(1.0f), kAFCropPresetWidth : @(1.0f)};
    [AFPhotoEditorCustomization setCropToolPresets:@[fourBySix, fiveBySeven, square]];
    
    // Set Supported Orientations
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        NSArray * supportedOrientations = @[@(UIInterfaceOrientationPortrait), @(UIInterfaceOrientationPortraitUpsideDown), @(UIInterfaceOrientationLandscapeLeft), @(UIInterfaceOrientationLandscapeRight)];
        [AFPhotoEditorCustomization setSupportedIpadOrientations:supportedOrientations];
    }
}


#pragma mark - UITableViewDatasource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 3;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identiferString = @"cellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identiferString];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identiferString];
    }
    
    switch (indexPath.row) {
        case 0:{
            [cell.textLabel setText:@"Camera Photos"];
        }
            break;
        case 1:{
            [cell.textLabel setText:@"Photo Library"];
        }
            break;
        case 2:{
            [cell.textLabel setText:@"Facebook"];
        }break;
        default:
            break;
    }
    
    return cell;
}
#pragma mark - UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self removePopup];
    
    switch (indexPath.row) {
        case 0:
        {
            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
            [picker setDelegate:self];
            [picker setAllowsEditing:YES];
            [picker setSourceType:UIImagePickerControllerSourceTypeCamera];
            
            [self presentViewController:picker animated:YES completion:nil];
            
            
        }
            break;
        case 1:{
            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
            [picker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
            [picker setAllowsEditing:YES];
            [picker setDelegate:self];
            
            [self presentViewController:picker animated:YES completion:nil];
        }
            break;
        case 2:{
            
        }
            break;
        default:
            break;
    }
}

#pragma mark - UIImagePickerControllerDelegate
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    
    [self addNewImage:chosenImage index:self.photos.count];
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}
@end
