//
//  Plane.h
//  RobotSimulator_ARKit_Metal
//
//  Created by Andrew Holbrook on 12/12/17.
//  Copyright © 2017 Andrew Holbrook. All rights reserved.
//

#ifndef Plane_h
#define Plane_h

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <ARKit/ARKit.h>

@interface Plane : NSObject {
    ARPlaneAnchor *_planeAnchor;
    id<MTLBuffer> _vertexPositionBuffer;
    id<MTLBuffer> _vertexColorBuffer;
    id<MTLBuffer> _mvpMatrixBuffer;
}

+ (Plane *)createWithPlaneAnchor:(ARPlaneAnchor *)planeAnchor andMTLDevice:(id<MTLDevice>) device;

- (simd_float3)getCenterPosition;
- (void)setPlaneAnchor:(ARPlaneAnchor *)planeAnchor;
- (void)setColor:(float[])color;
- (void)renderWithRenderEncoder:(id<MTLRenderCommandEncoder>)renderEncoder andVPMatrix:(matrix_float4x4)vpMatrix;

@end

#endif /* Plane_h */
