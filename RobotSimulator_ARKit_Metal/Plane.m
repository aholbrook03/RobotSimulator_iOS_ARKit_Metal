//
//  Plane.m
//  RobotSimulator_ARKit_Metal
//
//  Created by Andrew Holbrook on 12/12/17.
//  Copyright © 2017 Andrew Holbrook. All rights reserved.
//

#include "Plane.h"

@implementation Plane

+ (Plane *)createWithPlaneAnchor:(ARPlaneAnchor *)planeAnchor andMTLDevice:(id<MTLDevice>) device {
    Plane *newPlane = [[Plane alloc] init];
    
    const unsigned int componentsPerVertex = 4;
    const unsigned int numberOfVertices = 6;
    newPlane->_vertexPositionBuffer = [device newBufferWithLength:sizeof(float) * componentsPerVertex * numberOfVertices
                                                          options:MTLResourceStorageModeShared];
    [newPlane setPlaneAnchor:planeAnchor];
    
    // randomize plane's color
    float red = (arc4random() % 256) / 255.0f;
    float green = (arc4random() % 256) / 255.0f;
    float blue = (arc4random() % 256) / 255.0f;
    float color[4] = {red, green, blue, 1.0f};
    newPlane->_vertexColorBuffer = [device newBufferWithBytes:color length:sizeof(float) * 4 options:MTLResourceStorageModeShared];
    
    newPlane->_mvpMatrixBuffer = [device newBufferWithLength:sizeof(float) * 16 options:MTLResourceStorageModeShared];
    
    return newPlane;
}

- (simd_float3)getCenterPosition {
    simd_float4 centerPos = self->_planeAnchor.transform.columns[3] + simd_make_float4(self->_planeAnchor.center, 0.0f);
    return simd_make_float3(centerPos);
}

- (void)setColor:(float[])color {
    memcpy(self->_vertexColorBuffer.contents, color, sizeof(float) * 4);
}

- (void)setPlaneAnchor:(ARPlaneAnchor *)planeAnchor {
    self->_planeAnchor = planeAnchor;
    
    float halfWidth = planeAnchor.extent[0] / 2;
    float halfLength = planeAnchor.extent[2] / 2;
    float centerX = planeAnchor.center[0];
    float centerZ = planeAnchor.center[2];

    float planeVertices[] = {
        centerX + halfWidth, 0.0f, centerZ - halfLength, 1.0f,
        centerX - halfWidth, 0.0f, centerZ + halfLength, 1.0f,
        centerX + halfWidth, 0.0f, centerZ + halfLength, 1.0f,
        centerX - halfWidth, 0.0f, centerZ + halfLength, 1.0f,
        centerX + halfWidth, 0.0f, centerZ - halfLength, 1.0f,
        centerX - halfWidth, 0.0f, centerZ - halfLength, 1.0f
    };
    
    memcpy(self->_vertexPositionBuffer.contents, planeVertices, sizeof(planeVertices));
}

- (void)renderWithRenderEncoder:(id<MTLRenderCommandEncoder>)renderEncoder andVPMatrix:(matrix_float4x4)vpMatrix {
    [renderEncoder setVertexBuffer:self->_vertexPositionBuffer offset:0 atIndex:0];
    
    matrix_float4x4 modelMatrix = self->_planeAnchor.transform;
    matrix_float4x4 mvpMatrix = matrix_multiply(vpMatrix, modelMatrix);
    
    memcpy(self->_mvpMatrixBuffer.contents, mvpMatrix.columns, sizeof(float) * 16);
    [renderEncoder setVertexBuffer:self->_mvpMatrixBuffer offset:0 atIndex:1];
    [renderEncoder setVertexBuffer:self->_vertexColorBuffer offset:0 atIndex:2];
    
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
}

@end
