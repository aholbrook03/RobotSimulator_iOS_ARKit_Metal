//
//  SerialRobot.m
//  RobotSimulator_ARKit_Metal
//
//  Created by Andrew Holbrook on 12/12/17.
//  Copyright © 2017 Andrew Holbrook. All rights reserved.
//

#import "SerialRobot.h"

#import <ModelIO/ModelIO.h>

#import "Joint.h"
#import "Link.h"
#import "mesh_utils.h"

@implementation SerialRobot {
    id<MTLBuffer> _vertexAttributesBuffer;
    NSArray<Joint *> *_joints;
    simd_float3 _velocity;
    float _speed;
    float _yAngularVelocity;
    float _angularSpeed;
}

+ (SerialRobot *)createWithJSON:(NSString *)pathToJSON andMTLDevice:(id<MTLDevice>)device {
    SerialRobot *newRobot = [[SerialRobot alloc] init];
    
    NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:pathToJSON];
    [inputStream open];
    NSJSONSerialization *json = [NSJSONSerialization JSONObjectWithStream:inputStream options:0 error:nil];
    [inputStream close];
    
    [newRobot setName:[json valueForKey:@"name"]];
    [newRobot setPosition:simd_make_float3(0.0f, 0.0f, 0.0f)];
    [newRobot setYOrientation:0.0f];
    
    newRobot->_velocity = simd_make_float3(0.0f, 0.0f, 0.0f);
    newRobot->_speed = 1.0f / 3.0f;
    newRobot->_yAngularVelocity = 0.0f;
    newRobot->_angularSpeed = 360.0f / 3.0f;
    
    NSString *pathtoModelFile = [[NSBundle mainBundle] pathForResource:[json valueForKey:@"model_filename"]
                                                     ofType:[json valueForKey:@"model_file_extension"]];
    NSURL *pathFileURL = [NSURL URLWithString:pathtoModelFile];
    
    MDLAsset *scaraModel = [[MDLAsset alloc] initWithURL:pathFileURL];
    MDLMesh *scaraMesh = (MDLMesh *)[scaraModel objectAtIndex:0];
    
    NSData *vertexPositionData = GetFlattenedVertexPositionAndNormalData(scaraMesh);
    newRobot->_vertexAttributesBuffer = [device newBufferWithBytes:vertexPositionData.bytes length:vertexPositionData.length options:MTLResourceStorageModeShared];
    
    [newRobot _setupJoints:json AndMesh:scaraMesh AndMTLDevice:(id<MTLDevice>)device];
    
    return newRobot;
}

- (unsigned int)getNumberOfJoints {
    return (unsigned int)self->_joints.count;
}

- (Joint *)getJointAtIndex:(int)index {
    return self->_joints[index];
}

- (void)moveX:(int)dx {
    self->_velocity[0] = dx * self->_speed;
}

- (void)moveY:(int)dy {
    self->_velocity[1] = dy * self->_speed;
}

- (void)moveZ:(int)dz {
    self->_velocity[2] = dz * self->_speed;
}

- (void)rotateY:(int)dAy {
    self->_yAngularVelocity = dAy * self->_angularSpeed;
}

- (void)update:(CFTimeInterval)deltaTime {
    self->_position += self->_velocity * deltaTime;
    self->_yOrientation += self->_yAngularVelocity * deltaTime;
    while (self->_yOrientation >= 360.0f) { self->_yOrientation -= 360.0f; }
    while (self->_yOrientation < 0) { self->_yOrientation += 360.0f; }
    
    for (Joint *joint in self->_joints) {
        joint.value = fmax(joint.limit.min, fmin(joint.limit.max, joint.value + joint.direction * joint.dvalue * deltaTime));
    }
}

- (void)renderWithRenderEncoder:(id<MTLRenderCommandEncoder>)renderEncoder andVPMatrix:(matrix_float4x4)vpMatrix {
    [renderEncoder setVertexBuffer:self->_vertexAttributesBuffer offset:0 atIndex:0];
    
    matrix_float4x4 modelMatrix = simd_matrix4x4(simd_quaternion(self->_yOrientation * (float)M_PI / 180.0f, simd_make_float3(0.0f, 1.0f, 0.0f)));
    modelMatrix.columns[3] = simd_make_float4(self.position, 1.0f);
    
    matrix_float4x4 mvpMatrix = matrix_multiply(vpMatrix, modelMatrix);
    memcpy(self->_joints[0].linkA.mvpMatrixBuffer.contents, mvpMatrix.columns, sizeof(float) * 16);
    [renderEncoder setVertexBuffer:self->_joints[0].linkA.mvpMatrixBuffer offset:0 atIndex:1];
    
    memcpy(self->_joints[0].linkA.modelMatrixBuffer.contents, modelMatrix.columns, sizeof(float) * 16);
    [renderEncoder setVertexBuffer:self->_joints[0].linkA.modelMatrixBuffer offset:0 atIndex:2];
    
    memcpy(self->_joints[0].linkA.materialBuffer.contents, &self->_joints[0].linkA->material, sizeof(Material));
    [renderEncoder setFragmentBuffer:self->_joints[0].linkA.materialBuffer offset:0 atIndex:1];
    
    // render the first link
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:self->_joints[0].linkA.vertexStart
                      vertexCount:self->_joints[0].linkA.vertexCount];
    
    // render remaining links
    for (Joint *joint in self->_joints) {
        matrix_float4x4 jointModelMatrix = matrix_identity_float4x4;
        if (joint.type == JointTypeRevolute) {
            jointModelMatrix = simd_matrix4x4(simd_quaternion(joint.value * (float)M_PI / 180.0f, joint.axis));
        } else if (joint.type == JointTypePrismatic) {
            jointModelMatrix.columns[3] += simd_make_float4(joint.axis, 0.0f) * joint.value;
        }
        
        jointModelMatrix.columns[3] += simd_make_float4(joint.position, 0.0f);
        
        mvpMatrix = matrix_multiply(mvpMatrix, jointModelMatrix);
        memcpy(joint.linkB.mvpMatrixBuffer.contents, mvpMatrix.columns, sizeof(float) * 16);
        [renderEncoder setVertexBuffer:joint.linkB.mvpMatrixBuffer offset:0 atIndex:1];
        
        modelMatrix = matrix_multiply(modelMatrix, jointModelMatrix);
        memcpy(joint.linkB.modelMatrixBuffer.contents, modelMatrix.columns, sizeof(float) * 16);
        [renderEncoder setVertexBuffer:joint.linkB.modelMatrixBuffer offset:0 atIndex:2];
        
        memcpy(joint.linkB.materialBuffer.contents, &joint.linkB->material, sizeof(Material));
        [renderEncoder setFragmentBuffer:joint.linkB.materialBuffer offset:0 atIndex:1];
        
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:joint.linkB.vertexStart
                          vertexCount:joint.linkB.vertexCount];
    }
}

- (void)_setupJoints:(NSJSONSerialization *)json AndMesh:(MDLMesh *)mesh AndMTLDevice:(id<MTLDevice>)device {
    NSMutableArray<Joint *> *joints = [[NSMutableArray alloc] init];
    NSMutableDictionary<NSString *, Link *> *linkDict = [[NSMutableDictionary alloc] init];
    
    unsigned int vertexStart = 0;
    for (MDLSubmesh *submesh in mesh.submeshes) {
        unsigned int vertexCount = (unsigned int)submesh.indexCount;
        Link *newLink = [Link createWithName:submesh.name AndVertexStart:vertexStart
                              AndVertexCount:vertexCount AndMTLDevice:device];
        
        newLink->material.ambient = simd_make_float4(0.0f, 0.25f, 0.25f, 1.0f);
        newLink->material.diffuse = simd_make_float4(0.0f, 0.4f, 0.4f, 1.0f);
        newLink->material.specular = simd_make_float4(0.0f, 0.774597f, 0.774597f, 1.0f);
        newLink->material.shininess = 128.0f * 0.6f;
        
        [linkDict setObject:newLink forKey:newLink.name];
        
        vertexStart += submesh.indexCount;
    }
    
    for (id joint in [json valueForKey:@"joints"]) {
        NSString *name = [joint valueForKey:@"name"];
        NSString *typeStr = [joint valueForKey:@"type"];
        JointType type;
        if ([typeStr isEqualToString:@"revolute"]) {
            type = JointTypeRevolute;
        } else if ([typeStr isEqualToString:@"prismatic"]) {
            type = JointTypePrismatic;
        } else {
            type = JointTypeUnknown;
        }
        
        simd_float3 axis;
        axis[0] = ((NSNumber *)[joint valueForKey:@"axis"][0]).floatValue;
        axis[1] = ((NSNumber *)[joint valueForKey:@"axis"][1]).floatValue;
        axis[2] = ((NSNumber *)[joint valueForKey:@"axis"][2]).floatValue;
        
        JointLimit jointLimit;
        jointLimit.min = ((NSNumber *)[joint valueForKey:@"limit_min"]).floatValue;
        jointLimit.max = ((NSNumber *)[joint valueForKey:@"limit_max"]).floatValue;
        
        simd_float3 position;
        position[0] = ((NSNumber *)[joint valueForKey:@"position"][0]).floatValue;
        position[1] = ((NSNumber *)[joint valueForKey:@"position"][1]).floatValue;
        position[2] = ((NSNumber *)[joint valueForKey:@"position"][2]).floatValue;
        
        Link *linkA = [linkDict valueForKey:[joint valueForKey:@"link_a"]];
        Link *linkB = [linkDict valueForKey:[joint valueForKey:@"link_b"]];
        
        float value = ((NSNumber *)[joint valueForKey:@"value"]).floatValue;
        float dvalue = ((NSNumber *)[joint valueForKey:@"dvalue"]).floatValue;
        
        Joint *newJoint = [Joint createWithName:name andType:type];
        [newJoint setAxis:axis];
        [newJoint setLimit:jointLimit];
        [newJoint setPosition:position];
        [newJoint setLinkA:linkA];
        [newJoint setLinkB:linkB];
        [newJoint setValue:value];
        [newJoint setDvalue:dvalue];
        
        [joints addObject:newJoint];
    }
    
    self->_joints = joints;
}

@end
