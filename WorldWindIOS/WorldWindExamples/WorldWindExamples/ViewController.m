/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration.
 All Rights Reserved.
 
 * @version $Id$
 */

#import "ViewController.h"
#import "WorldWind/WorldWindView.h"

@implementation ViewController

- (id) init
{
    return [super initWithNibName:nil bundle:nil];
}

- (void) loadView
{
    self.view = [[WorldWindView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    if (self.view == nil)
    {
        NSLog(@"Unable to create a WorldWindView");
        return;
    }

    self.view.opaque = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    WWLog(@"View Did Load");
    
    [(WorldWindView*) self.view drawView];
}

@end