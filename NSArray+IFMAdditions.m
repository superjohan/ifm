//
//  NSArray+IFMAdditions.m
//  IFM
//
//  Created by Johan Halin on 2/22/12.
//  Copyright (c) 2012 Aero Deko. All rights reserved.
//

#import "NSArray+IFMAdditions.h"

@implementation NSArray (IFMAdditions)

- (id)objectAtIndexOrNil:(NSUInteger)index
{
	if (index >= self.count)
	{
		return nil;
	}
	
	return [self objectAtIndex:index];
}

@end
