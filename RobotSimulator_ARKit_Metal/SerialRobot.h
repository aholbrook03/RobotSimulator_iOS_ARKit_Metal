//
//  SerialRobot.h
//  RobotSimulator_ARKit_Metal
//
//  Created by Andrew Holbrook on 12/12/17.
//  Copyright © 2017 Andrew Holbrook. All rights reserved.
//

#ifndef SerialRobot_h
#define SerialRobot_h

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <ARKit/ARKit.h>
#import "Joint.h"

@interface SerialRobot : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) simd_float3 position;
@property (nonatomic) float yOrientation;

+ (SerialRobot *)createWithJSON:(NSString *)pathToJSON andMTLDevice:(id<MTLDevice>)device;

- (unsigned int)getNumberOfJoints;
- (Joint *)getJointAtIndex:(int)index;

- (void)moveX:(int)dx;
- (void)moveY:(int)dx;
- (void)moveZ:(int)dx;
- (void)rotateY:(int)dx;

- (void)update:(CFTimeInterval)deltaTime;
- (void)renderWithRenderEncoder:(id<MTLRenderCommandEncoder>)renderEncoder andVPMatrix:(matrix_float4x4)vpMatrix;

@end

#endif /* SerialRobot_h */
