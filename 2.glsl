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





//MINIMAL RAY TRACER by Michael Walczyk -- see: http://www.michaelwalczyk.com/blog/2017/5/25/ray-marching
float sphere(vec3 ray, vec3 dir, vec3 center, float radius)
{
	vec3 rc = ray - center;
	float c = dot(rc, rc) - (radius*radius);
	float b = dot(dir, rc);
	float d = b * b - c;
	float t = -b - sqrt(abs(d));
	float st = step(0.0, min(t, d));
	return mix(-1.0, t, st);
}

vec3 background(float t, vec3 rd)
{
	vec3 light = normalize(vec3(sin(t), 0.6, cos(t)));
	float sun = max(0.0, dot(rd, light));
	float sky = max(0.0, dot(rd, vec3(0.0, 1.0, 0.0)));
	float ground = max(0.0, -dot(rd, vec3(0.0, 1.0, 0.0)));
	return
		(pow(sun, 256.0) + 0.2*pow(sun, 2.0))*vec3(2.0, 1.6, 1.0) +
		pow(ground, 0.5)*vec3(0.4, 0.3, 0.2) +
		pow(sky, 1.0)*vec3(0.5, 0.6, 0.7);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
	vec2 uv = fragCoord;//(-1.0 + 2.0*fragCoord.xy / iResolution.xy) * vec2(iResolution.x / iResolution.y, 1.0);
	for (int i = -1; i < 1; i++) {

		vec3 ro = vec3(0.0, 0.0, -3.0);
		vec3 rd = normalize(vec3(uv, 1.0));
		vec3 p = vec3(i*0.6);
		float t = sphere(ro, rd, p, 0.4);
		vec3 nml = normalize(p - (ro + rd * t));
		vec3 bgCol = background(iTime, rd);
		rd = reflect(rd, nml);
		vec3 col = background(iTime, rd) * vec3(0.9, 0.8, 1.0);
		fragColor += vec4(mix(bgCol, col, step(0.0, t)), 1.0);
	
	}
}////////////////////////////////////////////////////////////////////////////////////////////////////////////





void main() { mainImage(fragColor, fragCoord); }