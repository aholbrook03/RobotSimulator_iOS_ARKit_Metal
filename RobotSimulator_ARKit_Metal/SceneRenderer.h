//
//  SceneRenderer.h
//  RobotSimulator_ARKit_Metal
//
//  Created by Andrew Holbrook on 12/9/17.
//  Copyright © 2017 Andrew Holbrook. All rights reserved.
//

#ifndef SceneRenderer_h
#define SceneRenderer_h

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <ARKit/ARKit.h>
#import "MTLView.h"
#import "Plane.h"
#import "SerialRobot.h"

@interface SceneRenderer : NSObject

@property (nonatomic, weak) MTLView *view;
@property (nonatomic) MTLViewport viewport;

+ (SceneRenderer *)createWithView:(MTLView *)view;

- (void)addPlane:(ARPlaneAnchor *)planeAnchor;
- (void)updatePlane:(ARPlaneAnchor *)planeAnchor;
- (Plane *)getPlaneByIdentifier:(NSUUID *)identifier;
- (Plane *)getSelectedPlane;
- (BOOL)isPlaneSelected;
- (void)selectPlaneByIdentifier:(NSUUID *)identifier;
- (SerialRobot *)getRobot;
- (void)render;
- (void)renderWithARFrame:(ARFrame *)arFrame;

@end

#endif /* SceneRenderer_h */
