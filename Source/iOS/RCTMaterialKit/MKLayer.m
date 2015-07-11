//
//  MKLayer.m
//  RCTMaterialKit
//
//  Created by Yingxin Wu on 15/6/6.
//  Copyright (c) 2015年 xinthink. All rights reserved.
//

#import "MKLayer.h"
@import CoreGraphics;


@implementation MKTimingFunction
// static instances
static MKTimingFunction *_linear = nil;
static MKTimingFunction *_easeIn = nil;
static MKTimingFunction *_easeOut = nil;

+ (instancetype)withName:(NSString*)name {
    MKTimingFunction *inst = [[[self class] alloc] init];
    inst.name = name;
    return inst;
}

+ (instancetype)linear {
    if (_linear) {
        return _linear;
    }

    @synchronized([self class]) {
        if (!_linear) {
            _linear = [[self class] withName:@"linear"];
        }
    }

    return _linear;
}

+ (instancetype)easeIn {
    if (_easeIn) {
        return _easeIn;
    }
    
    @synchronized([self class]) {
        if (!_easeIn) {
            _easeIn = [[self class] withName:@"easeIn"];
        }
    }

    return _easeIn;
}

+ (instancetype)easeOut {
    if (_easeOut) {
        return _easeOut;
    }
    
    @synchronized([self class]) {
        if (!_easeOut) {
            _easeOut = [[self class] withName:@"easeOut"];
        }
    }

    return _easeOut;
}

+ (instancetype)customize:(float)c1x :(float)c1y :(float)c2x :(float)c2y {
    MKTimingFunction *inst = [[[self class] alloc] init];
    inst.name = nil;
    inst.c1x = c1x;
    inst.c1y = c1y;
    inst.c2x = c2x;
    inst.c2y = c2y;
    return inst;
}

- (CAMediaTimingFunction*)function {
    if (!self.name) {
        return [CAMediaTimingFunction functionWithName:self.name];
    }

    return [CAMediaTimingFunction functionWithControlPoints:self.c1x :self.c1y :self.c2x :self.c2y];
}

@end


@implementation RCTMKLayer {
    CALayer *_superLayer;
    CALayer *_backgroundLayer;
    CALayer *_rippleLayer;
    CAShapeLayer *_maskLayer;
}

@synthesize rippleLocation;
@synthesize ripplePercent;

- (id)initWithSuperLayer:(CALayer *)superLayer {
    self = [super init];

    if (self) {
        _superLayer = superLayer;
        [_superLayer addObserver:self
                      forKeyPath:@"bounds"
                         options:NSKeyValueObservingOptionNew
                         context:nil];

        CGFloat sw = CGRectGetWidth(superLayer.bounds);
        CGFloat sh = CGRectGetHeight(superLayer.bounds);

        // background layer
        _backgroundLayer = [[CALayer alloc] init];
        _backgroundLayer.frame = superLayer.bounds;
        _backgroundLayer.opacity = 0.0;
        _backgroundLayer.masksToBounds = true;
        [_superLayer addSublayer:_backgroundLayer];

        // ripple layer
        _rippleLayer = [[CALayer alloc] init];
        CGFloat circleSize = MAX(sw, sh) * self.ripplePercent;
        CGFloat rippleCornerRadius = circleSize / 2;

        _rippleLayer.opacity = 0.0;
        _rippleLayer.cornerRadius = rippleCornerRadius;
        [self setCircleLayerLocationAt:CGPointMake(sw / 2, sh / 2)];
        [_backgroundLayer addSublayer:_rippleLayer];

        // mask layer
        [self setMaskLayerCornerRadius:superLayer.cornerRadius];
        _backgroundLayer.mask = _maskLayer;
    }

    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    NSLog(@"value changed %@ %@", keyPath, change);
    if ([@"bounds" isEqual:keyPath]) {
        [self superLayerDidResize];
    }
}

- (void)setRippleLocation:(MKRippleLocation)location {
    rippleLocation = location;
    [self updateRippleLocation];
}

- (MKRippleLocation)rippleLocation {
    return rippleLocation;
}

- (void)updateRippleLocation {
    CGFloat sw = CGRectGetWidth(_superLayer.bounds);
    CGFloat sh = CGRectGetHeight(_superLayer.bounds);
    
    switch (rippleLocation) {
        case MKRippleCenter:
            [self setCircleLayerLocationAt:CGPointMake(sw/2, sh/2)];
            break;
        case MKRippleLeft:
            [self setCircleLayerLocationAt:CGPointMake(sw * 0.25, sh / 2)];
            break;
        case MKRippleRight:
            [self setCircleLayerLocationAt:CGPointMake(sw * 0.75, sh / 2)];
            break;
        default:
            break;
    }
}

- (void)setRipplePercent:(float)percent {
    ripplePercent = percent;
    if (ripplePercent > 0) {
        CGFloat sw = CGRectGetWidth(_superLayer.bounds);
        CGFloat sh = CGRectGetHeight(_superLayer.bounds);
        CGFloat circleSize = MAX(sw, sh) * ripplePercent;
        CGFloat circleCornerRadius = circleSize / 2;

        _rippleLayer.cornerRadius = circleCornerRadius;
        [self setCircleLayerLocationAt:CGPointMake(sw / 2, sh / 2)];
    }
}

- (float)ripplePercent {
    return ripplePercent;
}

- (void)setCircleLayerLocationAt:(CGPoint)center {
    CGRect bounds = _superLayer.bounds;
    CGFloat width = CGRectGetWidth(bounds);
    CGFloat height = CGRectGetHeight(bounds);
    CGFloat subSize = MAX(width, height) * self.ripplePercent;
    CGFloat subX = center.x - subSize / 2;
    CGFloat subY = center.y - subSize / 2;

    // disable animation when changing layer frame
    [CATransaction begin];
    [CATransaction setDisableActions:true];
    _rippleLayer.cornerRadius = subSize / 2;
    _rippleLayer.frame = CGRectMake(subX, subY, subSize, subSize);
    [CATransaction commit];
}

- (void)setMaskLayerCornerRadius:(float)cornerRadius {
    _maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:_backgroundLayer.bounds
                                                 cornerRadius:cornerRadius].CGPath;
}

- (void)superLayerDidResize {
    [CATransaction begin];
    [CATransaction setDisableActions:true];
    _backgroundLayer.frame = _superLayer.bounds;
    [self setMaskLayerCornerRadius:_superLayer.cornerRadius];
    [CATransaction commit];
    [self updateRippleLocation];
//    [self setCircleLayerLocationAt:CGPointMake(_superLayer.bounds.size.width / 2,
//                                               _superLayer.bounds.size.height / 2)];
}

- (void)enableOnlyCircleLayer {
    [_backgroundLayer removeFromSuperlayer];
    [_superLayer addSublayer:_rippleLayer];
}

- (void)setBackgroundLayerColor:(UIColor*)color {
    _backgroundLayer.backgroundColor = color.CGColor;
}

- (void)setCircleLayerColor:(UIColor*)color {
    _rippleLayer.backgroundColor = color.CGColor;
}

- (void)didChangeTapLocation:(CGPoint)location {
    if (rippleLocation == MKRippleTapLocation) {
        [self setCircleLayerLocationAt:location];
    }
}

- (void)enableMask {
    [self enableMask:true];
}

- (void)enableMask:(BOOL)enable {
    _backgroundLayer.mask = enable ? _maskLayer : nil;
    _backgroundLayer.masksToBounds = enable;
}

- (void)setBackgroundLayerCornerRadius:(CGFloat)cornerRadius {
    _backgroundLayer.cornerRadius = cornerRadius;
}

// MARK - Animation
- (void)animateScaleForCircleLayer:(id)fromScale
                           toScale:(id)toScale
                    timingFunction:(MKTimingFunction*)timingFunction
                          duration:(CFTimeInterval)duration {
    CABasicAnimation *rippleLayerAnim = [CABasicAnimation animation];
    rippleLayerAnim.keyPath = @"transform.scale";
    rippleLayerAnim.fromValue = fromScale;
    rippleLayerAnim.toValue = toScale;

    CABasicAnimation *opacityAnim = [CABasicAnimation animation];
    opacityAnim.keyPath = @"opacity";
    opacityAnim.fromValue = @1.0;
    opacityAnim.toValue = @0.0;

    CAAnimationGroup *groupAnim = [[CAAnimationGroup alloc] init];
    groupAnim.duration = duration;
    groupAnim.timingFunction = [timingFunction function];
    groupAnim.removedOnCompletion = false;
    groupAnim.fillMode = kCAFillModeForwards;
    groupAnim.animations = @[rippleLayerAnim, opacityAnim];

    [_rippleLayer addAnimation:groupAnim forKey:nil];
}

- (void)animateAlphaForBackgroundLayer:(MKTimingFunction*)timingFunction
                              duration:(CFTimeInterval)duration {
    CABasicAnimation *bgLayerAnim = [CABasicAnimation animation];
    bgLayerAnim.keyPath = @"opacity";
    bgLayerAnim.fromValue = @1.0;
    bgLayerAnim.toValue = @0.0;
    bgLayerAnim.duration = duration;
    bgLayerAnim.timingFunction = [timingFunction function];
    [_backgroundLayer addAnimation:bgLayerAnim forKey:nil];
}

- (void)animateSuperLayerShadow:(id)fromRadius
                       toRadius:(id)toRadius
                    fromOpacity:(id)fromOpacity
                      toOpacity:(id)toOpacity
                 timingFunction:(MKTimingFunction*)timingFunction
                       duration:(CFTimeInterval)duration {
    [self animateShadowForLayer:_superLayer
                     fromRadius:fromRadius
                       toRadius:toRadius
                    fromOpacity:fromOpacity
                      toOpacity:toOpacity
                 timingFunction:timingFunction
                       duration: duration];
}

- (void)animateShadowForLayer:(CALayer*)layer
                   fromRadius:(id)fromRadius
                     toRadius:(id)toRadius
                  fromOpacity:(id)fromOpacity
                    toOpacity:(id)toOpacity
               timingFunction:(MKTimingFunction*)timingFunction
                     duration:(CFTimeInterval)duration {
    CABasicAnimation *radiusAnim = [CABasicAnimation animation];
    radiusAnim.keyPath = @"shadowRadius";
    radiusAnim.fromValue = fromRadius;
    radiusAnim.toValue = toRadius;
    
    CABasicAnimation *opacityAnim = [CABasicAnimation animation];
    opacityAnim.keyPath = @"shadowOpacity";
    opacityAnim.fromValue = fromOpacity;
    opacityAnim.toValue = toOpacity;
    
    CAAnimationGroup *groupAnim = [[CAAnimationGroup alloc] init];
    groupAnim.duration = duration;
    groupAnim.timingFunction = [timingFunction function];
    groupAnim.removedOnCompletion = false;
    groupAnim.fillMode = kCAFillModeForwards;
    groupAnim.animations = @[radiusAnim, opacityAnim];
    
    [layer addAnimation:groupAnim forKey:nil];
}

- (void)animateMaskLayerShadow {

}

@end


@implementation MKLayerSupport {
    UIView *_view;
}

@synthesize mkLayer = _mkLayer;
@synthesize maskEnabled;
@synthesize rippleLocation;
@synthesize rippleLocationByName;
@synthesize ripplePercent;
@synthesize backgroundLayerCornerRadius;
@synthesize cornerRadius;
@synthesize backgroundAniEnabled;
@synthesize rippleLayerColor;
@synthesize backgroundLayerColor;
@synthesize rippleAniTimingFunctionByName;

- (instancetype)initWithUIView:(UIView *)view {
    if (self = [super init]) {
        _view = view;
        [self setupLayer];
    }
    return self;
}

- (void)setupLayer {
    // default properties
    self.maskEnabled = true;
    self.ripplePercent = 1;
    self.rippleLocation = MKRippleTapLocation;
    self.cornerRadius = 2.5;
    
    self.shadowAniEnabled = true;
    self.backgroundAniEnabled = true;
    self.rippleAniDuration = 0.75;
    self.backgroundAniDuration = 1;
    self.shadowAniDuration = 0.65;
    self.rippleAniTimingFunction = MKTimingLinear;
    self.backgroundAniTimingFunction = MKTimingLinear;
    self.shadowAniTimingFunction = MKTimingEaseOut;
    
    self.rippleLayerColor = [UIColor colorWithWhite:0.45 alpha:0.5];
    self.backgroundLayerColor = [UIColor colorWithWhite:0.75 alpha:0.25];
}

- (RCTMKLayer *)mkLayer {
    if (!_mkLayer) {
        _mkLayer = [[RCTMKLayer alloc] initWithSuperLayer:_view.layer];
    }
    
    return _mkLayer;
}

- (void)setMaskEnabled:(BOOL)enabled {
    maskEnabled = enabled;
    [self.mkLayer enableMask:enabled];
}

- (BOOL)maskEnabled {
    return maskEnabled;
}

- (void)setRippleLocation:(MKRippleLocation)location {
    rippleLocation = location;
    self.mkLayer.rippleLocation = location;
}

- (MKRippleLocation)rippleLocation {
    return rippleLocation;
}

- (void)setRippleLocationByName:(NSString *)name {
    if ([@"tapLocation" isEqual:name]) {
        self.rippleLocation = MKRippleTapLocation;
    } else if ([@"center" isEqual:name]) {
        self.rippleLocation = MKRippleCenter;
    } else if ([@"left" isEqual:name]) {
        self.rippleLocation = MKRippleLeft;
    } else if ([@"right" isEqual:name]) {
        self.rippleLocation = MKRippleRight;
    } else {
        NSLog(@"unknown ripple location: %@", name);
    }
}

- (NSString*)rippleLocationByName {
    return nil;
}

- (void)setRipplePercent:(float)percent {
    ripplePercent = percent;
    self.mkLayer.ripplePercent = percent;
}

- (float)ripplePercent {
    return ripplePercent;
}

- (void)setBackgroundLayerCornerRadius:(float)radius {
    backgroundLayerCornerRadius = radius;
    [self.mkLayer setBackgroundLayerCornerRadius:radius];
}

- (float)backgroundLayerCornerRadius {
    return backgroundLayerCornerRadius;
}

- (void)setBackgroundAniEnabled:(BOOL)enabled {
    backgroundAniEnabled = enabled;
    if (!backgroundAniEnabled) {
        [self.mkLayer enableOnlyCircleLayer];
    }
}

- (BOOL)backgroundAniEnabled {
    return backgroundAniEnabled;
}

- (void)setRippleAniTimingFunctionByName:(NSString *)name {
    if ([@"linear" isEqual:name]) {
        self.rippleAniTimingFunction = MKTimingLinear;
    } else if ([@"easeIn" isEqual:name]) {
        self.rippleAniTimingFunction = MKTimingEaseIn;
    } else if ([@"easeOut" isEqual:name]) {
        self.rippleAniTimingFunction = MKTimingEaseOut;
    } else {
        NSLog(@"unkonwn timing function name: %@", name);
    }
}

- (NSString*)rippleAniTimingFunctionByName {
    return self.rippleAniTimingFunction.name;
}

- (void)setCornerRadius:(float)radius {
    cornerRadius = radius;
    _view.layer.cornerRadius = radius;
    self.backgroundLayerCornerRadius = radius;
    [self.mkLayer setMaskLayerCornerRadius:radius];
}

- (float)cornerRadius {
    return cornerRadius;
}

- (void)setRippleLayerColor:(UIColor *)color {
    rippleLayerColor = color;
    [self.mkLayer setCircleLayerColor:color];
}

- (UIColor *)rippleLayerColor { return rippleLayerColor; }

- (void)setBackgroundLayerColor:(UIColor *)color {
    backgroundLayerColor = color;
    [self.mkLayer setBackgroundLayerColor:color];
}

- (UIColor *)backgroundLayerColor { return backgroundLayerColor; }

@end
