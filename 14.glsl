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




//FLUID SIM SHADER by Clement Roche -- https://codepen.io/ClementRoche/pen/WmErMZ
float map(float value, float min1, float max1, float min2, float max2) {
	return ((value - min1) / (max1 - min1)) * (max2 - min2) + min2;
}


vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float random(in vec2 _st) {
	return fract(sin(dot(_st.xy,
		vec2(12.9898, 78.233)))*
		43758.5453123);
}

// Based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float noise(in vec2 _st) {
	vec2 i = floor(_st);
	vec2 f = fract(_st);

	// Four corners in 2D of a tile
	float a = random(i);
	float b = random(i + vec2(1.0, 0.0));
	float c = random(i + vec2(0.0, 1.0));
	float d = random(i + vec2(1.0, 1.0));

	vec2 u = f * f * (3.0 - 2.0 * f);

	return mix(a, b, u.x) +
		(c - a)* u.y * (1.0 - u.x) +
		(d - b) * u.x * u.y;
}

#define NUM_OCTAVES 5

float fbm(in vec2 _st) {
	float v = 0.0;
	float a = 0.5;
	vec2 shift = vec2(100.0);
	// Rotate to reduce axial bias
	mat2 rot = mat2(cos(0.5), sin(0.5),
		-sin(0.5), cos(0.50));
	for (int i = 0; i < NUM_OCTAVES; ++i) {
		v += a * noise(_st);
		_st = rot * _st * 2.0 + shift;
		a *= 0.5;
	}
	return v;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){
	//vec2 st = gl_FragCoord.xy / u_resolution.y;
	vec2 st = fragCoord;
	vec2 mouse = iMouse.xy;//u_mouse.xy / u_resolution.y;
	//st += st * abs(sin(time*0.1)*3.0);
	vec3 color = vec3(0.0);

	vec3 darker = vec3(45.0 / 255.0, 107.0 / 255.0, 55.0 / 255.0);
	vec3 lighter = vec3(80.0 / 255.0, 176.0 / 255.0, 92.0 / 255.0);

	vec2 q = vec2(0.);
	q.x = fbm(st + 0.02*iTime);
	q.y = fbm(st + vec2(1.0));

	vec2 r = vec2(0.);
	r.x = fbm(
		st
		+ 10.0*q
	//	+ vec2(1.0*mouse.x, 9.2*mouse.y)
		+ 0.15*iTime
	);
	r.y = fbm(
		st
		+ 25.0*q
	//	+ vec2(5.0*mouse.x, 2.8*mouse.y)
		+ 0.126*iTime
	);

	float f = fbm(st + r);

	color = mix(darker,
		lighter,
		clamp((f*f)*4.0, 1.0, 1.0));

	color = mix(color,
		darker,
		clamp(length(q), 1.0, 1.0));

	color = mix(color,
		lighter,
		clamp(length(r.x), 1.0, 1.0));


	vec4 rgb = vec4(vec4((f*f*f + .6*f*f + .5)*color, 1.));

	fragColor = rgb;
}//////////////////////////////////////////////////////////////////////////






void main() { mainImage(fragColor, fragCoord); }