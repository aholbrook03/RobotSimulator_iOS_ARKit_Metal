//
//  shaders.metal
//  RobotSimulator_ARKit_Metal
//
//  Created by Andrew Holbrook on 12/9/17.
//  Copyright © 2017 Andrew Holbrook. All rights reserved.
//

#include <metal_stdlib>
#include <metal_math>
using namespace metal;

struct BackgroundImageVertexIn {
    float4 position [[attribute(0)]];
    float2 uv [[attribute(1)]];
};

struct BackgroundImageFragmentIn {
    float4 position [[position]];
    float2 uv;
};

struct PlaneVertexIn {
    float4 position [[attribute(0)]];
};

struct PlaneFragmentIn {
    float4 position [[position]];
    float4 color;
};

struct VertexIn {
    float4 position [[attribute(0)]];
    float4 normal [[attribute(1)]];
};

struct FragmentIn {
    float4 position [[position]];
    float4 world_pos;
    float4 normal;
};

struct Material {
    float4 ambient;
    float4 diffuse;
    float4 specular;
    float shininess;
};

vertex BackgroundImageFragmentIn backgroundImageVertexFunction(BackgroundImageVertexIn dataIn [[stage_in]]) {
    BackgroundImageFragmentIn fragmentIn;
    fragmentIn.position = dataIn.position;
    fragmentIn.uv = dataIn.uv;
    
    return fragmentIn;
}

fragment float4 backgroundImageFragmentFunction(BackgroundImageFragmentIn dataIn [[stage_in]],
                                                texture2d<float, access::sample> backgroundImageTextureY [[texture(0)]],
                                                texture2d<float, access::sample> backgroundImageTextureCbCr [[texture(1)]]) {
    constexpr sampler colorSampler(filter::linear);
    const float4x4 ycbcrToRGBTransform = float4x4(
                                                  float4(+1.0000f, +1.0000f, +1.0000f, +0.0000f),
                                                  float4(+0.0000f, -0.3441f, +1.7720f, +0.0000f),
                                                  float4(+1.4020f, -0.7141f, +0.0000f, +0.0000f),
                                                  float4(-0.7010f, +0.5291f, -0.8860f, +1.0000f)
                                                  );
    
    float4 ycbcr = float4(backgroundImageTextureY.sample(colorSampler, dataIn.uv).r,
                          backgroundImageTextureCbCr.sample(colorSampler, dataIn.uv).rg, 1.0);
    
    float4 result = ycbcrToRGBTransform * ycbcr;
    result = float4(result.r, result.g, result.b, 1.0f);
    return result;
}

vertex PlaneFragmentIn planeVertexFunction(PlaneVertexIn dataIn [[stage_in]],
                                           constant float4x4 &mvpMatrix [[buffer(1)]],
                                           constant float4 &color [[buffer(2)]]) {
    PlaneFragmentIn dataOut;
    dataOut.position = mvpMatrix * dataIn.position;
    dataOut.color = color;
    return dataOut;
}

fragment float4 planeFragmentFunction(PlaneFragmentIn dataIn [[stage_in]]) {
    return dataIn.color;
}

vertex FragmentIn vertexFunction(VertexIn dataIn [[stage_in]],
                                 constant float4x4 &mvpMatrix [[buffer(1)]],
                                 constant float4x4 &modelMatrix [[buffer(2)]]) {
    FragmentIn dataOut;
    dataOut.position = mvpMatrix * dataIn.position;
    dataOut.world_pos = modelMatrix * dataIn.position;
    dataOut.normal = modelMatrix * dataIn.normal;
    return dataOut;
}

// blinn-phong shading
fragment float4 fragmentFunction(FragmentIn dataIn [[stage_in]],
                                 constant Material &material [[buffer(1)]],
                                 constant float4 &cameraPosition [[buffer(2)]],
                                 constant float &ambientIntensity [[buffer(3)]]) {
    float4 lightPos = float4(0.0f, 5.0f, 0.0f, 1.0f);
    float4 pointToLight = normalize(lightPos - dataIn.world_pos);
    float dotp = fmax(0.0f, fmin(1.0f, dot(pointToLight, dataIn.normal)));
    float4 pointToCamera = normalize(cameraPosition - dataIn.world_pos);
    float4 H = normalize(pointToCamera + pointToLight);
    float dote = pow(fmax(0.0f, fmin(1.0f, dot(dataIn.normal, H))), material.shininess);
    
    return float4(material.ambient.r * ambientIntensity + material.diffuse.r * dotp + material.specular.r * dote,
                  material.ambient.g * ambientIntensity + material.diffuse.g * dotp + material.specular.g * dote,
                  material.ambient.b * ambientIntensity + material.diffuse.b * dotp + material.specular.b * dote,
                  1.0f);
}


