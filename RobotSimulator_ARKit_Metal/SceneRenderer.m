//
//  SceneRenderer.m
//  RobotSimulator_ARKit_Metal
//
//  Created by Andrew Holbrook on 12/9/17.
//  Copyright © 2017 Andrew Holbrook. All rights reserved.
//

#import "SceneRenderer.h"
#import "Plane.h"
#import "SerialRobot.h"

@implementation SceneRenderer {
    id<MTLDevice> _mtlDevice;
    id<MTLCommandQueue> _mtlCommandQueue;
    id<MTLTexture> _depthTexture;
    
    // background image rendering properties
    id<MTLRenderPipelineState> _backgroundImagePipelineState;
    id<MTLDepthStencilState> _backgroundImageDepthState;
    id<MTLBuffer> _backgroundVertexAttributesBuffer;
    CVMetalTextureCacheRef _backgroundTextureCache;
    CVMetalTextureRef _backgroundTextureY;
    CVMetalTextureRef _backgroundTextureCbCr;
    
    // plane rendering properties
    id<MTLRenderPipelineState> _planePipelineState;
    
    // main scene rendering properties
    id<MTLRenderPipelineState> _mainPipelineState;
    id<MTLDepthStencilState> _mainDepthState;
    id<MTLBuffer> _cameraPositionBuffer;
    id<MTLBuffer> _ambientIntensityBuffer;
    
    NSMutableDictionary<NSUUID *, Plane *> *_planeDict;
    NSUUID *_selectedPlaneID;
    
    SerialRobot *_robot;
}

+ (SceneRenderer *)createWithView:(MTLView *)view {
    SceneRenderer *newSceneRenderer = [[SceneRenderer alloc] init];
    [newSceneRenderer setView:view];
    
    // setup viewport to fill entire view
    MTLViewport viewport;
    viewport.originX = 0.0;
    viewport.originY = 0.0;
    viewport.width = view.bounds.size.width;
    viewport.height = view.bounds.size.height;
    viewport.znear = 0.0;
    viewport.zfar = 1.0;
    [newSceneRenderer setViewport:viewport];
    
    newSceneRenderer->_mtlDevice = MTLCreateSystemDefaultDevice();
    newSceneRenderer->_mtlCommandQueue = [newSceneRenderer->_mtlDevice newCommandQueue];
    
    // create a depth texture to use for all rendering pipelines
    MTLTextureDescriptor *depthTextureDesc = [MTLTextureDescriptor
                                              texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float
                                              width:viewport.width
                                              height:viewport.height
                                              mipmapped:NO];
    depthTextureDesc.usage = MTLTextureUsageRenderTarget;
    newSceneRenderer->_depthTexture = [newSceneRenderer->_mtlDevice newTextureWithDescriptor:depthTextureDesc];
    
    [newSceneRenderer _setupBackgroundImagePipelineStateAndBuffers];
    [newSceneRenderer _setupPlanePipelineState];
    [newSceneRenderer _setupMainPipelineState];
    
    newSceneRenderer->_planeDict = [[NSMutableDictionary alloc] init];
    newSceneRenderer->_selectedPlaneID = nil;
    
    NSString *pathToJSONFile = [[NSBundle mainBundle] pathForResource:@"scara" ofType:@".json"];
    newSceneRenderer->_robot = [SerialRobot createWithJSON:pathToJSONFile andMTLDevice:newSceneRenderer->_mtlDevice];
    
    return newSceneRenderer;
}

- (void)addPlane:(ARPlaneAnchor *)planeAnchor {
    [self->_planeDict setObject:[Plane createWithPlaneAnchor:planeAnchor andMTLDevice:self->_mtlDevice]
                         forKey:planeAnchor.identifier];
}

- (void)updatePlane:(ARPlaneAnchor *)planeAnchor {
    Plane *plane = [self->_planeDict objectForKey:planeAnchor.identifier];
    [plane setPlaneAnchor:planeAnchor];
}

- (Plane *)getPlaneByIdentifier:(NSUUID *)identifier {
    return [self->_planeDict objectForKey:identifier];
}

- (Plane *)getSelectedPlane {
    return [self getPlaneByIdentifier:self->_selectedPlaneID];
}

- (BOOL)isPlaneSelected {
    return self->_selectedPlaneID != nil;
}

- (void)selectPlaneByIdentifier:(NSUUID *)identifier {
    self->_selectedPlaneID = identifier;
    Plane *selectedPlane = [self getPlaneByIdentifier:identifier];
    [self->_robot setPosition:[selectedPlane getCenterPosition]];
}

- (SerialRobot *)getRobot {
    return self->_robot;
}

- (void)render {
    @autoreleasepool {
        id<MTLCommandBuffer> commandBuffer = [self->_mtlCommandQueue commandBuffer];
        CAMetalLayer *metalLayer = (CAMetalLayer *)self.view.layer;
        id<CAMetalDrawable> drawable = [metalLayer nextDrawable];
        
        MTLRenderPassDescriptor *renderPassDesc = [MTLRenderPassDescriptor renderPassDescriptor];
        renderPassDesc.colorAttachments[0].texture = drawable.texture;
        renderPassDesc.colorAttachments[0].loadAction = MTLLoadActionDontCare;
        renderPassDesc.depthAttachment.texture = self->_depthTexture;
        renderPassDesc.depthAttachment.loadAction = MTLLoadActionClear;
        renderPassDesc.depthAttachment.clearDepth = 1.0;
        
        id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDesc];
        [renderEncoder setCullMode:MTLCullModeBack];
        [renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
        [renderEncoder setViewport:self.viewport];
        
        //[self _renderSceneWithRenderEncoder:renderEncoder];
        
        [renderEncoder endEncoding];
        [commandBuffer presentDrawable:drawable];
        [commandBuffer commit];
        [commandBuffer waitUntilCompleted];
    }
}

- (void)renderWithARFrame:(ARFrame *)arFrame {
    if (arFrame == nil) {
        return;
    }
    
    @autoreleasepool {
        id<MTLCommandBuffer> commandBuffer = [self->_mtlCommandQueue commandBuffer];
        CAMetalLayer *metalLayer = (CAMetalLayer *)self.view.layer;
        id<CAMetalDrawable> drawable = [metalLayer nextDrawable];
        
        MTLRenderPassDescriptor *renderPassDesc = [MTLRenderPassDescriptor renderPassDescriptor];
        renderPassDesc.colorAttachments[0].texture = drawable.texture;
        renderPassDesc.colorAttachments[0].loadAction = MTLLoadActionDontCare;
        renderPassDesc.depthAttachment.texture = self->_depthTexture;
        renderPassDesc.depthAttachment.loadAction = MTLLoadActionClear;
        renderPassDesc.depthAttachment.clearDepth = 1.0;
        
        id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDesc];
        [renderEncoder setCullMode:MTLCullModeBack];
        [renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
        [renderEncoder setViewport:self.viewport];
        
        CGSize viewportSize = CGSizeMake(self->_viewport.width, self->_viewport.height);
        matrix_float4x4 projectionMatrix = [arFrame.camera projectionMatrixForOrientation:UIInterfaceOrientationPortrait
                                                                              viewportSize:viewportSize
                                                                                     zNear:0.001 zFar:1000.0];
        matrix_float4x4 viewMatrix = [arFrame.camera viewMatrixForOrientation:UIInterfaceOrientationPortrait];
        matrix_float4x4 vpMatrix = matrix_multiply(projectionMatrix, viewMatrix);
        
        [self _renderBackgroundImageWithRenderEncoder:renderEncoder andARFrame:arFrame];
        
        if (self->_selectedPlaneID == nil) {
            [self _renderPlanesWithRenderEncoder:renderEncoder andVPMatrix:vpMatrix];
        } else {
            [self _renderSceneWithRenderEncoder:renderEncoder andVPMatrix:vpMatrix
                              andCameraPosition:arFrame.camera.transform.columns[3]
                            andAmbientIntensity:arFrame.lightEstimate.ambientIntensity / 1000.0f];
        }
        
        [renderEncoder endEncoding];
        [commandBuffer presentDrawable:drawable];
        [commandBuffer commit];
        [commandBuffer waitUntilCompleted];
    }
}

- (void)_setupBackgroundImagePipelineStateAndBuffers {
    MTLRenderPipelineDescriptor *renderPipelineDesc = [[MTLRenderPipelineDescriptor alloc] init];
    
    id<MTLLibrary> defaultLib = [self->_mtlDevice newDefaultLibrary];
    id<MTLFunction> vertexFunction = [defaultLib newFunctionWithName:@"backgroundImageVertexFunction"];
    id<MTLFunction> fragmentFunction = [defaultLib newFunctionWithName:@"backgroundImageFragmentFunction"];
    
    renderPipelineDesc.vertexFunction = vertexFunction;
    renderPipelineDesc.fragmentFunction = fragmentFunction;
    
    MTLVertexDescriptor *vertexDescriptor = [MTLVertexDescriptor vertexDescriptor];
    
    // position attributes
    vertexDescriptor.attributes[0].offset = 0;
    vertexDescriptor.attributes[0].bufferIndex = 0;
    vertexDescriptor.attributes[0].format = MTLVertexFormatFloat4;
    
    // uv coordinates
    vertexDescriptor.attributes[1].offset = 16;
    vertexDescriptor.attributes[1].bufferIndex = 0;
    vertexDescriptor.attributes[1].format = MTLVertexFormatFloat2;
    
    vertexDescriptor.layouts[0].stride = 24;
    vertexDescriptor.layouts[0].stepRate = 1;
    vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
    
    renderPipelineDesc.vertexDescriptor = vertexDescriptor;
    
    CAMetalLayer *metalLayer = (CAMetalLayer *)self.view.layer;
    renderPipelineDesc.colorAttachments[0].pixelFormat = metalLayer.pixelFormat;
    renderPipelineDesc.depthAttachmentPixelFormat = self->_depthTexture.pixelFormat;
    
    self->_backgroundImagePipelineState = [self->_mtlDevice newRenderPipelineStateWithDescriptor:renderPipelineDesc error:nil];
    
    float backgroundVertexData[] = {
        1.0f,  1.0f, 0.0f, 1.0f,
        0.0f,  0.0f,
        -1.0f, -1.0f, 0.0f, 1.0f,
        1.0f,  1.0f,
        1.0f, -1.0f, 0.0f, 1.0f,
        1.0f,  0.0f,
        -1.0f, -1.0f, 0.0f, 1.0f,
        1.0f,  1.0f,
        1.0f,  1.0f, 0.0f, 1.0f,
        0.0f,  0.0f,
        -1.0f,  1.0f, 0.0f, 1.0f,
        0.0f,  1.0f
    };
    
    self->_backgroundVertexAttributesBuffer = [self->_mtlDevice newBufferWithBytes:backgroundVertexData length:sizeof(backgroundVertexData) options:MTLResourceStorageModeShared];
    
    MTLDepthStencilDescriptor *depthStateDescriptor = [MTLDepthStencilDescriptor new];
    depthStateDescriptor.depthCompareFunction = MTLCompareFunctionAlways;
    depthStateDescriptor.depthWriteEnabled = NO;
    self->_backgroundImageDepthState = [self->_mtlDevice newDepthStencilStateWithDescriptor:depthStateDescriptor];
    
    CVMetalTextureCacheCreate(NULL, NULL, self->_mtlDevice, NULL, &self->_backgroundTextureCache);
}

- (void)_setupPlanePipelineState {
    MTLRenderPipelineDescriptor *renderPipelineDesc = [[MTLRenderPipelineDescriptor alloc] init];
    
    id<MTLLibrary> defaultLib = [self->_mtlDevice newDefaultLibrary];
    id<MTLFunction> vertexFunction = [defaultLib newFunctionWithName:@"planeVertexFunction"];
    id<MTLFunction> fragmentFunction = [defaultLib newFunctionWithName:@"planeFragmentFunction"];
    
    renderPipelineDesc.vertexFunction = vertexFunction;
    renderPipelineDesc.fragmentFunction = fragmentFunction;
    
    MTLVertexDescriptor *vertexDescriptor = [MTLVertexDescriptor vertexDescriptor];
    
    // position attribute
    vertexDescriptor.attributes[0].offset = 0;
    vertexDescriptor.attributes[0].bufferIndex = 0;
    vertexDescriptor.attributes[0].format = MTLVertexFormatFloat4;
    
    vertexDescriptor.layouts[0].stride = 16;
    vertexDescriptor.layouts[0].stepRate = 1;
    vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
    
    renderPipelineDesc.vertexDescriptor = vertexDescriptor;
    
    CAMetalLayer *metalLayer = (CAMetalLayer *)self.view.layer;
    renderPipelineDesc.colorAttachments[0].pixelFormat = metalLayer.pixelFormat;
    renderPipelineDesc.depthAttachmentPixelFormat = self->_depthTexture.pixelFormat;
    
    self->_planePipelineState = [self->_mtlDevice newRenderPipelineStateWithDescriptor:renderPipelineDesc error:nil];
}

- (void)_setupMainPipelineState {
    MTLRenderPipelineDescriptor *renderPipelineDesc = [[MTLRenderPipelineDescriptor alloc] init];
    
    id<MTLLibrary> defaultLib = [self->_mtlDevice newDefaultLibrary];
    id<MTLFunction> vertexFunction = [defaultLib newFunctionWithName:@"vertexFunction"];
    id<MTLFunction> fragmentFunction = [defaultLib newFunctionWithName:@"fragmentFunction"];
    
    renderPipelineDesc.vertexFunction = vertexFunction;
    renderPipelineDesc.fragmentFunction = fragmentFunction;
    
    MTLVertexDescriptor *vertexDescriptor = [MTLVertexDescriptor vertexDescriptor];
    
    // position attribute
    vertexDescriptor.attributes[0].offset = 0;
    vertexDescriptor.attributes[0].bufferIndex = 0;
    vertexDescriptor.attributes[0].format = MTLVertexFormatFloat4;
    
    // normal attribute
    vertexDescriptor.attributes[1].offset = 16;
    vertexDescriptor.attributes[1].bufferIndex = 0;
    vertexDescriptor.attributes[1].format = MTLVertexFormatFloat4;
    
    vertexDescriptor.layouts[0].stride = 32;
    vertexDescriptor.layouts[0].stepRate = 1;
    vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
    
    renderPipelineDesc.vertexDescriptor = vertexDescriptor;
    
    CAMetalLayer *metalLayer = (CAMetalLayer *)self.view.layer;
    renderPipelineDesc.colorAttachments[0].pixelFormat = metalLayer.pixelFormat;
    renderPipelineDesc.depthAttachmentPixelFormat = self->_depthTexture.pixelFormat;
    
    self->_mainPipelineState = [self->_mtlDevice newRenderPipelineStateWithDescriptor:renderPipelineDesc error:nil];
    
    MTLDepthStencilDescriptor *depthStateDescriptor = [MTLDepthStencilDescriptor new];
    depthStateDescriptor.depthCompareFunction = MTLCompareFunctionLess;
    depthStateDescriptor.depthWriteEnabled = YES;
    self->_mainDepthState = [self->_mtlDevice newDepthStencilStateWithDescriptor:depthStateDescriptor];
    
    self->_cameraPositionBuffer = [self->_mtlDevice newBufferWithLength:sizeof(float) * 4 options:MTLResourceStorageModeShared];
    self->_ambientIntensityBuffer = [self->_mtlDevice newBufferWithLength:sizeof(float) options:MTLResourceStorageModeShared];
}

- (void)_renderPlanesWithRenderEncoder:(id<MTLRenderCommandEncoder>)renderEncoder andVPMatrix:(matrix_float4x4)vpMatrix {
    [renderEncoder setRenderPipelineState:self->_planePipelineState];
    [renderEncoder setDepthStencilState:self->_mainDepthState];
    
    for (NSUUID *planeID in self->_planeDict) {
        Plane *plane = [self->_planeDict objectForKey:planeID];
        [plane renderWithRenderEncoder:renderEncoder andVPMatrix:vpMatrix];
    }
}

- (void)_renderBackgroundImageWithRenderEncoder:(id<MTLRenderCommandEncoder>)renderEncoder andARFrame:(ARFrame *)arFrame {
    [renderEncoder setVertexBuffer:self->_backgroundVertexAttributesBuffer offset:0 atIndex:0];
    [renderEncoder setRenderPipelineState:self->_backgroundImagePipelineState];
    [renderEncoder setDepthStencilState:self->_backgroundImageDepthState];
    
    CVBufferRelease(self->_backgroundTextureY);
    CVBufferRelease(self->_backgroundTextureCbCr);
    
    size_t width = CVPixelBufferGetWidthOfPlane(arFrame.capturedImage, 0);
    size_t height = CVPixelBufferGetHeightOfPlane(arFrame.capturedImage, 0);
    CVMetalTextureCacheCreateTextureFromImage(NULL,
                                              self->_backgroundTextureCache,
                                              arFrame.capturedImage,
                                              NULL,
                                              MTLPixelFormatR8Unorm,
                                              width,
                                              height,
                                              0,
                                              &self->_backgroundTextureY);
    
    width = CVPixelBufferGetWidthOfPlane(arFrame.capturedImage, 1);
    height = CVPixelBufferGetHeightOfPlane(arFrame.capturedImage, 1);
    CVMetalTextureCacheCreateTextureFromImage(NULL,
                                              self->_backgroundTextureCache,
                                              arFrame.capturedImage,
                                              NULL,
                                              MTLPixelFormatRG8Unorm,
                                              width,
                                              height,
                                              1,
                                              &self->_backgroundTextureCbCr);
    
    [renderEncoder setFragmentTexture:CVMetalTextureGetTexture(self->_backgroundTextureY) atIndex:0];
    [renderEncoder setFragmentTexture:CVMetalTextureGetTexture(self->_backgroundTextureCbCr) atIndex:1];
    
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
}

- (void)_renderSceneWithRenderEncoder:(id<MTLRenderCommandEncoder>)renderEncoder andVPMatrix:(matrix_float4x4)vpMatrix
                    andCameraPosition:(simd_float4)cameraPosition andAmbientIntensity:(float)ambientIntensity {
    [renderEncoder setRenderPipelineState:self->_mainPipelineState];
    [renderEncoder setDepthStencilState:self->_mainDepthState];
    
    memcpy(self->_cameraPositionBuffer.contents, &cameraPosition, sizeof(float) * 4);
    [renderEncoder setFragmentBuffer:self->_cameraPositionBuffer offset:0 atIndex:2];
    
    memcpy(self->_ambientIntensityBuffer.contents, &ambientIntensity, sizeof(float));
    [renderEncoder setFragmentBuffer:self->_ambientIntensityBuffer offset:0 atIndex:3];
    
    [self->_robot renderWithRenderEncoder:renderEncoder andVPMatrix:vpMatrix];
}



@end
