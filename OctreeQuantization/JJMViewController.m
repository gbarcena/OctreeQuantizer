//
//  JJMViewController.m
//  OctreeQuantization
//
//  Created by Gustavo Barcena on 5/20/14.
//

#import "JJMViewController.h"
@import ImageIO;
@import MobileCoreServices;

#import "ImageHelper.h"
#import "YLGIFImage.h"
#import "YLImageView.h"
#import "OctreeQuantizer.h"

@interface JJMViewController ()
@property (weak, nonatomic) IBOutlet YLImageView *imageView;
@property (weak, nonatomic) IBOutlet YLImageView *imageView2;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@property (nonatomic) CGImageDestinationRef destination;
@property (nonatomic) BOOL shouldQuantize;

@end

@implementation JJMViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.shouldQuantize = YES;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.imageView.image = [YLGIFImage imageNamed:@"leave_me_alone.gif"];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self makeGIF];
}

-(void)makeGIF
{
    NSDate *beginDate = [NSDate date];
    
    NSBundle *bundle = [NSBundle bundleWithPath:[[[ NSBundle mainBundle] bundlePath] stringByAppendingFormat:@"/%@", @"leave_me_alone.bundle"]];
    NSArray *arr = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:bundle.bundlePath
                                                                       error:NULL ];
    NSInteger frameCount = arr.count;
    [self beginWrite:frameCount];
    for ( int i = 0; i < frameCount; i++ ) {
        NSString *fileName = [NSString stringWithFormat:@"%d",i+1];
        NSString *filePath = [bundle pathForResource:fileName ofType:@"png"];
        UIImage *imageToProcess = [UIImage imageWithContentsOfFile:filePath];
        UIImage *newImage;
        
        if (self.shouldQuantize) {
            unsigned char *imageBytes = [ImageHelper convertUIImageToBitmapRGBA8:imageToProcess];
            image_t cImage = {0};
            cImage.w = imageToProcess.size.width;
            cImage.h = imageToProcess.size.height;
            cImage.pix = imageBytes;
            
            color_quant(&cImage, 32, 1);
            newImage = [ImageHelper convertBitmapRGBA8ToUIImage:cImage.pix
                                                      withWidth:imageToProcess.size.width
                                                     withHeight:imageToProcess.size.height];
        }
        else
        {
            newImage = imageToProcess;
        }
        [self writeImage:newImage];
    }
    [self endWrite];
    NSTimeInterval seconds = [[NSDate date] timeIntervalSinceDate:beginDate];
    self.timeLabel.text = [NSString stringWithFormat:@"%f", seconds];
    YLGIFImage *newGIF = [YLGIFImage imageWithContentsOfFile:[self filePath]];
    self.imageView2.image = newGIF;
}

#pragma mark - GIF File properties

// properties to be applied to each frame... such as setting delay time & color map.
- (NSDictionary *)framePropertiesWithFrameDelay:(NSTimeInterval)delay {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:5];
    [dict setObject:@(delay) forKey:(NSString *)kCGImagePropertyGIFDelayTime];
    
    NSDictionary *frameProps = [ NSDictionary dictionaryWithObject: dict
                                                            forKey: (NSString*) kCGImagePropertyGIFDictionary ];
    
    return frameProps;
}

// properties to apply to entire GIF... such as loop count (0 = infinite) and no global color map.
- (NSDictionary *)gifProperties {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:5];
    
    [dict setObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCGImagePropertyGIFLoopCount];
    
    NSDictionary *gifProps = [ NSDictionary dictionaryWithObject: dict
                                                          forKey: (NSString*) kCGImagePropertyGIFDictionary ];
    
    return gifProps;
}

#pragma mark - GIF File Location Methods

-(NSString *)filePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectoryURL = [paths objectAtIndex:0];
    NSString *path = [cacheDirectoryURL  stringByAppendingPathComponent:@"gifs"];
    NSError *error;
    [[NSFileManager defaultManager] createDirectoryAtPath:path
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];
    NSString *fileName = [NSString stringWithFormat:@"happy.gif"];
    NSString *filePath = [path stringByAppendingPathComponent:fileName];
    return filePath;
}

-(NSURL *)fileLocation
{
    NSString *filePath = [self filePath];
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    return fileURL;
}

#pragma mark - GIF writing Methods

-(void)beginWrite:(NSUInteger)frameCount
{
    NSUInteger kFrameCount = frameCount;
    NSDictionary *fileProperties = [self gifProperties];
    NSURL *fileURL = [self fileLocation];
    
    self.destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)fileURL, kUTTypeGIF, kFrameCount, NULL);
    CGImageDestinationSetProperties(self.destination, (__bridge CFDictionaryRef)fileProperties);
}

-(void)writeImage:(UIImage *)image
{
    NSTimeInterval frameDelay = .04;
    NSDictionary *frameProperties = [self framePropertiesWithFrameDelay:frameDelay];
    @autoreleasepool {
        CGImageRef imageRef  = image.CGImage;
        CGImageDestinationAddImage(self.destination, imageRef, (__bridge CFDictionaryRef)frameProperties);
    }
}

-(void)endWrite
{
    if (!CGImageDestinationFinalize(self.destination)) {
        NSLog(@"failed to finalize image destination");
    }
    CFRelease(self.destination);
}


@end
