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




/*by mu6k, Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

 Clouds are awesome! And also horribly hard to render. Well, hard is not the right
 word for it, computationally expensive is a much more accurate term.
 You can use the mouse to look around.

 This shader is based on what I did in my older shader,

 https://www.shadertoy.com/view/4sl3Dn

 But there is a huge difference, the domain is limited to small sphere there,
 there are rays that never need to evaluate the volumetric renderinc functions.
 For obvious reasons it's much faster.

 Here I have basically the same code, just a bit different setup. The volumetric
 functions are evaluated after tracing an infinite plane. When the ray hits the
 surface of that infinite plane the raymarcher takes N iterations to render the
 cloud. For each iteration another M iterations are used to determine the illumination.

 The density function is evaluated N*M times per pixel. This is the computationally
 expensive part because the density funtion is the product of a 4d noise function
 and a 2d noise function.

 There are a few rendering artifacts when the quality is reduced. However I managed to
 find a good configuration. With 17 steps the artifacts aren't visible anymore and
 it turns out that even 3 illum steps produces decent results. This reduces the
 amount of times the density function needs to be evaluated to 51.

 Feel free to play around with the parameters.
 Definitely check out wind_speed, morph_speed nad density_modifier.

 30/05/2013:
 - published

 muuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuusk!*/

#define quality 17 // nr of steps taken to evaluate the density
#define illum_quality 3 // nr of steps for illumination
#define noise_use_smoothstep //different interpolation for noise functions

#define wind_speed 0.1
#define morph_speed 0.12

#define density_modifier 0.00
#define density_osc_amp 0.04
#define density_osc_freq 0.07

#define const_light_color vec3(2.8,2.3,0.7)
#define const_dark_color vec3(.5,.55,.7)
#define const_sky_color vec3(0.2,0.46,0.8)

float hash(float x)
{
	return fract(sin(x*.0127863)*17143.321);
}

float hash(vec2 x)
{
	return fract(cos(dot(x.xy, vec2(2.31, 53.21))*124.123)*412.0);
}

float hashmix(float x0, float x1, float interp)
{
	x0 = hash(x0);
	x1 = hash(x1);
#ifdef noise_use_smoothstep
	interp = smoothstep(0.0, 1.0, interp);
#endif
	return mix(x0, x1, interp);
}

float hashmix(vec2 p0, vec2 p1, vec2 interp)
{
	float v0 = hashmix(p0[0] + p0[1] * 128.0, p1[0] + p0[1] * 128.0, interp[0]);
	float v1 = hashmix(p0[0] + p1[1] * 128.0, p1[0] + p1[1] * 128.0, interp[0]);
#ifdef noise_use_smoothstep
	interp = smoothstep(vec2(0.0), vec2(1.0), interp);
#endif
	return mix(v0, v1, interp[1]);
}

float hashmix(vec3 p0, vec3 p1, vec3 interp)
{
	float v0 = hashmix(p0.xy + vec2(p0.z*143.0, 0.0), p1.xy + vec2(p0.z*143.0, 0.0), interp.xy);
	float v1 = hashmix(p0.xy + vec2(p1.z*143.0, 0.0), p1.xy + vec2(p1.z*143.0, 0.0), interp.xy);
#ifdef noise_use_smoothstep
	interp = smoothstep(vec3(0.0), vec3(1.0), interp);
#endif
	return mix(v0, v1, interp[2]);
}

float hashmix(vec4 p0, vec4 p1, vec4 interp)
{
	float v0 = hashmix(p0.xyz + vec3(p0.w*17.0, 0.0, 0.0), p1.xyz + vec3(p0.w*17.0, 0.0, 0.0), interp.xyz);
	float v1 = hashmix(p0.xyz + vec3(p1.w*17.0, 0.0, 0.0), p1.xyz + vec3(p1.w*17.0, 0.0, 0.0), interp.xyz);
#ifdef noise_use_smoothstep
	interp = smoothstep(vec4(0.0), vec4(1.0), interp);
#endif
	return mix(v0, v1, interp[3]);
}

float noise(float p) // 1D noise
{
	float pm = mod(p, 1.0);
	float pd = p - pm;
	return hashmix(pd, pd + 1.0, pm);
}

float noise(vec2 p) // 2D noise
{
	vec2 pm = mod(p, 1.0);
	vec2 pd = p - pm;
	return hashmix(pd, (pd + vec2(1.0, 1.0)), pm);
}

float noise(vec3 p) // 3D noise
{
	vec3 pm = mod(p, 1.0);
	vec3 pd = p - pm;
	return hashmix(pd, (pd + vec3(1.0, 1.0, 1.0)), pm);
}

float noise(vec4 p) // 4D noise
{
	vec4 pm = mod(p, 1.0);
	vec4 pd = p - pm;
	return hashmix(pd, (pd + vec4(1.0, 1.0, 1.0, 1.0)), pm);
}

vec3 rotate_y(vec3 v, float angle)
{
	vec3 vo = v; float cosa = cos(angle); float sina = sin(angle);
	v.x = cosa * vo.x - sina * vo.z;
	v.z = sina * vo.x + cosa * vo.z;
	return v;
}

vec3 rotate_x(vec3 v, float angle)
{
	vec3 vo = v; float cosa = cos(angle); float sina = sin(angle);
	v.y = cosa * vo.y - sina * vo.z;
	v.z = sina * vo.y + cosa * vo.z;
	return v;
}

vec3 cc(vec3 color, float factor, float factor2) //a wierd color modifier
{
	float w = color.x + color.y + color.z;
	return mix(color, vec3(w)*factor, w*factor2);
}

vec3 plane(vec3 p, vec3 d) //returns the intersection with a predefined plane
{
	//http://en.wikipedia.org/wiki/Line-plane_intersection
	vec3 n = vec3(.0, 1.0, .0);
	vec3 p0 = n * 4.8;
	float f = dot(p0 - p, n) / dot(n, d);
	if (f > .0)
		return p + d * f;
	else
		return vec3(.0, .0, .0);
}

vec3 ldir = normalize(vec3(-1.0, -1.0, -1.0)); //light direction
float time = .0; //global time

float density(vec3 p) //density function for the cloud
{
	if (p.y > 15.0) return 0.0; //no clouds above y=15.0
	p.x += time * float(wind_speed);
	vec4 xp = vec4(p*0.4, time*morph_speed + noise(p));
	float nv = pow(pow((noise(xp*2.0)*.5 + noise(xp.zx*0.9)*.5), 2.0)*2.1, 2.);
	nv = max(0.1, nv); //negative density is illegal.
	nv = min(0.6, nv); //high density is ugly for clouds
	return nv;
}

float illumination(vec3 p, float density_coef)
{
	vec3 l = ldir;
	float il = 1.0;
	float ill = 1.0;

	float illum_q_coef = 10.0 / float(illum_quality);

	for (int i = 0; i<int(illum_quality); i++) //illumination
	{
		il -= density(p - l * hash(p.xy + vec2(il, p.z))*0.5)*density_coef*illum_q_coef;
		p -= l * illum_q_coef;

		if (il <= 0.0)
		{
			il = 0.0;
			break; //light can't reach this point in the cloud
		}
		if (il == ill)
		{
			break; //we already know the amount of light that reaches this point
			//(well not exactly but it increases performance A LOT)
		}
		ill = il;
	}

	return il;
}

void mainImage(out vec4 fragColor, vec2 fragCoord2)
{
	vec2 fragCoord = (fragCoord2 +0.5) * iResolution.xy;
	vec2 uv = fragCoord.xy / iResolution.xy - 0.5;
	uv.x *= iResolution.x / iResolution.y; //fix aspect ratio
	vec3 mouse = vec3(iMouse.xy / iResolution.xy - 0.5, iMouse.z - .5);

	time = iTime + 385.0; //i want the sun visible in the screenshot

	vec3 p = vec3(.0, .0, .0); //ray position
	vec3 d = vec3(uv, 1.0);
	d.z -= length(d)*.2;

	d = rotate_x(d, -1.19 - 1.0*mouse.y);
	d = rotate_y(d, 1.5 + -7.0*mouse.x);

	d = normalize(d); //ray direction

	float acc = .0;

	p = plane(p, d);

	float illum_acc = 0.0;
	float dense_acc = 0.0;
	float density_coef = 0.13 + float(density_modifier)
		+ sin(iTime*float(density_osc_freq))*float(density_osc_amp);
	float quality_coef = 20.0 / float(quality);

	for (int i = 0; i < quality; i++)
	{
		p += d * quality_coef*.5;

		float nv = density(p + d * hash(uv + vec2(iTime, dense_acc))*0.25)*density_coef*quality_coef;
		//evaluate the density function

		vec3 sp = p;
		dense_acc += nv;

		if (dense_acc > 1.0)
		{
			dense_acc = 1.0; //break condition: following steps do not contribute 
			break; //to the color because it's occluded by the gas
		}

		float il = illumination(p, density_coef);

		illum_acc += max(0.0, nv*il*(1.0 - dense_acc));
		//nv - alpha of current point
		//il - illumination of current point
		//1.0-dense_acc - how much is visible of this point
	}

	d = normalize(d);

	//color mixing follows

	vec3 illum_color = const_light_color * illum_acc*0.50;

	float sun = dot(d, -ldir); sun = .5*sun + .501; sun = pow(sun, 400.0);
	sun += (pow(dot(d, -ldir)*.5 + .5, 44.0))*.2;
	vec3 sky_color = const_sky_color * (1.1 - d.y*.3)*1.1;

	vec3 dense_color = mix(illum_color, const_dark_color, .6)*1.4; //color of the dark part of the cloud

	sky_color = sky_color * (1.0 - uv.y*0.2) + vec3(.9, .9, .9)*sun;

	vec3 color = mix(sky_color, (dense_color + illum_color * 0.33)*1.0, smoothstep(0.0, 1.0, dense_acc)); color -= length(uv)*0.2;

	color += hash(color.xy + uv)*0.01; //kill all color banding
	color = cc(color, 0.42, 0.45);

	fragColor = vec4(color, 1.0);
}






void main() { mainImage(fragColor, fragCoord); }