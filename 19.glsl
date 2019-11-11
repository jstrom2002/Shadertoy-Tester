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




void pR(inout vec2 p, float a) {
	p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}


// Formula for original MandelBulb from http://blog.hvidtfeldts.net/index.php/2011/09/distance-estimated-3d-fractals-v-the-mandelbulb-different-de-approximations/
// also see https://www.shadertoy.com/view/4tGXWd
float MandelBulb(vec3 pos, const int limitIterations)
{
	const int Iterations = 12;
	const float Bailout = 8.0;
	float Power = 5.0 + cos(iTime*0.325);

	vec3 z = pos;
	float dr = 1.0;
	float r = 0.0;
	for (int i = 0; i < Iterations; i++)
	{
		r = length(z);
		if (r > Bailout || i == limitIterations) break;   // TODO: test if better to continue loop and if() rather than break?

		// convert to polar coordinates
		float theta = acos(z.z / r);
		float phi = atan(z.y, z.x);
		dr = pow(r, Power - 1.0)*Power*dr + iTime / 10000.;

		// scale and rotate the point
		float zr = pow(r, Power);
		theta = theta * Power;
		phi = phi * Power;

		// convert back to cartesian coordinates
		z = zr * vec3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
		z += pos;
	}
	return 0.5*log(r)*r / dr;
}

float map(vec3 p)
{

	float planeDist = p.y;
	pR(p.xy, -90.);
	pR(p.yz, iTime / 7.4);
	float mm = MandelBulb(p - vec3(-2., -.5, -.3), 13);

	return (mm);
}


float RM(vec3 ro, vec3 rd)
{
	float t = 0.;

	for (int i = 0; i < 100; i++)
	{
		vec3 pos = ro + rd * t;
		float h = map(pos);

		if (h < .001) break;

		t += h;

		if (t > 40.0) {
			t = -1.0;
			break;
		}

	}

	return t;
}

vec3 GetNormal(vec3 p)
{
	vec2 e = vec2(.01, 0);
	float d = map(p);

	vec3 pointNormal = d - vec3(
		map(p - vec3(e.xyy)),
		map(p - vec3(e.yxy)),
		map(p - vec3(e.yyx))
	);

	return normalize(pointNormal);

}



void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
	vec2 uv = fragCoord;//(2.*fragCoord - iResolution.xy) / iResolution.y;
	vec3 col = vec3(0., 0.2*uv.y, 0.2*uv.y + .3);

	vec3 ro = vec3(1.3, 1.7, -2.);
	vec3 rd = normalize(vec3(uv, 1.));

	float t = RM(ro, rd);

	if (t > 0.0)
	{
		col = vec3(.2*sin(iTime*3.), .3*cos(iTime*4.) + uv.x, sin(iTime*3.));

		vec3 pos = ro + t * rd;
		vec3 nor = GetNormal(pos);
		vec3 sun_dir = normalize(vec3(2.5, 2., -1.5));
		float sun_sha = step(RM(pos + nor * .001, sun_dir), 0.);
		float sun_dif = (clamp(dot(nor, sun_dir), .0, 1.));


		//shadows

		col += vec3(.9)*sun_dif;
		//col = mix(col,col*0.2,shadow);
	}



	fragColor = vec4(col, 1.0);
}






void main() { mainImage(fragColor, fragCoord); }