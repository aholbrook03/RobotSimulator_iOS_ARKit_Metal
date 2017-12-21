//
//  ViewController.m
//  RobotSimulator_ARKit_Metal
//
//  Created by Andrew Holbrook on 12/9/17.
//  Copyright © 2017 Andrew Holbrook. All rights reserved.
//

#import "ViewController.h"

#import <ARKit/ARKit.h>

#import "UIControlView.h"

@implementation ViewController {
    ARSession *_arSession;
    SceneRenderer *_sceneRenderer;
    CFTimeInterval _startTime;
    CADisplayLink *_displayLink;
    UIControlView *_controlView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.view addGestureRecognizer:tapRecognizer];
    
    self->_arSession = [[ARSession alloc] init];
    self->_arSession.delegate = self;
    
    ARWorldTrackingConfiguration *sessionConfig = [[ARWorldTrackingConfiguration alloc] init];
    sessionConfig.planeDetection = ARPlaneDetectionHorizontal;
    sessionConfig.lightEstimationEnabled = YES;
    [self->_arSession runWithConfiguration:sessionConfig];
    
    self->_sceneRenderer = [SceneRenderer createWithView:(MTLView *)self.view];
    
    self->_startTime = 0;
    self->_displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
    [self->_displayLink addToRunLoop:NSRunLoop.currentRunLoop forMode:NSDefaultRunLoopMode];
}

- (void)update {
    if (self->_startTime == 0) {
        self->_startTime = self->_displayLink.timestamp;
    }
    
    CFTimeInterval deltaTime = self->_displayLink.timestamp - self->_startTime;
    self->_startTime = self->_displayLink.timestamp;
    
    SerialRobot *scaraRobot = [self->_sceneRenderer getRobot];
    [scaraRobot update:deltaTime];
    
    [self->_sceneRenderer renderWithARFrame:self->_arSession.currentFrame];
}

- (void)handleTap:(UITapGestureRecognizer *)tapRecognizer {
    CGPoint pointInView = [tapRecognizer locationInView:self.view];
    pointInView.y = self.view.bounds.size.height - pointInView.y;
    CGPoint location = CGPointMake(pointInView.x / self.view.bounds.size.width,
                                   pointInView.y / self.view.bounds.size.height);
    
    if ([self->_sceneRenderer isPlaneSelected]) {
    } else {
        NSArray<ARHitTestResult *> *hitResults = [self->_arSession.currentFrame hitTest:location
                                                                                  types:ARHitTestResultTypeExistingPlaneUsingExtent];
        for (ARHitTestResult *hitResult in hitResults) {
            [self->_sceneRenderer selectPlaneByIdentifier:hitResult.anchor.identifier];
            ARWorldTrackingConfiguration *sessionConfig = (ARWorldTrackingConfiguration *)self->_arSession.configuration;
            sessionConfig.planeDetection = ARPlaneDetectionNone;
            break;
        }
        
        if ([self->_sceneRenderer isPlaneSelected]) {
            self->_controlView = [UIControlView createWithFrame:CGRectMake(0.0f, self.view.bounds.size.height * 0.8f,
                                                                                   self.view.bounds.size.width, self.view.bounds.size.height * 0.2f)
                                               andSceneRenderer:self->_sceneRenderer];
            [self.view addSubview:self->_controlView];
        }
    }
}

- (void)session:(ARSession *)session didAddAnchors:(NSArray<ARAnchor *> *)anchors {
    for (ARAnchor *anchor in anchors) {
        if ([anchor isKindOfClass:[ARPlaneAnchor class]]) {
            [self->_sceneRenderer addPlane:(ARPlaneAnchor *)anchor];
        }
    }
}

- (void)session:(ARSession *)session didUpdateAnchors:(NSArray<ARAnchor *> *)anchors {
    for (ARAnchor *anchor in anchors) {
        if ([anchor isKindOfClass:[ARPlaneAnchor class]]) {
            [self->_sceneRenderer updatePlane:(ARPlaneAnchor *)anchor];
        }
    }
}

- (void)session:(ARSession *)session didRemoveAnchors:(NSArray<ARAnchor *> *)anchors {
}

@end
