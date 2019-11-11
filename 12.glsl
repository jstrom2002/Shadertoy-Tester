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






//RAINDROP SHADER
#define HASHSCALE3 vec3(.1031, .1030, .0973)
#define HASHSCALE1 0.1031
#define iterations 3
#define res .78
#define speed .68
#define FAR 1450.
#define MAX 400
#define EPSILON .06
#define T .5+.5+sin(iTime*1.)

/// Please excuse the mess of code, there's all kinds of crap in here for learning purposes!


// - hash from https://www.shadertoy.com/view/4djSRW
vec2 hash22(vec2 p)
{
	vec3 p3 = fract(vec3(p.xyx) * HASHSCALE3);
	p3 += dot(p3, p3.yzx + 176.1958);
	return fract((p3.xx + p3.yz)*p3.zy);

}

///  3 out, 3 in...
vec3 hash33(vec3 p3)
{
	p3 = fract(p3 * HASHSCALE3);
	p3 += dot(p3, p3.yxz + 19.19);
	return fract((p3.xxy + p3.yxx)*p3.zyx);

}

//----------------------------------------------------------------------------------------
//  1 out, 1 in...
float hash11(float p)
{
	vec3 p3 = fract(vec3(p) * HASHSCALE1);
	p3 += dot(p3, p3.yzx + 19.19);
	return fract((p3.x + p3.y) * p3.z);
}


float bias(float signal, float b)
{
	return signal / ((((1.0 / b) - 2.0)*(1.0 - signal)) + 1.0);
}


vec3 voronoi(vec3 p, float rnd)
{

	vec3 vw, xy, yz, xz, s1, s2, xx, bz, az, xw;

	yz = vec3(0.0);
	bz = vec3(0.0);
	az = vec3(0.0);
	xw = vec3(0.0);
	p = p.xzy;

	p *= res;
	vec3 uv2 = p;
	vec3 p2 = p;
	p = vec3(floor(p));

	float timer = iTime * speed;


	//vec2 rand = vw/vec2(iterations);

	vec2 yx = vec2(0.0);



	for (int j = -1; j <= 1;j++)
	{
		for (int k = -1; k <= 1; k++)
		{

			vec3 offset = vec3(float(j), float(k), 0.0);
			//grab random values for grid
			s1.xz = hash33(p + offset.xyz + 127.43 + rnd).xz;

			//uses random value as timer for switching positions of raindrop
			s2.xz = floor(s1.xx + timer);
			//adding the timer to the random value so that everytime a ripple fades, a new drop appears
			xz.xz = hash33(p + offset.xyz + (s2)+rnd).xz;
			xx = hash33(p + offset.xyz + (s2 - 1.));



			//test2 = xy;

			// modulate the timer
			s1 = mod(s1 + timer, 1.);

			//p2 = (p2-p2)+vec3(s1.x,0.0,s1.y);
			p2 = mod(p2, 1.0);

			// create opacity
			float op = 1. - s1.x;
			op = bias(op, .21);

			//change the profile of the timer
			s1.x = bias(s1.x, .62);

			// expand ripple over time
			float size = mix(4., 1.00, s1.x);

			// move the ripple formation from the center as it grows
			float size2 = mix(.005, 2.0, s1.x);

			// make the voronoi 'balls'



			xy.xz = vec2(length((p.xy + xz.xz) - (uv2.xy - offset.xy))*size);



			//xy.xz *= (1.0/9.0);

			xx = vec3(length((p2)+xz) - (uv2 - offset)*1.30);

			xx = 1.0 - xx;

			// invert
			xy.x = 1.0 - xy.x;


			xy.x *= size2;

			//create first ripple
			if (xy.x > .5)xy.x = mix(1., 0., xy.x);

			xy.x = mix(0., 2., xy.x);

			// second ripple
			if (xy.x > .5)xy.x = mix(1., 0., xy.x);

			xy.x = mix(0., 2., xy.x);

			xy.x = smoothstep(.0, 1., xy.x);

			// fade ripple over time
			xy *= op;

			yz = 1.0 - ((1.0 - yz)*(1.0 - xy));

			//ops += mix(0.0,xy.x,op.x);
			//yz = yz.xxx;
			//yz = max(yz,xy);

			//yz += p;
			//xw = max(xx,xw);
			//counter+=1.0;;
		}
	}


	return vec3(yz*.1);
}



float sphere(vec3 p)
{

	//p = mod((p-(p*.5)),12.3)-6.15;
	return length(p) - 1.;

}


float plane(vec3 p)
{


	float cc = 0.0;
	float pl = (p.y + 1.);
	vec3 ripples = vec3(0.0);

	for (int i = 0;i < iterations;i++)
	{
		ripples += voronoi(p, float(i + 1));
	}

	return pl - ripples.x*.25;


}




void mainImage(out vec4 fragColor, in vec2 fragCoord)
{

	//vec2 uv = fragCoord.xy / iResolution.xy;
	//uv = -1.0 + 2.0 * uv;
	vec2 uv = fragCoord;//uv's are already in NDC!

	float midPoint = uv.x + .5;

	vec2 uv2 = uv * res;

	uv2 = fragCoord.xy / iResolution.xx;
	vec2 po;

	//uv.x *= iResolution.x/iResolution.y;


	//uv.x *= iResolution.x/iResolution.y;

	float mixer1 = mix(-4., 4.0, 0.5 + 0.5*sin(iTime*.024));
	float mixer2 = mix(-4., 4.0, 0.5 + 0.5*cos(iTime*.024));
	float mixer3 = mix(-1., 1.60, 0.5 + 0.5*cos(iTime*.14));
	float mixer4 = mix(1., .01, 0.5 + 0.5*cos(iTime*.4));



	float move = iTime * 1.5;
	//move = 0.;

	// props to all this vector math from a reddit tutorial: 
	// https://www.reddit.com/r/twotriangles/comments/1hy5qy/tutorial_1_writing_a_simple_distance_field/

	vec3 camPos = vec3(mixer1, 4., mixer2);
	vec3 camTarget = vec3(0.0, mixer3, 1.0);
	vec3 upDir = vec3(0.0, 1., 0.0);
	vec3 camDir = normalize(camTarget - camPos);
	vec3 camRight = normalize(cross(upDir, camDir));
	vec3 camUp = cross(camDir, camRight);
	vec3 camLook = camPos + camDir;

	vec3 ray = camLook + uv.x*camRight*iResolution.x / iResolution.y + uv.y*camUp;

	vec3 rayDir = normalize((ray*.86) - (camPos));

	vec3 N;

	float totalDist = 0.0;
	vec3 pos = camPos;
	float dist = EPSILON;
	vec3 col;
	float fog = 0.;

	////// Ray marching version but not needed right now because I can't get raindrops figured out
	/*
	for (int i = 0; i < MAX; i++)
	{
	// Either we've hit the object or hit nothing at all, either way we should break out of the loop
	if (dist < EPSILON || totalDist > FAR)
		break; // If you use windows and the shader isn't working properly, change this to continue;


	//dist = voronoi(pos+float(i+1)*12.357,fog).x;// Evalulate the distance at the current point
	dist = plane(pos);

	totalDist += dist;
	fog += dist;
	pos += dist * rayDir; // Advance the point forwards in the ray direction by the distance
	}

	//vec3 test2 = mix(pos+.04*rayDir,pos+100.*rayDir,0.5+0.5*sin(iTime*4.));

	//dist = voronoi(pos*1.+(1.*12.357),fog).x;// Evalulate the distance at the current point


	vec3 eps = vec3(EPSILON, 0.0, 0.0);

	float d1 = plane(pos);
	float d2 = plane(pos + eps.xyz) - d1;

	vec3 normal2 = normalize(vec3(
	plane(pos + eps.xyz) - d1,
	plane(pos + eps.yxz) - d1,
	plane(pos + eps.yzx) - d1));

	vec3 ref2 = reflect(rayDir,normal2);
	vec3 refr = texture(iChannel0,ref2).xyz;
	vec3 refl = texture(iChannel0,-ref2).xyz;

	fog = clamp(fog/400.,0.,1.);
	*/



	//refl = mix(refr,refl,fresnel*1.);



	// help from Andy Whittock - a non-ray-marched version;
	vec3 eps = vec3(EPSILON, 0.0, 0.0);
	vec3 plane1 = vec3(0., 0.1, 0.);
	float d = -dot(camPos, plane1) / dot(rayDir, plane1);


	fog = smoothstep(0.0, 1.0, clamp(d / 20., 0.0, 1.0));



	vec3 hitPoint = (camPos + (d*rayDir));
	//camPos = camPos+rayDir;

	vec3 L, diffuse, ref, reflection, waterColor, col2, col3, normal;

	float v1, v2, v3, light;

	float b = 0.0;

	//vec3 voro = voronoi(hitPoint.xyz, b);

	vec3 BG = texture(iChannel0, rayDir.xy).xyz;

	vec3 der;
	hitPoint = hitPoint + 0.2;
	float test = 0.;
	float std = .5;


	if (d > 1.0)
	{

		hitPoint = hitPoint;


		std = plane(hitPoint);



		der += vec3(v1 = plane(hitPoint + eps.xyy) - std,
			v2 = plane(hitPoint + eps.yxy) - std,
			v3 = plane(hitPoint + eps.yyx) - std);
		test = std;


		//der *= (1.0/(s*s));

		normal = normalize(plane1 + der);

		vec3 ref2 = reflect(rayDir, normal);
		vec3 refr = texture(iChannel0, ref2.xy).xyz;
		vec3 refl = texture(iChannel0, -ref2.xy).xyz;

		L = normalize(vec3(17.5, 12.5, 12.5));
		float LDist = length(L - pos);
		float atten = min(2.0, 1.0 / (LDist / 4.50));
		atten = 1.0;
		diffuse = vec3(.50, .5, .5);
		//light = max(.0,dot(normalize(L), normal2));

		ref = -reflect(rayDir, normal);

		float fresnel = 1.0 + (dot(normal, rayDir))*.5;
		fresnel = bias(fresnel, .35);
		fresnel = pow(fresnel, 2.4);

		float spec = 0.;

		refl = mix(vec3(0.0), refl, fresnel*2.);

		col = refl;

		vec3 fogColor = vec3(0.3, .6, 1.);

		col = mix(refl, fogColor, fog);





		fogColor = col3;



		col2 = vec3(0.);
		col = mix(refl, refr, fresnel);

		int its = 0;
		float bs = 1.80;
		float opacity = .75;


		//smp = mix(smp,smp*10.,fog);


		for (int L = -1; L <= 1; L++)
		{
			for (int M = -1; M <= 1; M++)
			{
				// hitPoint = hitPoint + vec3(float(L)*smp,0.0,float(M)*smp);
				// test += voronoi(hitPoint.xyz*1.+(1.*12.357),b).x;
			}
		}

		//test *= (1.0/9.0);


	}

	else col = texture(iChannel0, -rayDir.xy).xyz;





	//if (pos.y > -0.)ref3 = col;
	//vec3 result = mix(col,BG,fog);
	//result = vec3(normal);
	float qe = 1.2;
	//float test2 = voronoi(pos+vec3(0.0,test*.2,0.0),qe).x;
	fragColor = vec4(vec3((col + (fog*.32))*1.), 1.0);
}/////////////////////////////////////////////////////////////////////////////////////////////



void main() { mainImage(fragColor, fragCoord); }