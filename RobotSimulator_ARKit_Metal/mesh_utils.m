//
//  mesh_utils.m
//  RobotSimulator_ARKit_Metal
//
//  Created by Andrew Holbrook on 12/16/17.
//  Copyright © 2017 Andrew Holbrook. All rights reserved.
//

#import "mesh_utils.h"

#import <Foundation/Foundation.h>
#import <ModelIO/ModelIO.h>

NSData * GetFlattenedVertexPositionAndNormalData(MDLMesh *mesh) {
    const unsigned int COMPONENTS_PER_VERTEX_IN = 3;
    const unsigned int COMPONENTS_PER_VERTEX_OUT = 4;
    NSMutableData *data = [[NSMutableData alloc] initWithLength:GetTotalIndexCount(mesh) * sizeof(float) * COMPONENTS_PER_VERTEX_OUT * 2];
    float *data_dst_ptr = (float *)data.bytes;
    
    @autoreleasepool {
        MDLMeshBufferMap *positionMap = [mesh.vertexBuffers[0] map];
        float *data_src_ptr = (float *)positionMap.bytes;
        
        // all indices are stored as 32-bit integers
        for (MDLSubmesh *submesh in mesh.submeshes) {
            MDLMeshBufferMap *indexMap = [submesh.indexBuffer map];
            uint32_t *index_ptr = indexMap.bytes;
            for (int i = 0; i < submesh.indexCount; i += 3) {
                simd_float3 u = simd_make_float3(data_src_ptr[index_ptr[i] * COMPONENTS_PER_VERTEX_IN],
                                                 data_src_ptr[index_ptr[i] * COMPONENTS_PER_VERTEX_IN + 1],
                                                 data_src_ptr[index_ptr[i] * COMPONENTS_PER_VERTEX_IN + 2]);
                simd_float3 v = simd_make_float3(data_src_ptr[index_ptr[i + 1] * COMPONENTS_PER_VERTEX_IN],
                                                 data_src_ptr[index_ptr[i + 1] * COMPONENTS_PER_VERTEX_IN + 1],
                                                 data_src_ptr[index_ptr[i + 1] * COMPONENTS_PER_VERTEX_IN + 2]);
                simd_float3 w = simd_make_float3(data_src_ptr[index_ptr[i + 2] * COMPONENTS_PER_VERTEX_IN],
                                                 data_src_ptr[index_ptr[i + 2] * COMPONENTS_PER_VERTEX_IN + 1],
                                                 data_src_ptr[index_ptr[i + 2] * COMPONENTS_PER_VERTEX_IN + 2]);
                simd_float3 normal = simd_normalize(simd_cross(v - u, w - v));
                
                data_dst_ptr[0] = u[0]; data_dst_ptr[1] = u[1]; data_dst_ptr[2] = u[2]; data_dst_ptr[3] = 1.0f;
                data_dst_ptr[4] = normal[0]; data_dst_ptr[5] = normal[1]; data_dst_ptr[6] = normal[2]; data_dst_ptr[7] = 0.0f;
                
                data_dst_ptr[8] = v[0]; data_dst_ptr[9] = v[1]; data_dst_ptr[10] = v[2]; data_dst_ptr[11] = 1.0f;
                data_dst_ptr[12] = normal[0]; data_dst_ptr[13] = normal[1]; data_dst_ptr[14] = normal[2]; data_dst_ptr[15] = 0.0f;
                
                data_dst_ptr[16] = w[0]; data_dst_ptr[17] = w[1]; data_dst_ptr[18] = w[2]; data_dst_ptr[19] = 1.0f;
                data_dst_ptr[20] = normal[0]; data_dst_ptr[21] = normal[1]; data_dst_ptr[22] = normal[2]; data_dst_ptr[23] = 0.0f;
                
                data_dst_ptr += 24;
            }
        }
    }
    
    return data;
}

unsigned int GetTotalIndexCount(MDLMesh *mesh) {
    unsigned int totalIndexCount = 0;
    for (MDLSubmesh *submesh in mesh.submeshes) {
        totalIndexCount += submesh.indexCount;
    }
    
    return totalIndexCount;
}
