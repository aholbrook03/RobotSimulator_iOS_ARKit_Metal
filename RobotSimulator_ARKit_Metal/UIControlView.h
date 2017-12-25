//
//  UIControlView.h
//  RobotSimulator_ARKit_Metal
//
//  Created by Andrew Holbrook on 12/18/17.
//  Copyright © 2017 Andrew Holbrook. All rights reserved.
//

#ifndef UIControlView_h
#define UIControlView_h

#import <UIKit/UIKit.h>

#import "SceneRenderer.h"

@interface UIControlView : UIView

+ (UIControlView *)createWithFrame:(CGRect)frame andSceneRenderer:(SceneRenderer *)sceneRenderer andPlane:(Plane *)plane;

- (void)handleMinusButtonDown;
- (void)handleMinusButtonUp;
- (void)handlePlusButtonDown;
- (void)handlePlusButtonUp;
- (void)handlePrevButtonDown;
- (void)handleNextButtonDown;

@end

#endif /* UIControlView_h */
