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




/**
I tried modeling clouds using perlin-worley noise as described by Andrew Schneider
in the chapter Real-Time Volumetric Cloudscapes of GPU Pro 7. There are two types
of worley fbm functions used, a low frequency one to model the cloud shapes, and
a high frequency one used to add finer details around the edges of the clouds. Finally,
a simple 2D ray march along the light direction to add some fake lighting and shadows
to the cloudscapes.
*/

#define CLOUD_COVERAGE .65

// Hash functions by Dave_Hoskins
float hash12(vec2 p)
{
	uvec2 q = uvec2(ivec2(p)) * uvec2(1597334673U, 3812015801U);
	uint n = (q.x ^ q.y) * 1597334673U;
	return float(n) * (1.0 / float(0xffffffffU));
}

vec2 hash22(vec2 p)
{
	uvec2 q = uvec2(ivec2(p))*uvec2(1597334673U, 3812015801U);
	q = (q.x ^ q.y) * uvec2(1597334673U, 3812015801U);
	return vec2(q) * (1.0 / float(0xffffffffU));
}

float remap(float x, float a, float b, float c, float d)
{
	return (((x - a) / (b - a)) * (d - c)) + c;
}

// Noise function by morgan3d
float perlinNoise(vec2 x) {
	vec2 i = floor(x);
	vec2 f = fract(x);

	float a = hash12(i);
	float b = hash12(i + vec2(1.0, 0.0));
	float c = hash12(i + vec2(0.0, 1.0));
	float d = hash12(i + vec2(1.0, 1.0));

	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

vec2 curlNoise(vec2 uv)
{
	vec2 eps = vec2(0., 1.);

	float n1, n2, a, b;
	n1 = perlinNoise(uv + eps);
	n2 = perlinNoise(uv - eps);
	a = (n1 - n2) / (2.*eps.y);

	n1 = perlinNoise(uv + eps.yx);
	n2 = perlinNoise(uv - eps.yx);
	b = (n1 - n2) / (2.*eps.y);

	return vec2(a, -b);
}

float worleyNoise(vec2 uv, float freq, float t, bool curl)
{
	uv *= freq;
	uv += t + (curl ? curlNoise(uv*2.) : vec2(0.)); // exaggerate the curl noise a bit

	vec2 id = floor(uv);
	vec2 gv = fract(uv);

	float minDist = 100.;
	for (float y = -1.; y <= 1.; ++y)
	{
		for (float x = -1.; x <= 1.; ++x)
		{
			vec2 offset = vec2(x, y);
			vec2 h = hash22(id + offset) * .8 + .1; // .1 - .9
			h += offset;
			vec2 d = gv - h;
			minDist = min(minDist, dot(d, d));
		}
	}

	return minDist;
}

float perlinFbm(vec2 uv, float freq, float t)
{
	uv *= freq;
	uv += t;
	float amp = .5;
	float noise = 0.;
	for (int i = 0; i < 8; ++i)
	{
		noise += amp * perlinNoise(uv);
		uv *= 2.;
		amp *= .5;
	}
	return noise;
}

// Worley fbm inspired by Andrew Schneider's Real-Time Volumetric Cloudscapes
// chapter in GPU Pro 7.
vec4 worleyFbm(vec2 uv, float freq, float t, bool curl)
{
	// worley0 isn't used for high freq noise, so we can save a few ops here
	float worley0 = 0.;
	if (freq < 4.)
		worley0 = 1. - worleyNoise(uv, freq * 1., t * 1., false);
	float worley1 = 1. - worleyNoise(uv, freq * 2., t * 2., curl);
	float worley2 = 1. - worleyNoise(uv, freq * 4., t * 4., curl);
	float worley3 = 1. - worleyNoise(uv, freq * 8., t * 8., curl);
	float worley4 = 1. - worleyNoise(uv, freq * 16., t * 16., curl);

	// Only generate fbm0 for low freq
	float fbm0 = (freq > 4. ? 0. : worley0 * .625 + worley1 * .25 + worley2 * .125);
	float fbm1 = worley1 * .625 + worley2 * .25 + worley3 * .125;
	float fbm2 = worley2 * .625 + worley3 * .25 + worley4 * .125;
	float fbm3 = worley3 * .75 + worley4 * .25;
	return vec4(fbm0, fbm1, fbm2, fbm3);
}

float clouds(vec2 uv, float t)
{
	float pfbm = perlinFbm(uv, 2., t);
	vec4 wfbmLowFreq = worleyFbm(uv, 2., t*2., false); // low freq without curl
	vec4 wfbmHighFreq = worleyFbm(uv, 8., t*4., true); // high freq with curl
	float perlinWorley = remap(abs(pfbm * 2. - 1.),
		wfbmLowFreq.r - CLOUD_COVERAGE, 1., 0., 1.);
	float worleyLowFreq = wfbmLowFreq.g * .625 + wfbmLowFreq.b * .25
		+ wfbmLowFreq.a * .125;
	float worleyHighFreq = wfbmHighFreq.g * .625 + wfbmHighFreq.b * .25
		+ wfbmHighFreq.a * .125;
	float c = remap(perlinWorley, worleyLowFreq - 1., 1., 0., 1.);
	c = remap(c, worleyHighFreq*.2, 1., 0., 1.);
	return max(0., c);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
	float aspectRatio = iResolution.x / iResolution.y;
	vec2 uv = fragCoord / iResolution.xy;
	uv.x *= aspectRatio;
	vec2 m = iMouse.xy / iResolution.y;
	float t = mod(iTime + 600., 7200.) * .03;

	// set up 2D ray march variables
	vec2 marchDist = vec2(48.) / iResolution.xy;
	float steps = 10.;
	float stepsInv = 1. / steps;
	vec2 sunDir = normalize(m - uv) * marchDist * stepsInv;
	vec2 marchUv = uv;
	float cloudColor = 0.;
	float cloudShape = clouds(uv, t);

	// 2D ray march loop
	for (float i = 0.; i < steps; ++i)
	{
		marchUv += sunDir;
		float c = clouds(marchUv, t);
		cloudColor += (cloudShape - c) * (1. - i * stepsInv);
	}

	cloudColor += cloudShape;

	vec3 skyCol = mix(vec3(.1, .5, .9), vec3(.1, .1, .9), uv.y);
	float sun = .002 / pow(length(uv - m), 1.7);
	vec3 col = vec3(0.);
	col = mix(skyCol, vec3(1.), sun);;
	col += cloudShape;
	col = mix(vec3(cloudColor*.5), col, 1. - cloudShape);
	fragColor = vec4(pow(col, vec3(1. / 2.2)), 1.0);
}






void main() { mainImage(fragColor, fragCoord); }