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



/*========================================================
TEST SHADER by Jeff Strom -- mostly just hash and noise 
functions that I'm playing with to try to create shapes
=========================================================*/
float hash1(vec2 p)
{
	p = 50.0*fract(p*0.3183099);
	return fract(p.x*p.y*(p.x + p.y));
}

float hash1(float n)
{
	return fract(n*17.0*fract(n*0.3183099));
}

vec2 hash2(float n) { return fract(sin(vec2(n, n + 1.0))*vec2(43758.5453123, 22578.1459123)); }


vec2 hash2(vec2 p)
{
	const vec2 k = vec2(0.3183099, 0.3678794);
	p = p * k + k.yx;
	return fract(16.0 * k*fract(p.x*p.y*(p.x + p.y)));
}


vec3 noised(in vec2 x)
{
	vec2 p = floor(x);
	vec2 w = fract(x);

	vec2 u = w * w*w*(w*(w*6.0 - 15.0) + 10.0);
	vec2 du = 30.0*w*w*(w*(w - 2.0) + 1.0);

	float a = hash1(p + vec2(0, 0));
	float b = hash1(p + vec2(1, 0));
	float c = hash1(p + vec2(0, 1));
	float d = hash1(p + vec2(1, 1));

	float k0 = a;
	float k1 = b - a;
	float k2 = c - a;
	float k4 = a - b - c + d;

	return vec3(-1.0 + 2.0*(k0 + k1 * u.x + k2 * u.y + k4 * u.x*u.y),
		2.0* du * vec2(k1 + k4 * u.y,
			k2 + k4 * u.x));
}

float noise(in vec2 x)
{
	vec2 p = floor(x);
	vec2 w = fract(x);
	vec2 u = w * w*w*(w*(w*6.0 - 15.0) + 10.0);

#if 0
	p *= 0.3183099;
	float kx0 = 50.0*fract(p.x);
	float kx1 = 50.0*fract(p.x + 0.3183099);
	float ky0 = 50.0*fract(p.y);
	float ky1 = 50.0*fract(p.y + 0.3183099);

	float a = fract(kx0*ky0*(kx0 + ky0));
	float b = fract(kx1*ky0*(kx1 + ky0));
	float c = fract(kx0*ky1*(kx0 + ky1));
	float d = fract(kx1*ky1*(kx1 + ky1));
#else
	float a = hash1(p + vec2(0, 0));
	float b = hash1(p + vec2(1, 0));
	float c = hash1(p + vec2(0, 1));
	float d = hash1(p + vec2(1, 1));
#endif

	return -1.0 + 2.0*(a + (b - a)*u.x + (c - a)*u.y + (a - b - c + d)*u.x*u.y);
}

//==========================================================================================
// fbm constructions
//==========================================================================================

const mat3 m3 = mat3(0.00, 0.80, 0.60,
	-0.80, 0.36, -0.48,
	-0.60, -0.48, 0.64);
const mat3 m3i = mat3(0.00, -0.80, -0.60,
	0.80, 0.36, -0.48,
	0.60, -0.48, 0.64);
const mat2 m2 = mat2(0.80, 0.60,
	-0.60, 0.80);
const mat2 m2i = mat2(0.80, -0.60,
	0.60, 0.80);

//------------------------------------------------------------------------------------------

float fbm_4(in vec3 x)
{
	float f = 2.0;
	float s = 0.5;
	float a = 0.0;
	float b = 0.5;
	for (int i = 0; i < 4; i++)
	{
		float n = noise(x.xy);
		a += b * n;
		b *= s;
		x = f * m3*x;
	}
	return a;
}

vec4 fbmd_8(in vec3 x)
{
	float f = 1.92;
	float s = 0.5;
	float a = 0.0;
	float b = 0.5;
	vec3  d = vec3(0.0);
	mat3  m = mat3(1.0, 0.0, 0.0,
		0.0, 1.0, 0.0,
		0.0, 0.0, 1.0);
	for (int i = 0; i < 7; i++)
	{
		vec4 n = vec4(noised(x.xy), 1.0);
		a += b * n.x;          // accumulate values		
		d += b * m*n.yzw;      // accumulate derivatives
		b *= s;
		x = f * m3*x;
		m = f * m3i*m;
	}
	return vec4(a, d);
}

float fbm_9(in vec2 x)
{
	float f = 1.9;
	float s = 0.55;
	float a = 0.0;
	float b = 0.5;
	for (int i = 0; i < 9; i++)
	{
		float n = noise(x);
		a += b * n;
		b *= s;
		x = f * m2*x;
	}
	return a;
}

vec3 fbmd_9(in vec2 x)
{
	float f = 1.9;
	float s = 0.55;
	float a = 0.0;
	float b = 0.5;
	vec2  d = vec2(0.0);
	mat2  m = mat2(1.0, 0.0, 0.0, 1.0);
	for (int i = 0; i < 9; i++)
	{
		vec3 n = noised(x);
		a += b * n.x;          // accumulate values		
		d += b * m*n.yz;       // accumulate derivatives
		b *= s;
		x = f * m2*x;
		m = f * m2i*m;
	}
	return vec3(a, d);
}

float fbm_4(in vec2 x)
{
	float f = 1.9;
	float s = 0.55;
	float a = 0.0;
	float b = 0.5;
	for (int i = 0; i < 4; i++)
	{
		float n = noise(x);
		a += b * n;
		b *= s;
		x = f * m2*x;
	}
	return a;
}


void mainImage(out vec4 fragColor, vec2 fragCoord) {

	vec2 coord = fragCoord;
	//vec2 coord = (-iResolution.xy + 2.0*(fragCoord+1.0)) / iResolution.y;//convert NDC to Shadertoy coords

	// Set the camera
	float speed = 1.9;
	vec3 direction = normalize(vec3(coord, 1.0));
	vec3 origin = vec3(1225.0 + iTime * speed, 1225.0 + iTime * speed, 1225.0 + iTime * speed);
	vec3 forward = -origin;
	vec3 up = vec3(sin(iTime * 0.3), 2.0, 0.0);
	mat3 rotation;
	rotation[2] = normalize(forward);
	rotation[0] = vec3(1, 0, 0);
	rotation[1] = vec3(0, 1, 0);
	direction = rotation * direction;

	float zoom = 3.0;
	vec3 tempCol;
	vec3 temp = noised(origin.xy*direction.xy * zoom);
	if (dot(temp, temp) > 2.4) { tempCol += temp; }
	tempCol *= fbmd_8(origin*direction * zoom).xzy;
	tempCol += 0.4;
	tempCol *= vec3(0.1, 0.7, 1.0);
	fragColor = vec4(tempCol, 1);
}/////////////////////////////////////////////////////////////////////////////////////////////////





void main() { mainImage(fragColor, fragCoord); }