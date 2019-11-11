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







//SMOKE SHADER
void MakeViewRay(in vec2 fragCoord, out vec3 eye, out vec3 ray)
{
	vec2 ooR = 1. / iResolution.xy;
	vec2 q = fragCoord.xy * ooR;
	vec2 p = 2.*q - 1.;
	p = fragCoord;//ADJUST FOR MY COMPUTER
	p.x *= iResolution.x * ooR.y;

	vec3 lookAt = vec3(0., 0., 0. + iTime * .0);
	eye = vec3(2.5, 3., -2.5) * 1.5 + lookAt;

	// camera frame
	vec3 fo = normalize(lookAt - eye);
	vec3 ri = normalize(vec3(fo.z, 0., -fo.x));
	vec3 up = normalize(cross(fo, ri));

	float fov = .25;

	ray = normalize(fo + fov * p.x*ri + fov * p.y*up);
}

//#define CHEAPER_NOISES

float Noise(in vec3 x, float lod_bias)
{
	vec3 p = floor(x);
	vec3 f = fract(x);
#ifndef CHEAPER_NOISES	
	f = f * f*(3.0 - 2.0*f);	//not terribly noticeable for higher freq noises anyway
#endif

	vec2 uv = (p.xy + vec2(37.0, 17.0)*p.z) + f.xy;
#ifdef CHEAPER_NOISES	
	vec2 rg = texture(iChannel1, uv*(1. / 256.0), lod_bias).yx;
#else	
	vec2 rg = texture(iChannel1, (uv + 0.5) / 256.0, lod_bias).yx;
#endif	
	return mix(rg.x, rg.y, f.z);
}

vec2 Noise2(in vec3 x, float lod_bias)
{
	vec3 p = floor(x);
	vec3 f = fract(x);
	vec2 uv = (p.xy + vec2(37.0, 17.0)*p.z) + f.xy;
	vec4 rg = texture(iChannel1, uv*(1. / 256.0), lod_bias).yxwz;
	return mix(rg.xz, rg.yw, f.z);
}

vec4 BlendUnder(vec4 accum, vec4 col)
{
	col = clamp(col, vec4(0), vec4(1));
	col.rgb *= col.a;
	accum += col * (1.0 - accum.a);
	return accum;
}

vec2 Turbulence2(vec3 p, float lod)
{
	vec2 t = vec2(0.);
	float oof = 1.;
	for (int i = 0; i < 5; i++)
	{
		t += abs(Noise2(p, lod))*oof;
		oof *= 0.5;
		p *= 2.7;	//bigger number, more detail
	}

	return t - vec2(1.);
}

vec2 PhaseShift2(vec3 p)
{
	float g = (p.y + 2.);	 //fall off with height

	float lod = -100.;
	//g*2.;

	p *= .4;

	p.x += g * iTime * .02;
	p.y += -iTime;


	return g * Turbulence2(p, lod);
}

float Density(vec3 p)
{
	//rotate Z randomly about Y  =~ swirly space
	float t = Noise(p, -100.);
	t *= (180. / 3.1415927)*.005 * (p.y + 2.);
	float s = sin(t); float c = cos(t);
	p.z = p.x*s + p.z*c;

	//
	p.xz += PhaseShift2(p);

	//repeat it just because we can
	float f = 3.;
	p.xz = mod(p.xz, f) - f * .5;

	//column as distance from y axis
	float rx = dot(p.xz, p.xz)*5. - p.y*0.25;
	if (rx < 1.)
	{
		float s = sin(3.1415927*rx);	//hollow tube
		return s * s*s*s;
	}

	return 0.;
}

vec4 March(vec4 accum, vec3 viewP, vec3 viewD, vec2 mM)
{
//exponential stepping
#define SHQ	
//#define MEDQ	
//#define YUCKQ	
#ifdef SHQ
#define STEPS	128	
	float slices = 512.;
#endif	
#ifdef MEDQ
#define STEPS	64	
	float slices = 256.;
#endif	
#ifdef YUCKQ	
#define STEPS	32	
	float slices = 128.;
#endif

	float Far = 10.;

	float sliceStart = log2(mM.x)*(slices / log2(Far));
	float sliceEnd = log2(mM.y)*(slices / log2(Far));

	float last_t = mM.x;

	for (int i = 0; i < STEPS; i++)
	{
		sliceStart += 1.;
		float sliceI = sliceStart;// + float(i);	//advance an exponential step
		float t = exp2(sliceI*(log2(Far) / slices));	//back to linear

		vec3 p = viewP + t * viewD;

		float dens = Density(p);
		dens *= (t - last_t)*1.5;

		//color gradient
		vec3 c = mix(vec3(0.5, 0.6, .7), vec3(0.2), p.y);

		c *= min(-t * .6 + 7., 1.);

		accum = BlendUnder(accum, vec4(c, dens));

		last_t = t;
	}

	return accum;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
	vec3 viewP, viewD;
	MakeViewRay(fragCoord, viewP, viewD);

	//ground plane
	float floor_height = -1.;
	float floor_intersect_t = (-viewP.y + floor_height) / (viewD.y);
	vec3 p = viewP + viewD * floor_intersect_t;
	vec3 c = texture(iChannel0, (p.xz)*0.125 + vec2(0.575, 0.575), floor_intersect_t*0. - 16.).xyz;
	c = pow(c, vec3(2.2));
	c *= 0.2;
	float ceil_intersect_t = (-viewP.y + 1.) / (viewD.y);

	vec4 a = March(vec4(0), viewP, viewD, vec2(ceil_intersect_t, floor_intersect_t));
	c = BlendUnder(a, vec4(c, 1.)).xyz;
	c = pow(c, vec3(1. / 2.2));
	fragColor = vec4(c, 1.0);
}//////////////////////////////////////////////////////////////////////////////////////////////





void main() { mainImage(fragColor, fragCoord); }