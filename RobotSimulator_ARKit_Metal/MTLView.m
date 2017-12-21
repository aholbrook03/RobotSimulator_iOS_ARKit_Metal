//
//  MTLView.m
//  RoboSim
//
//  Created by Andrew Holbrook on 11/30/17.
//  Copyright © 2017 Andrew Holbrook. All rights reserved.
//

#import "MTLView.h"

@implementation MTLView

+ (Class) layerClass {
    return [CAMetalLayer class];
}

@end
