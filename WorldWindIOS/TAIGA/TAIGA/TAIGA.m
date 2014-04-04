/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#import "TAIGA.h"
#import "AppUpdateController.h"
#import "UnitsFormatter.h"

@implementation TAIGA

static AppUpdateController* appUpdateController; // singleton instance
static UnitsFormatter* unitsFormatter;

+ (void) initialize
{
    static BOOL initialized = NO; // protects against erroneous explicit calls to this method

    if (!initialized)
    {
        initialized = YES;

        appUpdateController = [[AppUpdateController alloc] init];
        unitsFormatter = [[UnitsFormatter alloc] init];
    }
}

+ (AppUpdateController*) appUpdateController
{
    return appUpdateController;
}

+ (UnitsFormatter*) unitsFormatter
{
    return unitsFormatter;
}

@end