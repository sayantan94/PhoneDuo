//
//  DuoFold.metal
//  PhoneDuo
//
//  Frosted-glass "fold" effect.
//
//  Model: the UI lives on a fixed plane in the world, the plane the screen occupied at zero tilt.
//  The viewer does not move either: their eye stays where it was when they looked at the untilted
//  device head-on, on that plane's normal through the screen center. Only the glass moves: when the
//  device tilts by `angle` around the screen-space Y axis, the screen rotates around the edge farther
//  from the viewer, which stays in the UI plane, and the rest of the glass rises toward the eye.
//  Everything is computed in the UI plane's frame. For each screen pixel we:
//    1. place the pixel in 3D on the rotated glass,
//    2. cast a ray from the eye through it and continue until it meets the UI plane,
//    3. blur the UI around the hit point with a radius proportional to the gap between the glass
//       and the plane at that pixel.
//  Rays that miss the UI plane's content are black. A clear window would show the interface exactly
//  where it was, so the reprojection only redistributes which pixels show which part of it.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

// Precomputed, fixed-count disk: no trigonometry or square roots inside the blur loop.
constant float2 kDisk[24] = {
    float2(0.1443376, 0.0000000),
    float2(-0.1843422, 0.1688726),
    float2(0.0282165, -0.3215128),
    float2(0.2323514, 0.3030613),
    float2(-0.4263934, -0.0754230),
    float2(0.4039171, -0.2569390),
    float2(-0.1351024, 0.5025741),
    float2(-0.2576549, -0.4960988),
    float2(0.5590080, 0.2041488),
    float2(-0.5815547, 0.2400573),
    float2(0.2803478, -0.5990869),
    float2(0.2071699, 0.6604902),
    float2(-0.6244124, -0.3618598),
    float2(0.7325068, -0.1610396),
    float2(-0.4470375, 0.6358649),
    float2(-0.1032760, -0.7969739),
    float2(0.6340135, 0.5343472),
    float2(-0.8531834, 0.0352818),
    float2(0.6223318, -0.6193032),
    float2(-0.0416364, 0.9004257),
    float2(-0.5921507, -0.7095944),
    float2(0.9380321, 0.1262109),
    float2(-0.7947927, 0.5529960),
    float2(0.2171831, -0.9654005)
};

// Rotate the fixed disk per pixel to avoid repeated text outlines. Unlike a radius-
// dependent tap count, the pattern stays stable as the radius changes.
static float pixelRotation(float2 p) {
    float3 q = fract(float3(p.xyx) * 0.1031);
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z) * 6.2831853;
}

static half4 opaque(half4 premultiplied) {
    // The layer is premultiplied; dropping alpha composites it over black.
    return half4(premultiplied.rgb, 1.0h);
}

/// - position:    pixel being shaded, in the view's coordinate space (points).
/// - bounds:      view bounds (x, y, width, height), same space as `position`.
/// - angle:       signed tilt in radians around the screen-space Y axis.
///                Positive: the right edge is farther from the viewer, so the UI plane hinges there.
///                Negative: the left edge is the hinge.
/// - eyeDistance: distance from the viewer's eye to the UI plane, in points. The eye sits on the
///                plane's normal through the screen center, where it was when the viewer looked at
///                the untilted device head-on.
/// - blurSpread:  blur radius per point of glass-to-plane separation (tan of the scatter half-angle).
/// - darkening:   fraction of light lost per point of blur radius.
[[ stitchable ]] half4 duoFold(float2 position,
                               SwiftUI::Layer layer,
                               float4 bounds,
                               float angle,
                               float2 tiltSinCos,
                               float eyeDistance,
                               float blurSpread,
                               float darkening,
                               float maxBlurRadius)
{
    const float2 size = bounds.zw;
    const float2 p    = position - bounds.xy;
    const float  tilt = abs(angle);

    if (tilt < 1e-5) {
        return opaque(layer.sample(position));
    }

    // UI-plane frame: origin at the top-left corner of the untilted screen, points, z toward the viewer.
    const bool  hingeRight = angle > 0.0;
    const float hingeX     = hingeRight ? size.x : 0.0;
    const float side       = hingeRight ? -1.0 : 1.0;      // direction across the screen, away from the hinge
    const float d          = abs(p.x - hingeX);            // distance of this pixel from the hinge, along the glass

    // The glass is rotated `tilt` around the hinge line, rising toward the viewer.
    const float3 glass = float3(hingeX + side * d * tiltSinCos.y, p.y, d * tiltSinCos.x);
    const float3 eye   = float3(size * 0.5, eyeDistance);

    // Ray eye -> glass pixel, continued to the UI plane z = 0.
    const float depth = eye.z - glass.z;
    if (depth <= 1e-3) {
        return half4(0.0h, 0.0h, 0.0h, 1.0h);
    }
    const float  t   = eye.z / depth;
    const float2 hit = eye.xy + (glass.xy - eye.xy) * t;

    // Gap between this pixel of the glass and the UI plane.
    const float gap    = glass.z;
    const float radius = min(blurSpread * gap, maxBlurRadius);

    // The whole blur kernel misses the UI: black.
    if (any(hit < -radius) || any(hit > size + radius)) {
        return half4(0.0h, 0.0h, 0.0h, 1.0h);
    }

    // Frosted glass also absorbs: dim in proportion to how much it scatters.
    const half attenuation = half(max(1.0 - darkening * radius, 0.0));

    const half3 center = layer.sample(bounds.xy + hit).rgb;
    if (radius < 0.01) {
        return half4(center * attenuation, 1.0h);
    }

    const float rotation = pixelRotation(position);
    const float c = cos(rotation), s = sin(rotation);
    half3 sum = half3(0.0h);
    for (int i = 0; i < 24; ++i) {
        const float2 v = kDisk[i];
        const float2 offset = float2(c * v.x - s * v.y, s * v.x + c * v.y);
        sum += layer.sample(bounds.xy + hit + radius * offset).rgb;
    }
    // Fade into the kernel continuously at the hinge and when crossing neutral.
    const half blend = half(smoothstep(0.0, 1.0, radius));
    return half4(mix(center, sum / 24.0h, blend) * attenuation, 1.0h);
}
