/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "ViewController.h"
#import "WorldWind.h"
#import "WorldWind/WorldWindView.h"
#import "WorldWind/Layer/WWBMNGLandsatCombinedLayer.h"
#import "WorldWind/Layer/WWBMNGLayer.h"
#import "WorldWind/Layer/WWLayerList.h"
#import "WorldWind/Render/WWSceneController.h"

@interface ViewController ()
@end

@implementation ViewController

- (void) loadView
{
    self.view = [[UIView alloc] init];
    
    [self createWorldWindView];
    [self layout];
}

- (void) createWorldWindView
{
    _wwv = [[WorldWindView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    if (_wwv == nil)
    {
        NSLog(@"Unable to create a WorldWindView");
        return;
    }
    
    [self.view addSubview:_wwv];
}

- (void) layout
{
    NSDictionary* viewsDictionary = NSDictionaryOfVariableBindings(_wwv);
    
    [_wwv setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    
    [[self view] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_wwv]|" options:0 metrics:nil
                                                                          views:viewsDictionary]];
    [[self view] addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_wwv]|" options:0
                                                                        metrics:nil views:viewsDictionary]];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    WWLog(@"View Did Load. World Wind iOS Version %@", WW_VERSION);
    
    WWLayerList* layers = [[_wwv sceneController] layers];
    
    WWLayer* layer = [[WWBMNGLayer alloc] init];
    [layers addLayer:layer];
}

@end
