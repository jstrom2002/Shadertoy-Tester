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




//do you like shitty code?
//if not, then you probably dont want to read this then

mat3 lookat(vec3 fwd) {
	//vec3 fwd = normalize(obj - cam);
	vec3 up = vec3(0., 1., 0.) - fwd * fwd.y;
	vec3 rt = cross(fwd, up);
	return transpose(mat3(rt, up, fwd));
}

vec2 path(float t) {
	return sin(t * vec2(1., .83)) * .5 + sin(t * vec2(.3, .21)) * 1.;
}

vec2 path_dt(float t) {
	return cos(t * vec2(1., .83)) * vec2(1., .83) * .5 + cos(t * vec2(.3, .21)) * vec2(.3, .21) * 1.;
}

//copied from https://www.iquilezles.org/www/articles/gradientnoise/gradientnoise.htm
//i sli- i mean heavily modified the code to be more performant
//so that my toaster potato from the year 1683 can run it at 60 fps
float noise(vec3 x) {
	// grid
	ivec3 p = ivec3(floor(x));
	vec3 w = fract(x);

	vec3 u = w * w*w*(w*(w*6.0 - 15.0) + 10.0);

	// gradients & projections  -- SOME CHANNELS ARE CUBEMAPS
	float acc = 0.;
	vec3 ga = texelFetch(iChannel1, p + ivec3(0, 0, 0) & 31, 0).xyz * 2. - 1.;
	float va = dot(ga, w - vec3(0.0, 0.0, 0.0));
	vec3 gb = texelFetch(iChannel1, p + ivec3(1, 0, 0) & 31, 0).xyz * 2. - 1.;
	float vb = dot(gb, w - vec3(1.0, 0.0, 0.0));
	vec3 gc = texelFetch(iChannel1, p + ivec3(0, 1, 0) & 31, 0).xyz * 2. - 1.;
	float vc = dot(gc, w - vec3(0.0, 1.0, 0.0));
	vec3 gd = texelFetch(iChannel1, p + ivec3(1, 1, 0) & 31, 0).xyz * 2. - 1.;
	float vd = dot(gd, w - vec3(1.0, 1.0, 0.0));
	vec3 ge = texelFetch(iChannel1, p + ivec3(0, 0, 1) & 31, 0).xyz * 2. - 1.;
	float ve = dot(ge, w - vec3(0.0, 0.0, 1.0));
	vec3 gf = texelFetch(iChannel1, p + ivec3(1, 0, 1) & 31, 0).xyz * 2. - 1.;
	float vf = dot(gf, w - vec3(1.0, 0.0, 1.0));
	vec3 gg = texelFetch(iChannel1, p + ivec3(0, 1, 1) & 31, 0).xyz * 2. - 1.;
	float vg = dot(gg, w - vec3(0.0, 1.0, 1.0));
	vec3 gh = texelFetch(iChannel1, p + ivec3(1, 1, 1) & 31, 0).xyz * 2. - 1.;
	float vh = dot(gh, w - vec3(1.0, 1.0, 1.0));

	// interpolation
	return va +
		u.x*(vb - va) +
		u.y*(vc - va) +
		u.z*(ve - va) +
		u.x*u.y*(va - vb - vc + vd) +
		u.y*u.z*(va - vc - ve + vg) +
		u.z*u.x*(va - vb - ve + vf) +
		u.x*u.y*u.z*(-va + vb + vc - vd + ve - vf - vg + vh);
}

float sdf(vec3 p) {
	return .7 - length(p.xy - path(p.z)) + noise(p * 1.5) * .6 + noise(p * 5.) * .15;
}

//yet another piece of code copied from iq? amazing
//https://www.iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 sdf_normal(vec3 p) {
	const float h = 0.0001;
#define ZERO (min(iFrame,0))
	vec3 n = vec3(0.0);
	for (int i = ZERO; i < 4; i++)
	{
		vec3 e = 0.5773*(2.0*vec3((((i + 3) >> 1) & 1), ((i >> 1) & 1), (i & 1)) - 1.0);
		n += e * sdf(p + e * h);
	}
	return normalize(n);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
	vec2 pos = fragCoord;//vec2 pos = (fragCoord.xy * 2. - iResolution.xy) / iResolution.y;
	mat3 view_mat = lookat(normalize(vec3(path_dt(iTime + .5), 1.)));

	vec3 ro = vec3(path(iTime), iTime);
	vec3 rd = normalize(vec3(pos, 1.)) * view_mat;

	float totdist = 0.;
	for (int i = 0; i < 64; i++) {
		float currdist = sdf(ro + rd * totdist);
		totdist += currdist * .6;
		if (abs(currdist) < .001) break;
		if (totdist > 7.) break;
	}

	vec3 hitpos = ro + rd * totdist;
	vec3 normal = sdf_normal(hitpos);
	//triplanar texturing code sort of copied from https://developer.nvidia.com/gpugems/GPUGems3/gpugems3_ch01.html
	vec3 weights = max((abs(normal) - .2) * .7, 0.);
	weights /= dot(vec3(1.), weights);
	fragColor = (texture(iChannel0, hitpos.yz * .3) * weights.x
		+ texture(iChannel0, hitpos.xz * .3) * weights.y
		+ texture(iChannel0, hitpos.xy * .3) * weights.z) / totdist * (1. - dot(normal, rd)) / 2.;
	fragColor *= .5;
	fragColor += max(hitpos.z - ro.z - 3., 0.) * .2;
}






void main() { mainImage(fragColor, fragCoord); }