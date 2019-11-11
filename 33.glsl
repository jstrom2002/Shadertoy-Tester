#version 330 core
out vec4 fragColor;
in vec2 fragCoord;

uniform vec3      iResolution;           // viewport resolution (in pixels)
uniform float     iTime;                 // shader playback time (in seconds)
uniform float     iTimeDelta;            // render time (in seconds)
uniform int       iFrame;                // shader playback frame
uniform float     iFrameRate;            // shader playback framerate
uniform float     iChannelTime[4];       // channel playback time (in seconds)
uniform vec3      iChannelResolution[4]; // channel resolution (in pixels)
uniform vec4      iMouse;                // mouse pixel coords. xy: current (if MLB down), zw: click
uniform sampler2D iChannel0;			// input channel. XX = 2D/Cube
uniform sampler2D iChannel1;			// input channel. XX = 2D/Cube
uniform sampler2D iChannel2;			// input channel. XX = 2D/Cube
uniform sampler2D iChannel3;			// input channel. XX = 2D/Cube
uniform vec4      iDate;                 // (year, month, day, time in seconds)
uniform float     iSampleRate = 441000;           // sound sample rate (i.e., 44100)
//======================================================================================================
//======================================================================================================



/////////////////////////////
// BRADY'S VOLUMETRIC FIRE //
/////////////////////////////

// CREDITS
// Thanks to @shnitzelkiller & @iq for inspiration and help
// noise: https://github.com/BrianSharpe/Wombat/blob/master/Value3D.glsl
// saturation: https://github.com/AnalyticalGraphicsInc/cesium/blob/master/Source/Shaders/Builtin/Functions/saturation.glsl
// fnoise: https://www.shadertoy.com/view/Xsd3R2

float noise(vec3 P)
{
	vec3 Pi = floor(P);
	vec3 Pf = P - Pi;
	vec3 Pf_min1 = Pf - 1.0;
	Pi.xyz = Pi.xyz - floor(Pi.xyz * (1.0 / 69.0)) * 69.0;
	vec3 Pi_inc1 = step(Pi, vec3(69.0 - 1.5)) * (Pi + 1.0);
	vec4 Pt = vec4(Pi.xy, Pi_inc1.xy) + vec2(50.0, 161.0).xyxy;
	Pt *= Pt;
	Pt = Pt.xzxz * Pt.yyww;
	vec2 hash_mod = vec2(1.0 / (635.298681 + vec2(Pi.z, Pi_inc1.z) * 48.500388));
	vec4 hash_lowz = fract(Pt * hash_mod.xxxx);
	vec4 hash_highz = fract(Pt * hash_mod.yyyy);
	vec3 blend = Pf * Pf * Pf * (Pf * (Pf * 6.0 - 15.0) + 10.0);
	vec4 res0 = mix(hash_lowz, hash_highz, blend.z);
	vec4 blend2 = vec4(blend.xy, vec2(1.0 - blend.xy));
	return dot(res0, blend2.zxzx * blend2.wwyy);
}

float fnoise(vec3 p, float time)
{
	float f = 0.0;
	p = p - vec3(0.0, 1.0, 0.0) * .5 * time;
	p = p * 3.0;
	f += 0.50000 * noise(p); p = 2.0 * p;
	f += 0.25000 * noise(p); p = 2.0 * p;
	f += 0.12500 * noise(p); p = 2.0 * p;
	f += 0.06250 * noise(p); p = 2.0 * p;
	f += 0.03125 * noise(p);
	return f;
}

float model(in vec3 p)
{
	p.y *= .7;
	float sphere = length(p) - .8;
	float res = sphere + fnoise(p*1.5, iTime*3.)* .4;
	return res * .8;
}

float raymarch(in vec3 ro, in vec3 rd)
{
	float dist = 0.;
	for (int i = 0; i < 30; i++)
	{
		float m = model(ro + rd * dist);
		dist += m;

		if (m < .01) return dist;
		else if (dist > 2.) break;
	}
	return -1.;
}

vec3 hueShift(vec3 color, float hueAdjust) {

	const vec3  kRGBToYPrime = vec3(0.299, 0.587, 0.114);
	const vec3  kRGBToI = vec3(0.596, -0.275, -0.321);
	const vec3  kRGBToQ = vec3(0.212, -0.523, 0.311);

	const vec3  kYIQToR = vec3(1.0, 0.956, 0.621);
	const vec3  kYIQToG = vec3(1.0, -0.272, -0.647);
	const vec3  kYIQToB = vec3(1.0, -1.107, 1.704);

	float   YPrime = dot(color, kRGBToYPrime);
	float   I = dot(color, kRGBToI);
	float   Q = dot(color, kRGBToQ);
	float   hue = atan(Q, I);
	float   chroma = sqrt(I * I + Q * Q);

	hue += hueAdjust;

	Q = chroma * sin(hue);
	I = chroma * cos(hue);

	vec3    yIQ = vec3(YPrime, I, Q);

	return vec3(dot(yIQ, kYIQToR), dot(yIQ, kYIQToG), dot(yIQ, kYIQToB));

}

vec3 saturation(vec3 rgb, float adjustment)
{
	const vec3 W = vec3(0.2125, 0.7154, 0.0721);
	vec3 intensity = vec3(dot(rgb, W));
	return mix(intensity, rgb, adjustment);
}

vec3 background(in vec2 p)
{
	return vec3(length(p))*.25;
}

vec3 volume(in vec3 p, in vec3 rd, in vec3 ld, in vec2 sp)
{
	vec3 op = p;
	float trans = 1.0;
	float td = 0.0;
	float dif = 0.0;
	float emit = 0.0;
	float steps = 30.; // increase to smooth

	// march
	for (float i = 0.; i < steps; i++)
	{
		float m = model(p);
		p += rd * .03;

		float dens = 1. - smoothstep(0., .35, -m);
		td += dens;
		trans *= dens;

		if (td > 1.0 && dif <= 0.)
		{
			td = 1.;
			dif = clamp(1. - model(p - .1*ld), 0., 1.);
			emit = pow(smoothstep(-.3, 0., model(p)), 4.);
		}
	}

	trans = (1. - pow(td / steps, 4.5));
	trans = smoothstep(0., 1., trans);
	float emitmod = (emit*trans)*.8 + .2;

	// light
	vec3 lin = vec3(.3, .2, .9);
	lin = hueShift(lin, 4.2 + -trans * .6 + dif * .5);
	lin *= emitmod;

	// bright/sat/contrast
	lin = saturation(lin, pow(trans, .5)*.4);
	lin *= 5.;
	lin -= vec3(.4);

	return mix(background(sp), lin, pow(trans, 1.25));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
	vec2 p = fragCoord;//(fragCoord - .5*iResolution.xy) / iResolution.y;

	float rs = .5;
	vec3 ro = vec3(cos(iMouse.x / 100.), 1., sin(iMouse.x / 100.))*1.35;
	vec3 ta = vec3(0., 0.1, .0);

	vec3 w = normalize(ta - ro);
	vec3 u = normalize(cross(w, vec3(0., 1., 0.)));
	vec3 v = normalize(cross(u, w));
	mat3 mat = mat3(u, v, w);
	vec3 rd = normalize(mat*vec3(p.xy, 1.));

	float dist = raymarch(ro, rd);
	vec3 ld = vec3(-1., 1., 0.);
	vec3 col = dist > 0. ? volume(ro + rd * dist, rd, ld, p) : background(p);

	fragColor = vec4(col, 1.0);
}




void main() { mainImage(fragColor, fragCoord); }