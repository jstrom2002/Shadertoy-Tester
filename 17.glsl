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


//	Cavernous  Fly Though
// 	leaning from shaders
//
// 	https://www.shadertoy.com/view/wdXSWn
//	https://www.shadertoy.com/view/XlXXWj
//
// 	triangle noise used create a ray
//	marched tunnel. path is created with
//	sine wave then use dot product to cut
//	into sdf shape.
//
//////////////////////////////////////////

#define MAX_DIST 	50.0
#define MIN_DIST 	0.001
#define MAX_STEPS 	210

#define PI  		3.1415926
#define PI2 		6.2831853

// Single rotation function - return matrix
mat2 r2(float a)
{
	float c = cos(a); float s = sin(a);
	return mat2(c, s, -s, c);
}

// iMouse pos function 
vec3 get_mouse(vec3 ro)
{
	float x = iMouse.xy == vec2(0) ? -.2 :
		(iMouse.y / iResolution.y * .5 - 0.25) * PI;
	float y = iMouse.xy == vec2(0) ? .0 :
		-(iMouse.x / iResolution.x * 1.0 - .5) * PI;
	float z = 0.0;

	ro.zy *= r2(x);
	ro.zx *= r2(y*.5);

	return ro;
}

float smin(in float a, in float b, float k)
{
	float h = max(k - abs(a - b), 0.);
	return min(a, b) - h * h / (k*4.);
}

vec3 tri(in vec3 x) {
	return abs(x - floor(x) - .5); // The triangle function by Nimitz
}

// surface function that culls the space to create
// the cavern effect. Given a point return noise gradient // Shane
float surf(in vec3 p) {
	// added displacement for rounded rocks.
	float dsp = sin(2. * p.x) * sin(7.5 * p.y) * sin(10. * p.z) * .13;

	float n = dot(tri(p*1.5), vec3(.4, 1.25, .3)) + dsp;
	p.xz = vec2(p.x + p.z, p.z - p.y) * .73;
	n = dot(tri(p*1.75 + tri(p*.15).yzx), vec3(.242)) + n;
	return n;
}

// path functions 
vec2 path(in float z) {
	vec2 wv1 = vec2(2.3*sin(z * .15), 1.4*cos(z * .25));
	vec2 wv2 = vec2(1.2*sin(z * .49), 2.1*sin(z * .25));
	return wv1 + wv2;
}

vec2 path2(in float z) {
	vec2 wv1 = vec2(2.4*cos(z * .35), 1.4*sin(z * .15));
	vec2 wv2 = vec2(1.3*sin(z * .59), 1.8*cos(z * .21));
	return wv1 + wv2;
}

vec2 map(in vec3 pos) {
	vec3 p = pos - vec3(0., 0., 0);
	vec2 res = vec2(0., -1.);

	// so if I get this correctly - we're taking a point on the
	// path and getting and offset - noise that cuts into the 
	// filled sdf space. Im still not sure about the xy to z thing.
	vec2 tun = p.xy - path(p.z);
	vec2 tun2 = p.xy - path2(p.z);
	float d = 1. - smin(length(tun), length(tun2), .5) + (0.5 - surf(p));

	res = vec2(d, 3.);

	// make some balls - added at the end
	// but eh kind of nice - or just a 
	// placeholder

	vec3 b = pos - vec3(0., .2, 0.);
	vec3 bb = vec3(b.x, b.y, mod(b.z - .5, 1.) - .5);
	bb.xy -= path2(b.z);
	float d2 = length(bb) - .05;
	if (d2 < res.x) res = vec2(d2, 2.);

	return res;
}

vec3 get_normal(in vec3 p) {
	float d = map(p).x;
	vec2 e = vec2(.01, .0);
	vec3 n = d - vec3(
		map(p - e.xyy).x,
		map(p - e.yxy).x,
		map(p - e.yyx).x
	);
	return normalize(n);
}

vec2 ray_march(in vec3 ro, in vec3 rd)
{
	float depth = 0.0;
	float m = -1.;
	for (int i = 0; i < MAX_STEPS;i++)
	{
		vec3 pos = ro + depth * rd;
		vec2 dist = map(pos);
		m = dist.y;

		if (dist.x < 0.001*depth) break;

		if (depth > MAX_DIST)  break;
		depth += abs(dist.x*.25); // if I dont have the .25 if fails or is
	   // way too distorted. I dont know what im doing wrong in my marchers
	   // but feel i have the issue a lot

	}
	if (depth > MAX_DIST) m = -1.;
	return vec2(depth, m);

}

// Tri-Planar blending function. Based on an old Nvidia tutorial.
// https://www.shadertoy.com/view/XlXXWj
vec3 tex3D(sampler2D tex, in vec3 p, in vec3 n)
{
	n = max((abs(n) - 0.2)*7., 0.001);
	n /= (n.x + n.y + n.z);
	p = (texture(tex, p.yz)*n.x +
		texture(tex, p.zx)*n.y +
		texture(tex, p.xy)*n.z).xyz;
	return p * p;
}

vec3 checkerd(in vec2 pos) {
	vec2 f = fract(pos.xy * 40.5) - 0.5;
	return vec3(f.x*f.y > 0.0 ? vec3(.9, .7, .0) : vec3(.8, .3, .0));
}

vec3 get_color(in float m, in vec3 pos) {
	vec3 mate = vec3(.8);
	vec3 nor = get_normal(pos);

	if (m == 3.) {
		float ff = sin(pos.zy*1.76).y;
		float fy = fract(pos*6.3).y + tri(pos*11.6).y;
		mate = vec3(.45, .05 + fy, .0)*fy*vec3(0.3, .06, ff);
		mate *= tex3D(iChannel0, pos*2., nor*2.);
	}
	if (m == 2.) {
		mate = checkerd(pos.zy);
	}
	if (m == 1.) {
		mate = vec3(1.0);
	}

	return mate;
}

// Texture bump mapping. Four tri-planar lookups, or 12 texture lookups in total.
float gscale(vec3 p) { return p.x*0.299 + p.y*0.587 + p.z*0.114; }
vec3 doBumpMap(sampler2D tex, in vec3 p, in vec3 nor, float factor) {

	const float es = 0.001;
	float ref = gscale(tex3D(tex, p, nor));
	vec3 grad = vec3(
		gscale(tex3D(tex, vec3(p.x - es, p.y, p.z), nor)) - ref,
		gscale(tex3D(tex, vec3(p.x, p.y - es, p.z), nor)) - ref,
		gscale(tex3D(tex, vec3(p.x, p.y, p.z - es), nor)) - ref
	) / es;

	grad -= nor * dot(nor, grad);
	return normalize(nor + grad * factor);
}

// basic lighting and soft shadows //
float get_diff(vec3 p, vec3 lpos) {
	vec3 l = normalize(lpos - p);
	vec3 n = get_normal(p);
	float dif = clamp(dot(n, l), 0., 1.);

	vec2 shadow = ray_march(p + n * MIN_DIST * 2., l);
	if (shadow.x < length(p - lpos)) {
		dif *= .1;
	}
	return dif;
}

vec3 render(in vec3 ro, in vec3 rd, in vec2 uv) {
	vec3 color = vec3(1.);

	vec2 ray = ray_march(ro, rd);

	if (ray.x < MAX_DIST) {
		vec3 p = ro + ray.x * rd;
		vec3 n = get_normal(p);
		vec3 tint = get_color(ray.y, p);

		vec3 lpos = ro + vec3(-0.05, 0.01, .55);
		vec3 lpos2 = ro + vec3(0.05, -.2, 1.15);

		float diff = get_diff(p, lpos) *2.;
		float diff2 = get_diff(p, lpos2);

		// lighting is my worst right now - how to add / mult / sub to get
		// the right look and settings.
		float bounce = clamp(.25 + .25 * dot(n, vec3(0., -1., 0.)), 0., 1.) *.5;
		float spec = pow(max(dot(reflect(lpos, n), -rd), 0.0), .5);
		float aor = .5;
		float occlusion = 1. - max(0., 1. - map(p + n * aor).x / aor) *.75;
		color *= tint;
		color *= vec3(spec + diff + bounce * occlusion);

	}

	float t = ray.x; // post process distance effect - iq
	color = mix(color, vec3(.91, 1.09, 1.09), 1. - exp(-0.00925*t*t*t));
	return pow(color, vec3(0.4545));
}

vec3 ray(in vec3 ro, in vec3 lp, in vec2 uv) {
	// set vectors to solve intersection

	float dt = fract(iTime *.01);
	vec3 cf = normalize(lp - ro);
	//vec3 cp = vec3(sin(dt*PI/2.),1.,cos(dt*PI/2.)); 
	vec3 cp = vec3(0., 1., 0.);
	vec3 cr = normalize(cross(cp, cf));
	vec3 cu = normalize(cross(cf, cr));
	;
	// center of the screen
	vec3 c = ro + cf * .65;

	vec3 i = c + uv.x * cr + uv.y * cu;
	// intersection point
	return i - ro;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
	// pixel screen coordinates
	vec2 uv = fragCoord;//vec2 uv = (fragCoord.xy - iResolution.xy*0.5) / iResolution.y;

	// ray origin / look at point
	float tm = iTime * .2;
	float tlap = -3.;
	if (mod(iTime*.5, 10.) < 5.) tlap = 3.;
	vec3 lp = vec3(0., 0., 0. - tm);
	vec3 ro = lp + vec3(0., 0., tlap);

	// uncomment to pan camera but not really
	// happy with it.. dont have a good auto
	// function - but you can check it.

	// lp = get_mouse(lp);

	lp.xy += path2(lp.z);
	ro.xy += path2(ro.z);

	// get ray direction
	vec3 rd = ray(ro, lp, uv);
	// render scene
	vec3 col = render(ro, rd, uv);
	// Output to screen
	fragColor = vec4(col, 1.0);
}

void mainVR(out vec4 fragColor, in vec2 fragCoord, in vec3 fragRayOri, in vec3 fragRayDir) {
	vec2 uv = (fragCoord.xy - .5 * iResolution.xy) / iResolution.y;

	float tm = iTime * .2;
	vec3 lp = vec3(0., .2, 0. - tm);
	lp.xy += path2(lp.z);

	vec3 ro = lp + fragRayOri;

	//ro.xy += path2(ro.z);

	vec3 color = render(ro, fragRayDir, uv);

	fragColor = vec4(color, 1.0);
}


void main() { mainImage(fragColor, fragCoord); }