//
//  UIControlView.m
//  RobotSimulator_ARKit_Metal
//
//  Created by Andrew Holbrook on 12/18/17.
//  Copyright © 2017 Andrew Holbrook. All rights reserved.
//

#import "UIControlView.h"

#import <Foundation/Foundation.h>

@implementation UIControlView {
    UIButton *_minusButton;
    UIButton *_plusButton;
    UIButton *_prevButton;
    UIButton *_nextButton;
    UILabel *_jointLabel;
    SceneRenderer *_sceneRenderer;
    Plane *_plane;
    int _jointIndex;
}

+ (UIControlView *)createWithFrame:(CGRect)frame andSceneRenderer:(SceneRenderer *)sceneRenderer andPlane:(Plane *)plane {
    UIControlView *controlView = [[UIControlView alloc] initWithFrame:frame];
    
    controlView->_minusButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, frame.size.width * 0.20f, frame.size.height)];
    [controlView->_minusButton setTitle:@"-" forState:UIControlStateNormal];
    [controlView->_minusButton setBackgroundColor:[UIColor blueColor]];
    [controlView->_minusButton addTarget:controlView action:@selector(handleMinusButtonDown) forControlEvents:UIControlEventTouchDown];
    [controlView->_minusButton addTarget:controlView action:@selector(handleMinusButtonUp) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    [controlView addSubview:controlView->_minusButton];
    
    controlView->_plusButton = [[UIButton alloc] initWithFrame:CGRectMake(frame.size.width * 0.80f, 0.0f, frame.size.width * 0.20f, frame.size.height)];
    [controlView->_plusButton setTitle:@"+" forState:UIControlStateNormal];
    [controlView->_plusButton setBackgroundColor:[UIColor blueColor]];
    [controlView->_plusButton addTarget:controlView action:@selector(handlePlusButtonDown) forControlEvents:UIControlEventTouchDown];
    [controlView->_plusButton addTarget:controlView action:@selector(handlePlusButtonUp) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    [controlView addSubview:controlView->_plusButton];
    
    controlView->_prevButton = [[UIButton alloc] initWithFrame:CGRectMake(controlView->_minusButton.bounds.size.width + frame.size.width * 0.02f,
                                                                          frame.size.height * 0.75f,
                                                                          frame.size.width * 0.25f,
                                                                          frame.size.height * 0.20f)];
    [controlView->_prevButton setTitle:@"PREV" forState:UIControlStateNormal];
    [controlView->_prevButton setBackgroundColor:[UIColor yellowColor]];
    [controlView->_prevButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [controlView->_prevButton addTarget:controlView action:@selector(handlePrevButtonDown) forControlEvents:UIControlEventTouchDown];
    [controlView addSubview:controlView->_prevButton];
    
    CGFloat x = frame.size.width - frame.size.width * 0.25f - frame.size.width * 0.02f - frame.size.width * 0.20f;
    controlView->_nextButton = [[UIButton alloc] initWithFrame:CGRectMake(x,
                                                                          frame.size.height * 0.75f,
                                                                          frame.size.width * 0.25f,
                                                                          frame.size.height * 0.20f)];
    [controlView->_nextButton setTitle:@"NEXT" forState:UIControlStateNormal];
    [controlView->_nextButton setBackgroundColor:[UIColor yellowColor]];
    [controlView->_nextButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [controlView->_nextButton addTarget:controlView action:@selector(handleNextButtonDown) forControlEvents:UIControlEventTouchDown];
    [controlView addSubview:controlView->_nextButton];
    
    [controlView setBackgroundColor:[UIColor grayColor]];
    
    controlView->_sceneRenderer = sceneRenderer;
    controlView->_plane = plane;
    controlView->_jointIndex = 0;
    
    controlView->_jointLabel = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width / 2 - frame.size.width * 0.125f,
                                                                         frame.size.height * 0.75f - frame.size.height * 0.25f - frame.size.height * 0.05f,
                                                                         frame.size.width * 0.25f, frame.size.height * 0.25f)];
    [controlView->_jointLabel setBackgroundColor:[UIColor blackColor]];
    [controlView->_jointLabel setTextColor:[UIColor yellowColor]];
    [controlView->_jointLabel setText:@"RX"];
    [controlView->_jointLabel setTextAlignment:NSTextAlignmentCenter];
    [controlView addSubview:controlView->_jointLabel];
    
    return controlView;
}

- (void)handleMinusButtonDown {
    SerialRobot *scaraRobot = [self->_sceneRenderer getRobot];
    
    switch (self->_jointIndex) {
        case 0:
            [scaraRobot moveX:-1];
            break;
        case 1:
            [scaraRobot moveY:-1];
            break;
        case 2:
            [scaraRobot moveZ:-1];
            break;
        case 3:
            [scaraRobot rotateY:-1];
            break;
        default:
            {
                Joint *joint = [scaraRobot getJointAtIndex:self->_jointIndex - 4];
                [joint setDirection:-1];
            }
            break;
    }
}

- (void)handleMinusButtonUp {
    SerialRobot *scaraRobot = [self->_sceneRenderer getRobot];
    
    switch (self->_jointIndex) {
        case 0:
            [scaraRobot moveX:0];
            break;
        case 1:
            [scaraRobot moveY:0];
            break;
        case 2:
            [scaraRobot moveZ:0];
            break;
        case 3:
            [scaraRobot rotateY:0];
            break;
        default:
        {
            Joint *joint = [scaraRobot getJointAtIndex:self->_jointIndex - 4];
            [joint setDirection:0];
        }
            break;
    }
}

- (void)handlePlusButtonDown {
    SerialRobot *scaraRobot = [self->_sceneRenderer getRobot];
    
    switch (self->_jointIndex) {
        case 0:
            [scaraRobot moveX:1];
            break;
        case 1:
            [scaraRobot moveY:1];
            break;
        case 2:
            [scaraRobot moveZ:1];
            break;
        case 3:
            [scaraRobot rotateY:1];
            break;
        default:
        {
            Joint *joint = [scaraRobot getJointAtIndex:self->_jointIndex - 4];
            [joint setDirection:1];
        }
            break;
    }
}

- (void)handlePlusButtonUp {
    SerialRobot *scaraRobot = [self->_sceneRenderer getRobot];
    
    switch (self->_jointIndex) {
        case 0:
            [scaraRobot moveX:0];
            break;
        case 1:
            [scaraRobot moveY:0];
            break;
        case 2:
            [scaraRobot moveZ:0];
            break;
        case 3:
            [scaraRobot rotateY:0];
            break;
        default:
        {
            Joint *joint = [scaraRobot getJointAtIndex:self->_jointIndex - 4];
            [joint setDirection:0];
        }
            break;
    }
}

- (void)handlePrevButtonDown {
    SerialRobot *scaraRobot = [self->_sceneRenderer getRobot];
    
    self->_jointIndex--;
    if (self->_jointIndex < 0) {
        self->_jointIndex = [scaraRobot getNumberOfJoints] - 1 + 4;
    }
    
    switch (self->_jointIndex) {
        case 0:
            [self->_jointLabel setText:@"Rx"];
            break;
        case 1:
            [self->_jointLabel setText:@"Ry"];
            break;
        case 2:
            [self->_jointLabel setText:@"Rz"];
            break;
        case 3:
            [self->_jointLabel setText:@"Ay"];
            break;
        default:
        {
            Joint *joint = [scaraRobot getJointAtIndex:self->_jointIndex - 4];
            [self->_jointLabel setText:joint.name];
        }
            break;
    }
}

- (void)handleNextButtonDown {
    SerialRobot *scaraRobot = [self->_sceneRenderer getRobot];
    
    self->_jointIndex++;
    if (self->_jointIndex == [scaraRobot getNumberOfJoints] + 4) {
        self->_jointIndex = 0;
    }
    
    switch (self->_jointIndex) {
        case 0:
            [self->_jointLabel setText:@"Rx"];
            break;
        case 1:
            [self->_jointLabel setText:@"Ry"];
            break;
        case 2:
            [self->_jointLabel setText:@"Rz"];
            break;
        case 3:
            [self->_jointLabel setText:@"Ay"];
            break;
        default:
        {
            Joint *joint = [scaraRobot getJointAtIndex:self->_jointIndex - 4];
            [self->_jointLabel setText:joint.name];
        }
            break;
    }
}

@end
