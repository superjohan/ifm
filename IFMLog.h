//
//  IFMLog.h
//  IFM
//
//  Created by Johan Halin on 26.2.2012.
//  Copyright (c) 2012 Aero Deko. All rights reserved.
//

#import <Foundation/Foundation.h>

#define IFMLOG_LOG(levelName, fmt, ...) NSLog((@"%@ [T:0x%x %@] %s:%d " fmt), levelName, (unsigned int)[NSThread currentThread], ([[NSThread currentThread] isMainThread] ? @"M" : @"S"), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)

#ifdef DEBUG
#define IFMLOG_DEBUG(fmt, ...) IFMLOG_LOG(@"DEBUG", fmt, ##__VA_ARGS__)
#else
#define IFMLOG_DEBUG(...)
#endif

#define IFMLOG_INFO(fmt, ...) IFMLOG_LOG(@"INFO", fmt, ##__VA_ARGS__)
