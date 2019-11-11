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




// Based upon: https://www.shadertoy.com/view/XdlSD4

// I always liked mandelbox_ryu made by EvilRyu
// Was tinkering a bit with the code and came up with this which at least I liked.

// Uses very simple occlusion based lighting which made it look more like a structure
// of bones than my other futile lighting attemps.

const float fixed_radius2 = 1.9;
const float min_radius2 = 0.5;
const float folding_limit = 1.0;
const float scale = -2.8;
const int   max_iter = 120;
const vec3  bone = vec3(0.89, 0.855, 0.788);

void sphere_fold(inout vec3 z, inout float dz) {
	float r2 = dot(z, z);
	if (r2 < min_radius2) {
		float temp = (fixed_radius2 / min_radius2);
		z *= temp;
		dz *= temp;
	}
	else if (r2 < fixed_radius2) {
		float temp = (fixed_radius2 / r2);
		z *= temp;
		dz *= temp;
	}
}

void box_fold(inout vec3 z, inout float dz) {
	z = clamp(z, -folding_limit, folding_limit) * 2.0 - z;
}

float sphere(vec3 p, float t) {
	return length(p) - t;
}

float torus(vec3 p, vec2 t) {
	vec2 q = vec2(length(p.xz) - t.x, p.y);
	return length(q) - t.y;
}

float mb(vec3 z) {
	vec3 offset = z;
	float dr = 1.0;
	float fd = 0.0;
	for (int n = 0; n < 5; ++n) {
		box_fold(z, dr);
		sphere_fold(z, dr);
		z = scale * z + offset;
		dr = dr * abs(scale) + 1.0;
		float r1 = sphere(z, 5.0);
		float r2 = torus(z, vec2(8.0, 1));
		float r = n < 4 ? r2 : r1;
		float dd = r / abs(dr);
		if (n < 3 || dd < fd) {
			fd = dd;
		}
	}
	return fd;
}

float df(vec3 p) {
	float d1 = mb(p);
	return d1;
}


float hash(vec2 p) {
	float h = dot(p, vec2(127.1, 311.7));
	return fract(sin(h)*43758.5453123);
}

float intersect(vec3 ro, vec3 rd, out int iter) {
	float res;
	float r = hash(ro.xy + ro.xz + ro.yz);
	float t = 10.0*mix(0.01, 0.02, r);
	iter = max_iter;

	for (int i = 0; i < max_iter; ++i) {
		vec3 p = ro + rd * t;
		res = df(p);
		if (res < 0.001 * t || res > 20.) {
			iter = i;
			break;
		}
		t += res;
	}

	if (res > 20.) t = -1.;
	return t;
}

float ambientOcclusion(vec3 p, vec3 n) {
	float stepSize = 0.012;
	float t = stepSize;

	float oc = 0.0;

	for (int i = 0; i < 12; i++) {
		float d = df(p + n * t);
		oc += t - d;
		t += stepSize;
	}

	return clamp(oc, 0.0, 1.0);
}

vec3 normal(in vec3 pos) {
	vec3  eps = vec3(.001, 0.0, 0.0);
	vec3 nor;
	nor.x = df(pos + eps.xyy) - df(pos - eps.xyy);
	nor.y = df(pos + eps.yxy) - df(pos - eps.yxy);
	nor.z = df(pos + eps.yyx) - df(pos - eps.yyx);
	return normalize(nor);
}

vec3 lighting(vec3 p, vec3 rd, int iter) {
	vec3 n = normal(p);
	float fake = float(iter) / float(max_iter);
	float fakeAmb = exp(-fake * fake*9.0);
	float amb = ambientOcclusion(p, n);

	vec3 col = vec3(mix(1.0, 0.125, pow(amb, 3.0)))*vec3(fakeAmb)*bone;
	return col;
}

vec3 post(vec3 col, vec2 q) {
	col = pow(clamp(col, 0.0, 1.0), vec3(0.65));
	col = col * 0.6 + 0.4*col*col*(3.0 - 2.0*col);  // contrast
	col = mix(col, vec3(dot(col, vec3(0.33))), -0.5);  // satuation
	col *= 0.5 + 0.5*pow(19.0*q.x*q.y*(1.0 - q.x)*(1.0 - q.y), 0.7);  // vigneting
	return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
	vec2 q = fragCoord.xy / iResolution.xy;
	vec2 uv = fragCoord;//-1.0 + 2.0*q;
	uv.x *= iResolution.x / iResolution.y;

	float stime = sin(iTime*0.1);
	float ctime = cos(iTime*0.1);

	vec3 ta = vec3(0.0, 0.0, 0.0);
	vec3 ro = vec3(3.0*stime, 2.0*ctime, 5.0 + 1.0*stime);
	vec3 cf = normalize(ta - ro);
	vec3 cs = normalize(cross(cf, vec3(0.0, 1.0, 0.0)));
	vec3 cu = normalize(cross(cs, cf));
	vec3 rd = normalize(uv.x*cs + uv.y*cu + 2.8*cf);  // transform from view to world

	vec3 bg = mix(bone*0.5, bone, smoothstep(-1.0, 1.0, uv.y));
	vec3 col = bg;

	vec3 p = ro;

	int iter = 0;

	float t = intersect(ro, rd, iter);

	if (t > -0.5) {
		p = ro + t * rd;
		col = lighting(p, rd, iter);
		col = mix(col, bg, 1.0 - exp(-0.001*t*t));
	}


	col = post(col, q);
	fragColor = vec4(col.x, col.y, col.z, 1.0);
}





void main() { mainImage(fragColor, fragCoord); }