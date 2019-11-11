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



// Created by inigo quilez - iq/2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.



// A basic temple model. No global illumination, all cheated and composed to camera:
//
// - the terrain is false perspective
// - there are two different sun directions for foreground and background. 
// - ambient occlusion is mostly painted by hand
// - bounce lighting is also painted by hand
//
// This shader was made as a continuation to a live coding session I did for the students
// of UPENN. After the initial live coded session I decided to rework it and improve it,
// and that turned out to be a bit of a pain because when looking for the final look I got
// trapped in more local minima that I usually do and it took me a while to leave them. 



// Created by inigo quilez - iq/2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.


// A basic temple model. No global illumination, all cheated and composed to camera:
//
// - the terrain is false perspective
// - there are two different sun directions for foreground and background. 
// - ambient occlusion is mostly painted by hand
// - bounce lighting is also painted by hand
//
// This shader was made as a continuation to a live coding session I did for the students
// of UPENN. After the initial live coded session I decided to rework it and improve it,
// and that turned out to be a bit of a pain because when looking for the final look I got
// trapped in more local m♂inima that I usually do and it took me a while to leave them. 




//#define STATICCAM

float hash1(vec2 p)
{
	p = 50.0*fract(p*0.3183099);
	return fract(p.x*p.y*(p.x + p.y));
}

float hash(uint n)
{
	n = (n << 13U) ^ n;
	n = n * (n * n * 15731U + 789221U) + 1376312589U;
	// floating point conversion from http://iquilezles.org/www/articles/sfrand/sfrand.htm
	return uintBitsToFloat((n >> 9U) | 0x3f800000U) - 1.0;
}

vec2 hash2(float n) { return fract(sin(vec2(n, n + 1.0))*vec2(43758.5453123, 22578.1459123)); }

float noise(in vec2 x)
{
	ivec2 p = ivec2(floor(x));
	vec2 f = fract(x);
	f = f * f*(3.0 - 2.0*f);
	ivec2 uv = p.xy;
	float rgA = texelFetch(iChannel1, (uv + ivec2(0, 0)) & 255, 0).x;
	float rgB = texelFetch(iChannel1, (uv + ivec2(1, 0)) & 255, 0).x;
	float rgC = texelFetch(iChannel1, (uv + ivec2(0, 1)) & 255, 0).x;
	float rgD = texelFetch(iChannel1, (uv + ivec2(1, 1)) & 255, 0).x;
	return mix(mix(rgA, rgB, f.x),
		mix(rgC, rgD, f.x), f.y);
}

float noise(in vec3 x)
{
	vec3 p = floor(x);
	vec3 f = fract(x);
	f = f * f*(3.0 - 2.0*f);
	vec2 uv = (p.xy + vec2(37.0, 17.0)*p.z) + f.xy;
	vec2 rg = textureLod(iChannel1, (uv + 0.5) / 256.0, 0.0).yx;
	return mix(rg.x, rg.y, f.z);
}

float fbm4(in vec3 p)
{
	float n = 0.0;
	n += 1.000*noise(p*1.0);
	n += 0.500*noise(p*2.0);
	n += 0.250*noise(p*4.0);
	n += 0.125*noise(p*8.0);
	return n;
}

float fbm6(in vec3 p)
{
	float n = 0.0;
	n += 1.00000*noise(p*1.0);
	n += 0.50000*noise(p*2.0);
	n += 0.25000*noise(p*4.0);
	n += 0.12500*noise(p*8.0);
	n += 0.06250*noise(p*16.0);
	n += 0.03125*noise(p*32.0);
	return n;
}

float fbm6(in vec2 p)
{
	float n = 0.0;
	n += 1.00000*noise(p*1.0);
	n += 0.50000*noise(p*2.0);
	n += 0.25000*noise(p*4.0);
	n += 0.12500*noise(p*8.0);
	n += 0.06250*noise(p*16.0);
	n += 0.03125*noise(p*32.0);
	return n;
}

float fbm4(in vec2 p)
{
	float n = 0.0;
	n += 1.00000*noise(p*1.0);
	n += 0.50000*noise(p*2.0);
	n += 0.25000*noise(p*4.0);
	n += 0.12500*noise(p*8.0);
	return n;
}

float ndot(vec2 a, vec2 b) { return a.x*b.x - a.y*b.y; }

float sdRhombus(in vec2 p, in vec2 b, in float r)
{
	vec2 q = abs(p);
	float h = clamp((-2.0*ndot(q, b) + ndot(b, b)) / dot(b, b), -1.0, 1.0);
	float d = length(q - 0.5*b*vec2(1.0 - h, 1.0 + h));
	d *= sign(q.x*b.y + q.y*b.x - b.x*b.y);
	return d - r;
}

float usdBox(in vec3 p, in vec3 b)
{
	return length(max(abs(p) - b, 0.0));
}

float sdBox(vec3 p, vec3 b)
{
	vec3 d = abs(p) - b;
	return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float sdBox(float p, float b)
{
	return abs(p) - b;
}

vec2 opRepLim(in vec2 p, in float s, in vec2 lim)
{
	return p - s * clamp(round(p / s), -lim, lim);
}

vec4 textureGood(sampler2D sam, in vec2 uv)
{
	uv = uv * 1024.0 - 0.5;
	vec2 iuv = floor(uv);
	vec2 f = fract(uv);
	f = f * f*(3.0 - 2.0*f);
	vec4 rg1 = textureLod(sam, (iuv + vec2(0.5, 0.5)) / 1024.0, 0.0);
	vec4 rg2 = textureLod(sam, (iuv + vec2(1.5, 0.5)) / 1024.0, 0.0);
	vec4 rg3 = textureLod(sam, (iuv + vec2(0.5, 1.5)) / 1024.0, 0.0);
	vec4 rg4 = textureLod(sam, (iuv + vec2(1.5, 1.5)) / 1024.0, 0.0);
	return mix(mix(rg1, rg2, f.x), mix(rg3, rg4, f.x), f.y);
}

#define ZERO (min(iFrame,0))

//------------

float terrain(in vec2 p)
{
	float h = 90.0*textureGood(iChannel2, p.yx*0.0001 + 0.35 + vec2(0.02, 0.05)).x - 70.0 + 5.0;
	h = mix(h, -7.2, 1.0 - smoothstep(16.0, 60.0, length(p)));
	h -= 7.0*textureGood(iChannel2, p*0.002).x;
	float d = textureLod(iChannel0, p*0.01, 0.0).x;
	h -= 1.0*d*d*d;
	return h;
}

const float ocean = -25.0;

vec3 temple(in vec3 p)
{
	vec3 op = p;
	vec3 res = vec3(-1.0, -1.0, 0.5);

	p.y += 2.0;

	// bounding box
	float bbox = usdBox(p, vec3(15.0, 12.0, 15.0)*1.5);
	if (bbox > 5.0) return vec3(bbox + 1.0, -1.0, 0.5);

	vec3 q = vec3(mod(p.x + 2.0, 4.0) - 2.0, p.y,
		mod(p.z + 2.0, 4.0) - 2.0);

	// columns
	vec2 id = floor((p.xz + 2.0) / 4.0);

	float d = length(q.xz) - 0.9 + 0.05*p.y;
	d -= 0.05*pow(0.5 + 0.5*sin(atan(q.x, q.z)*16.0), 2.0);
	d -= 0.15*pow(0.5 + 0.5*sin(q.y*3.0 + 0.6), 0.12) - 0.15;
	res.z = hash1(id + 11.0*floor(0.25 + (q.y*3.0 + 0.6) / 6.2831));
	d *= 0.85;
	{
		vec3 qq = vec3(q.x, abs(q.y - 0.3) - 5.5, q.z);
		d = min(d, sdBox(qq, vec3(1.4, 0.2, 1.4) + sign(q.y - 0.3)*vec3(0.1, 0.05, 0.1)) - 0.1); // base
	}

	d = max(d, sdBox(p, vec3(18.0, 7.0, 10.0))); // clip out
	d = max(d, -sdBox(p, vec3(14.0, 10.0, 6.0))); // clip in

	// floor
	float ra = 0.15 * hash1(id + vec2(1.0, 3.0));
	q = p; q.xz = opRepLim(q.xz, 4.0, vec2(4.0, 3.0));
	float b = sdBox(q - vec3(0.0, -6.0 + 0.1 - ra, 0.0), vec3(2.0, 0.5, 2.0) - 0.15 - ra) - 0.15;
	b *= 0.5;
	if (b < d) { d = b; res.z = hash1(id); }

	p.xz -= 2.0;
	id = floor((p.xz + 2.0) / 4.0);
	ra = 0.15 * hash1(id + vec2(1.0, 3.0) + 23.1);
	q = p; q.xz = opRepLim(q.xz, 4.0, vec2(5.0, 4.0));
	b = sdBox(q - vec3(0.0, -7.0 - ra, 0.0), vec3(2.0, 0.6, 2.0) - 0.15 - ra) - 0.15;
	b *= 0.8;
	if (b < d) { d = b; res.z = hash1(id + 13.5); }
	p.xz += 2.0;

	id = floor((p.xz + 2.0) / 4.0);
	ra = 0.15 * hash1(id + vec2(1.0, 3.0) + 37.7);
	q = p; q.xz = opRepLim(q.xz, 4.0, vec2(5.0, 4.0));
	b = sdBox(q - vec3(0.0, -8.0 - ra - 1.0, 0.0), vec3(2.0, 0.6 + 1.0, 2.0) - 0.15 - ra) - 0.15;
	b *= 0.5;
	if (b < d) { d = b; res.z = hash1(id*7.0 + 31.1); }


	// roof
	q = vec3(mod(p.x + 2.0, 4.0) - 2.0, p.y, mod(p.z + 0.0, 4.0) - 2.0);
	b = sdBox(q - vec3(0.0, 7.0, 0.0), vec3(1.95, 1.0, 1.95) - 0.15) - 0.15;
	b = max(b, sdBox(p - vec3(0.0, 7.0, 0.0), vec3(18.0, 1.0, 10.0)));
	if (b < d) { d = b; res.z = hash1(floor((p.xz + vec2(2.0, 0.0)) / 4.0) + 31.1); }

	q = vec3(mod(p.x + 0.5, 1.0) - 0.5, p.y, mod(p.z + 0.5, 1.0) - 0.5);
	b = sdBox(q - vec3(0.0, 8.0, 0.0), vec3(0.45, 0.5, 0.45) - 0.02) - 0.02;
	b = max(b, sdBox(p - vec3(0.0, 8.0, 0.0), vec3(19.0, 0.2, 11.0)));
	//q = p+vec3(0.0,0.0,-0.5); q.xz = opRepLim( q.xz, 1.0, vec2(19.0,10.0) );
	//b = sdBox( q-vec3(0.0,8.0,0.0), vec3(0.45,0.2,0.45)-0.02 )-0.02;
	if (b < d) { d = b; res.z = hash1(floor((p.xz + 0.5) / 1.0) + 7.8); }



	b = sdRhombus(p.yz - vec2(8.2, 0.0), vec2(3.0, 11.0), 0.05);
	q = vec3(mod(p.x + 1.0, 2.0) - 1.0, p.y, mod(p.z + 1.0, 2.0) - 1.0);
	b = max(b, -sdBox(vec3(abs(p.x) - 20.0, p.y, q.z) - vec3(0.0, 8.0, 0.0), vec3(2.0, 5.0, 0.1)) - 0.02);

	b = max(b, -p.y + 8.2);
	b = max(b, usdBox(p - vec3(0.0, 8.0, 0.0), vec3(19.0, 12.0, 11.0)));
	float c = sdRhombus(p.yz - vec2(8.3, 0.0), vec2(2.25, 8.5), 0.05);
	c = max(c, sdBox(abs(p.x) - 19.0, 2.0));
	b = max(b, -c);


	d = min(d, b);

	d = max(d, -sdBox(p - vec3(0.0, 9.5, 0.0), vec3(15.0, 4.0, 9.0)));


	d -= 0.02*smoothstep(0.5, 1.0, fbm4(p.zxy));
	d -= 0.01*smoothstep(0.4, 0.8, fbm4(op*3.0));
	d += 0.005;

	res = vec3(d, 1.0, res.z);

	return res;
}

vec3 map(in vec3 p)
{
	vec3 res = temple(p);

	{
		float h = terrain(p.xz);
		float m = p.y - h;
		m *= 0.35;
		if (m < res.x) res = vec3(m, 2.0, 0.0);
	}


	{
		float w = p.y + 25.0;
		if (w < res.x) res = vec3(w, 3.0, 0.0);
	}

	return res;
}

// http://iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 calcNormal(in vec3 p, in float t)
{
#if 0    
	float e = 0.001*t;

	vec2 h = vec2(1.0, -1.0)*0.5773;
	return normalize(h.xyy*map(p + h.xyy*e).x +
		h.yyx*map(p + h.yyx*e).x +
		h.yxy*map(p + h.yxy*e).x +
		h.xxx*map(p + h.xxx*e).x);
#else    
	// inspired by klems - a way to prevent the compiler from inlining map() 4 times
	vec3 n = vec3(0.0);
	for (int i = ZERO; i < 4; i++)
	{
		vec3 e = 0.5773*(2.0*vec3((((i + 3) >> 1) & 1), ((i >> 1) & 1), (i & 1)) - 1.0);
		n += e * map(p + e * 0.001*t).x;
	}
	return normalize(n);
#endif    
}

vec3 intersect(in vec3 ro, in vec3 rd)
{
	vec2 ma = vec2(0.0);

	vec3 res = vec3(-1.0);

	float tmax = 1000.0;

	float tp = (ocean - ro.y) / rd.y;
	if (tp > 0.0)
	{
		tmax = tp;
		res = vec3(tp, 3.0, 0.0);
	}

	float t = 10.0;
	for (int i = 0; i < 256; i++)
	{
		vec3 pos = ro + t * rd;
		vec3 h = map(pos);
		if (h.x<(0.0001*t) || t>tmax) break;
		t += h.x;

		ma = h.yz;
	}

	if (t < tmax)
	{
		res = vec3(t, ma);
	}

	return res;
}

vec4 textureBox(in sampler2D tex, in vec3 pos, in vec3 nor)
{
	vec4 cx = texture(tex, pos.yz);
	vec4 cy = texture(tex, pos.xz);
	vec4 cz = texture(tex, pos.xy);
	vec3 m = nor * nor;
	return (cx*m.x + cy * m.y + cz * m.z) / (m.x + m.y + m.z);
}

float calcShadow(in vec3 ro, in vec3 rd, float k)
{
	float res = 1.0;

	float t = 0.01;
	for (int i = 0; i < 128; i++)
	{
		vec3 pos = ro + t * rd;
		float h = map(pos).x;
		res = min(res, k*max(h, 0.0) / t);
		if (res < 0.0001) break;
		t += clamp(h, 0.01, 0.5);
	}

	return res;
}

float calcOcclusion(in vec3 pos, in vec3 nor, float ra)
{
	float occ = 0.0;
	for (int i = ZERO; i < 32; i++)
	{
		float h = 0.01 + 4.0*pow(float(i) / 31.0, 2.0);
		vec2 an = hash2(ra + float(i)*13.1)*vec2(3.14159, 6.2831);
		vec3 dir = vec3(sin(an.x)*sin(an.y), sin(an.x)*cos(an.y), cos(an.x));
		dir *= sign(dot(dir, nor));
		occ += clamp(5.0*map(pos + h * dir).x / h, -1.0, 1.0);
	}
	return clamp(occ / 32.0, 0.0, 1.0);
}


vec3 lig1 = normalize(vec3(0.7, 0.1, 0.4));
vec3 lig2 = normalize(vec3(0.7, 0.3, 0.4));

vec3 skyColor(in vec3 ro, in vec3 rd)
{
	vec3 col = vec3(0.3, 0.4, 0.5)*0.3 - 0.3*rd.y;

	float t = (1000.0 - ro.y) / rd.y;
	if (t > 0.0)
	{
		vec2 uv = (ro + t * rd).xz;
		float cl = texture(iChannel0, .000003*uv.yx).x;
		cl = smoothstep(0.3, 0.7, cl);
		col = mix(col, vec3(0.3, 0.2, 0.1), 0.1*cl);
	}

	col = mix(col, vec3(0.2, 0.25, 0.30)*0.5, exp(-30.0*rd.y));

	float sd = pow(clamp(0.25 + 0.75*dot(lig1, rd), 0.0, 1.0), 4.0);
	col = mix(col, vec3(1.2, 0.30, 0.05) / 1.2, sd*exp(-abs((60.0 - 50.0*sd)*rd.y)));

	return col;
}

vec3 doBumpMap(in vec3 pos, in vec3 nor)
{
	float e = 0.002;
	float b = 0.015;

	float ref = fbm6(4.0*pos);
	vec3 gra = -b * vec3(fbm6(4.0*vec3(pos.x + e, pos.y, pos.z)) - ref,
		fbm6(4.0*vec3(pos.x, pos.y + e, pos.z)) - ref,
		fbm6(4.0*vec3(pos.x, pos.y, pos.z + e)) - ref) / e;

	vec3 tgrad = gra - nor * dot(nor, gra);
	return normalize(nor - tgrad);
}

vec3 doBumpMapGrass(in vec2 pos, in vec3 nor, out float hei)
{
	float e = 0.002;
	float b = 0.03;

	float ref = fbm6(4.0*pos);
	hei = ref;

	vec3 gra = -b * vec3(fbm6(4.0*vec2(pos.x + e, pos.y)) - ref,
		e,
		fbm6(4.0*vec2(pos.x, pos.y + e)) - ref) / e;

	vec3 tgrad = gra - nor * dot(nor, gra);
	return normalize(nor - tgrad);
}

mat3 setCamera(in vec3 ro, in vec3 ta, float cr)
{
	vec3 cw = normalize(ta - ro);
	vec3 cp = vec3(sin(cr), cos(cr), 0.0);
	vec3 cu = normalize(cross(cw, cp));
	vec3 cv = normalize(cross(cu, cw));
	return mat3(cu, cv, cw);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
	float isThumbnail = step(iResolution.x, 499.0);

	vec2 o = (1.0 - isThumbnail)*(hash2(float(iFrame)) - 0.5);

	vec2 p = (-iResolution.xy + 2.0*(fragCoord + o)) / iResolution.y;

	uvec2 px = uvec2(fragCoord);
	float ran = hash(px.x + 1920U * px.y + (1920U * 1080U)*uint(iFrame * 0));

#ifdef STATICCAM
	float an = -0.96;
#else
	float an = -0.96 + sin(iTime*0.05)*0.1;
#endif
	float ra = 70.0;
	float fl = 3.0;
	vec3 ta = vec3(0.0, -3.0, -23.0);
	vec3 ro = ta + vec3(ra*sin(an), 10.0, ra*cos(an));
	mat3 ca = setCamera(ro, ta, 0.0);
	vec3 rd = ca * normalize(vec3(p.xy, fl));


	vec3 col = vec3(0.0);

	col = skyColor(ro, rd);

	float resT = 10000.0;
	vec3 res = intersect(ro, rd);
	if (res.y > 0.0)
	{
		float t = res.x;
		resT = t;
		vec3 pos = ro + t * rd;
		vec3 nor = calcNormal(pos, t);

		float fre = pow(clamp(1.0 + dot(nor, rd), 0.0, 1.0), 5.0);
		float foc = 1.0;

		vec3 mate = vec3(0.2);
		vec2 mspe = vec2(0.0);
		float mbou = 0.0;
		float mter = 0.0;
		if (res.y < 1.5)
		{
			vec3 te = textureBox(iChannel0, pos*0.05, nor).xyz;
			//mate = vec3(0.12,0.08,0.05) + 0.15*te;
			mate = vec3(0.14, 0.10, 0.07) + 0.1*te;
			mate *= 0.8 + 0.4*res.z;
			mate *= 1.15;
			mspe = vec2(1.0, 8.0);
			mbou = 1.0;

			nor = doBumpMap(pos, nor);

			foc = 0.7 + 0.3*smoothstep(0.4, 0.7, fbm4(3.0*pos));

			float ho = 1.0;
			if (pos.y > -7.5) ho *= smoothstep(0.0, 5.0, (pos.y + 7.5));
			ho = mix(0.1 + ho * 0.3, 1.0, clamp(0.6 + 0.4*dot(normalize(nor.xz*vec2(0.5, 1.0)), normalize(pos.xz*vec2(0.5, 1.0))) + 1.0*nor.y*nor.y, 0.0, 1.0));
			foc *= ho;
			foc *= 0.4 + 0.6*smoothstep(2.0, 15.0, length(pos*vec3(0.5, 0.25, 1.0)));
			float rdis = clamp(-0.15*max(sdRhombus(pos.yz - vec2(8.3, 0.0) + vec2(2.0, 0.0), vec2(2.25, 8.5), 0.05), -(pos.y - 8.3 + 2.0)), 0.0, 1.0);
			if (rdis > 0.0001) foc = 0.1 + sqrt(rdis);
			if (pos.y < 5.8) foc *= 0.6 + 0.4*smoothstep(0.0, 1.5, -(pos.y - 5.8));
			if (pos.y < 3.4) foc *= 0.6 + 0.4*smoothstep(0.0, 2.5, -(pos.y - 3.4));

			foc *= 0.8;
		}
		else if (res.y < 2.5)
		{
			mate = vec3(0.95, 0.9, 0.85) * 0.4*texture(iChannel0, pos.xz*0.015).xyz;
			mate *= 0.25 + 0.75*smoothstep(-25.0, -24.0, pos.y);
			mate *= 0.32;
			float h;
			vec3 mor = doBumpMapGrass(pos.xz, nor, h);
			mspe = vec2(2.5, 4.0);
			float is_grass = smoothstep(0.9, 0.95, mor.y);

			mate = mix(mate, vec3(0.15, 0.1, 0.0)*0.8*0.7 + h * h*h*vec3(0.12, 0.1, 0.05)*0.15, is_grass);
			mspe = mix(mspe, vec2(0.5, 4.0), is_grass);
			nor = mor;
			mter = 1.0;
		}
		else
		{
			mate = vec3(0.1, 0.21, 0.25)*0.45;
			mate += 2.0*vec3(0.01, 0.03, 0.03)*(1.0 - smoothstep(0.0, 10.0, pos.y - terrain(pos.xz)));
			mate *= 0.4;
			float foam = (1.0 - smoothstep(0.0, 1.0, pos.y - terrain(pos.xz)));
			foam *= smoothstep(0.35, 0.5, texture(iChannel0, pos.xz*0.07).x);
			mate += vec3(0.08)*foam;
			mspe = vec2(0.5, 8.0);

			vec2 e = vec2(0.01, 0.0);
			float ho = fbm4((pos.xz)*vec2(2.0, 0.5));
			float hx = fbm4((pos.xz + e.xy)*vec2(2.0, 0.5));
			float hy = fbm4((pos.xz + e.yx)*vec2(2.0, 0.5));
			float sm = (1.0 - smoothstep(0.0, 4.0, pos.y - terrain(pos.xz)));
			sm *= 0.02 + 0.03*foam;
			ho *= sm;
			hx *= sm;
			hy *= sm;

			nor = normalize(vec3(ho - hx, e.x, ho - hy));
		}

		float occ = 0.33 + 0.5*nor.y;
		occ = calcOcclusion(pos, nor, ran) * foc;

		float lf = 1.0 - smoothstep(30.0, 80.0, length(pos.z));
		vec3 lig = normalize(mix(lig1, lig2, lf));
		vec3 ligbak = normalize(vec3(-lig.x, 0.0, -lig.z));
		float dif = clamp(dot(nor, lig), 0.0, 1.0);
		float sha = calcShadow(pos + nor * 0.001, lig, 32.0);
		dif *= sha;
		float amb = (0.8 + 0.2*nor.y);
		amb = mix(amb, amb*(0.5 + 0.5*smoothstep(-8.0, -1.0, pos.y)), mbou);

		vec3 qos = pos / 1.5 - vec3(0.0, 1.0, 0.0);

		float bak = clamp(0.4 + 0.6*dot(nor, ligbak), 0.0, 1.0);
		bak *= 0.6 + 0.4*smoothstep(-8.0, -1.0, qos.y);


		float bou = 0.3*clamp(0.7 - 0.3*nor.y, 0.0, 1.0);
		bou *= smoothstep(8.0, 0.0, qos.y + 6.0)*smoothstep(-6.7, -6.4, qos.y);
		bou *= (0.7*smoothstep(3.0, 1.0, length((qos.xz - vec2(1.0, 6.0))*vec2(0.2, 1.0))) +
			smoothstep(5.0, 1.0, length((qos.xz - vec2(5.0, -3.0))*vec2(0.4, 1.0))));


		bou += 0.1*smoothstep(5.0, 1.0, length((qos - vec3(-5.0, 0.0, -5.0))*vec3(0.7, 0.8, 1.5)));

		vec3 hal = normalize(lig - rd);
		float spe = pow(clamp(dot(nor, hal), 0.0, 1.0), mspe.y)*(0.1 + 0.9*fre)*sha*(0.5 + 0.5*occ);

		col = vec3(0.0);
		col += amb * 1.0*vec3(0.15, 0.25, 0.35)*occ*(1.0 + mter);
		col += dif * 5.0*vec3(0.90, 0.55, 0.35);
		col += bak * 1.7*vec3(0.10, 0.11, 0.12)*occ*mbou;
		col += bou * 3.0*vec3(1.00, 0.50, 0.15)*occ*mbou;
		col += spe * 6.0*mspe.x*occ;

		col *= mate;

		vec3 fogcol = vec3(0.2, 0.25, 0.30)*0.5;
		float sd = pow(clamp(0.25 + 0.75*dot(lig, rd), 0.0, 1.0), 4.0);
		fogcol = mix(fogcol, vec3(1.2, 0.30, 0.05) / 1.2, sd*exp(-abs((60.0 - 50.0*sd)*abs(rd.y))));

		float fog = 1.0 - exp(-0.0013*t);
		col *= 1.0 - 0.5*fog;
		col = mix(col, fogcol, fog);
	}

	col = max(col, 0.0);

	col += 0.15*vec3(1.0, 0.8, 0.7)*pow(clamp(dot(rd, lig1), 0.0, 1.0), 6.0);

	col = 1.2*col / (1.0 + col);

	col = sqrt(col);


	col = clamp(1.4*col, 0.0, 1.0);
	col = col * 0.1 + 0.9*col*col*(3.0 - 2.0*col);
	col = pow(col, vec3(0.83, 1.0, 1.0));
	col = clamp((col - 0.05)*1.4, 0.0, 1.0);

	//------------------------------------------
	// reproject from previous frame and average
	//------------------------------------------
#ifdef STATICCAM
	vec3 ocol = texelFetch(iChannel3, ivec2(fragCoord - 0.5), 0).xyz;
	if (iFrame == 0) ocol = col;
	col = mix(ocol, col, 0.05);
	fragColor = vec4(col, 1.0);
#else
	mat4 oldCam = mat4(texelFetch(iChannel3, ivec2(0, 0), 0),
		texelFetch(iChannel3, ivec2(1, 0), 0),
		texelFetch(iChannel3, ivec2(2, 0), 0),
		0.0, 0.0, 0.0, 1.0);

	// world space
	vec4 wpos = vec4(ro + rd * resT, 1.0);
	// camera space
	vec3 cpos = (wpos*oldCam).xyz; // note inverse multiply
	// ndc space
	vec2 npos = fl * cpos.xy / cpos.z;
	// screen space
	vec2 spos = 0.5 + 0.5*npos*vec2(iResolution.y / iResolution.x, 1.0);
	// undo dither
	spos -= o / iResolution.xy;
	// raster space
	vec2 rpos = spos * iResolution.xy;

	if ((rpos.y < 1.0 && rpos.x < 3.0) || (isThumbnail > 0.5))
	{
	}
	else
	{
		vec4 data = textureLod(iChannel3, spos, 0.0);
		vec3 ocol = data.xyz;
		float dt = abs(data.w - resT) / resT;
		if (iFrame == 0) ocol = col;
		col = mix(ocol, col, 0.1 + 0.5*smoothstep(0.1, 0.2, dt));
	}

	if (fragCoord.y < 1.0 && fragCoord.x < 3.0)
	{
		if (abs(fragCoord.x - 2.5) < 0.5) fragColor = vec4(ca[2], -dot(ca[2], ro));
		if (abs(fragCoord.x - 1.5) < 0.5) fragColor = vec4(ca[1], -dot(ca[1], ro));
		if (abs(fragCoord.x - 0.5) < 0.5) fragColor = vec4(ca[0], -dot(ca[0], ro));
	}
	else
	{
		fragColor = vec4(col, resT);
	}
#endif
}



void main() { mainImage(fragColor, fragCoord); }