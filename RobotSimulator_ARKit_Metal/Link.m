//
//  Link.m
//  RobotSimulator_ARKit_Metal
//
//  Created by Andrew Holbrook on 12/16/17.
//  Copyright © 2017 Andrew Holbrook. All rights reserved.
//

#import "Link.h"
#import <Metal/Metal.h>

@implementation Link 

+ (Link *)createWithName:(NSString *)name AndVertexStart:(unsigned int)vertexStart
          AndVertexCount:(unsigned int)vertexCount AndMTLDevice:(id<MTLDevice>)device {
    Link *newLink = [[Link alloc] init];
    [newLink setName:name];
    [newLink setVertexStart:vertexStart];
    [newLink setVertexCount:vertexCount];
    
    newLink.mvpMatrixBuffer = [device newBufferWithLength:sizeof(float) * 16 options:MTLResourceStorageModeShared];
    newLink.modelMatrixBuffer = [device newBufferWithLength:sizeof(float) * 16 options:MTLResourceStorageModeShared];
    newLink.colorBuffer = [device newBufferWithLength:sizeof(float) * 4 options:MTLResourceStorageModeShared];
    [newLink setColorWithRed:1.0f Green:0.0f Blue:0.0f];
    
    newLink.materialBuffer = [device newBufferWithLength:sizeof(Material) options:MTLResourceStorageModeShared];
    
    return newLink;
}

- (void)setColorWithRed:(float)red Green:(float)green Blue:(float)blue {
    float *color = (float *)self->_colorBuffer.contents;
    color[0] = red; color[1] = green; color[2] = blue; color[3] = 1.0f;
}

@end
