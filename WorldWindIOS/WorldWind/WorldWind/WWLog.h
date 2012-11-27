/*
 Copyright (C) 2013 United States Government as represented by the Administrator of the
 National Aeronautics and Space Administration. All Rights Reserved.
 
 @version $Id$
 */

#define WWLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)

#define WWLogE(msg, e) NSLog((@"Exception occurred %@ at %s [Line %d] %@, %@, %@"), msg, __PRETTY_FUNCTION__, __LINE__, [e name], [e reason], [e userInfo])

#define WWEXCEPTION(name, msg) [[NSException alloc] initWithName:name reason:msg userInfo:nil]

#define WWLOG_AND_THROW(name, msg) {WWLog(@"%@", msg); @throw WWEXCEPTION(name, msg);}
