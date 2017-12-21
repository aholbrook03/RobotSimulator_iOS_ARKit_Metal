//
//  mesh_utils.h
//  RobotSimulator_ARKit_Metal
//
//  Created by Andrew Holbrook on 12/16/17.
//  Copyright © 2017 Andrew Holbrook. All rights reserved.
//

#ifndef mesh_utils_h
#define mesh_utils_h

#import <Foundation/Foundation.h>
#import <ModelIO/ModelIO.h>

unsigned int GetTotalIndexCount(MDLMesh *mesh);
NSData * GetFlattenedVertexPositionAndNormalData(MDLMesh *mesh);

#endif /* mesh_utils_h */
