//
//  Joint.h
//  RobotSimulator_ARKit_Metal
//
//  Created by Andrew Holbrook on 12/6/17.
//  Copyright © 2017 Andrew Holbrook. All rights reserved.
//

#ifndef Joint_h
#define Joint_h

#import "Link.h"

typedef NS_ENUM(NSInteger, JointType) {
    JointTypePrismatic,
    JointTypeRevolute,
    JointTypeUnknown
};

typedef struct {
    float min;
    float max;
} JointLimit;

@interface Joint : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) JointType type;
@property (nonatomic) simd_float3 axis;
@property (nonatomic) simd_float3 position;
@property (nonatomic) float value;
@property (nonatomic) float dvalue;
@property (nonatomic) JointLimit limit;
@property (nonatomic) Link *linkA;
@property (nonatomic) Link *linkB;
@property (nonatomic) int direction;

+ (Joint *)createWithName:(NSString *)name andType:(JointType)type;

@end

#endif /* Joint_h */
