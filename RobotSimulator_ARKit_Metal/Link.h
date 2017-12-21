//
//  Link.h
//  RobotSimulator_ARKit_Metal
//
//  Created by Andrew Holbrook on 12/6/17.
//  Copyright © 2017 Andrew Holbrook. All rights reserved.
//

#ifndef Link_h
#define Link_h

#import <Metal/Metal.h>
#import <ModelIO/ModelIO.h>

typedef struct {
    simd_float4 ambient;
    simd_float4 diffuse;
    simd_float4 specular;
    float shininess;
} Material;

@interface Link: NSObject {
    @public
    Material material;
}

@property (nonatomic) NSString *name;
@property (nonatomic) unsigned int vertexStart;
@property (nonatomic) unsigned int vertexCount;
@property (nonatomic) id<MTLBuffer> mvpMatrixBuffer;
@property (nonatomic) id<MTLBuffer> modelMatrixBuffer;
@property (nonatomic) id<MTLBuffer> colorBuffer;
@property (nonatomic) id<MTLBuffer> materialBuffer;

+ (Link *)createWithName:(NSString *)name AndVertexStart:(unsigned int)vertexStart
          AndVertexCount:(unsigned int)vertexCount AndMTLDevice:(id<MTLDevice>)device;

- (void)setColorWithRed:(float)red Green:(float)green Blue:(float)blue;

@end

#endif /* Link_h */
