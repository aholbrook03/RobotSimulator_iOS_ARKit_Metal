//
//  Joint.m
//  RobotSimulator_ARKit_Metal
//
//  Created by Andrew Holbrook on 12/6/17.
//  Copyright © 2017 Andrew Holbrook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Joint.h"

@implementation Joint

+ (Joint *)createWithName:(NSString *)name andType:(JointType)type {
    Joint *newJoint = [[Joint alloc] init];
    [newJoint setName:name];
    [newJoint setType:type];
    [newJoint setDirection:0];
    
    return newJoint;
}

@end
