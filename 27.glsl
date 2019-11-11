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



#define PIXEL_SAMPLES 		8				//Increase for higher quality
#define CAMERA_LENS_RADIUS	0.1				//Increase for DoF
#define FRAME_TIME			0.05			//Increase for Motion blur
#define VOLUME_SCAATTERING	0.01			//Increase for more fog
#define GAMMA 				2.2				//
//#define OCULUS_VERSION

const vec3 backgroundColor = vec3(0.0);
float frameSta;
float frameEnd;

//used macros and constants
#define PI 					3.1415926
#define TWO_PI 				6.2831852
#define FOUR_PI 			12.566370
#define INV_PI 				0.3183099
#define INV_TWO_PI 			0.1591549
#define INV_FOUR_PI 		0.0795775
#define EPSILON 			0.00001 
#define EQUAL_FLT(a,b,eps)	(((a)>((b)-(eps))) && ((a)<((b)+(eps))))
#define IS_ZERO(a) 			EQUAL_FLT(a,0.0,EPSILON)
//********************************************

#define MATERIAL_COUNT 		10
#define BSDF_COUNT 			3
#define BSDF_R_DIFFUSE 		0
#define BSDF_R_GLOSSY 		1
#define BSDF_R_SPECULAR 	2
#define BSDF_R_LIGHT 		3

// random number generator **********
// taken from iq :)
float seed;	//seed initialized in main
float rnd() { return fract(sin(seed++)*43758.5453123); }
//***********************************

//************************************************************************************
#define BRIGHTNESS(c) (0.2126*c.x + 0.7152*c.y + 0.0722*c.z)

// Data structures ****************** 
struct Sphere { int materialId; vec3 pos; float radius; float radiusSq; float area; };
struct LightSample { vec3 pos; vec3 intensity; vec3 normal; float weight; };
struct Plane { vec4 abcd; };
struct Range { float min_; float max_; };
struct Material { vec3 color; float roughness_; int bsdf_; };
struct RayHit { vec3 pos; vec3 normal; vec3 E; vec2 uv; int materialId; };
struct Ray { vec3 origin; vec3 dir; };
struct Camera { mat3 rotate; vec3 pos; vec3 target; float fovV; float lensSize; float focusDist; };
//***********************************

// ************ SCENE ***************
Plane ground;
#define LIGHT_COUNT 2
Sphere spherelight[LIGHT_COUNT];
Sphere sphereGeometry;
Camera camera;
//***********************************

Sphere GetLightSphere(int lightId) {
	return spherelight[lightId];
}

#define MTL_LIGHT_1			0
#define MTL_LIGHT_2			1
#define MTL_WALL			2
#define MTL_SPHERE			4

Material materialLibrary[MATERIAL_COUNT];
#define INIT_MTL(i,bsdf,phongExp,colorVal) materialLibrary[i].bsdf_=bsdf; materialLibrary[i].roughness_=phongExp; materialLibrary[i].color=colorVal;
void initMaterialLibrary()
{
	INIT_MTL(MTL_WALL, BSDF_R_DIFFUSE, 0.0, vec3(1.0));

	vec3 color = vec3(256.0, 240.0, 160.0);
	vec3 blue = vec3(200.0, 200.0, 256.0);

	INIT_MTL(MTL_LIGHT_1, BSDF_R_LIGHT, 0.0, color*(sin(iTime*1.3) + 1.1));
	INIT_MTL(MTL_LIGHT_2, BSDF_R_LIGHT, 0.0, blue);
	INIT_MTL(MTL_SPHERE, BSDF_R_DIFFUSE, 0.0, vec3(0.8));
}

void UpdateMaterial() {

}

Material getMaterialFromLibrary(int index) {
	return materialLibrary[index];
}

void initScene() {
	float time = iTime;
	float frameSta = iTime;
	float frameEnd = frameSta + FRAME_TIME;

	//init lights
	float r = 0.1;
	spherelight[0] = Sphere(MTL_LIGHT_1, vec3(2.0, 2.5, -4.0), r, r*r, r*r*4.0*PI);
	// r = 0.2;
	spherelight[1] = Sphere(MTL_LIGHT_2, vec3(-1.0, 3.5, -2.0), r, r*r, r*r*4.0*PI);

	//ground
	ground.abcd = vec4(0.0, 1.0, 0.0, 1.0);

	float xFactor = (iMouse.x == 0.0) ? 0.0 : 2.0*(iMouse.x / iResolution.x) - 1.0;
	float yFactor = (iMouse.y == 0.0) ? 0.0 : 2.0*(iMouse.y / iResolution.y) - 1.0;
	sphereGeometry = Sphere(MTL_WALL, vec3(xFactor*5.0, 1.0, -5.0 - yFactor * 4.0), 1.0, 1.0, 4.0*PI);
}

void updateScene() {
	vec3 pos1 = vec3(2.0, 2.5 + sin(frameSta*0.15)*1.74, -4.0 + sin(frameSta*0.3)*2.734);
	vec3 pos2 = vec3(2.0, 2.5 + sin(frameEnd*0.15)*1.74, -4.0 + sin(frameEnd*0.3)*2.734);
	spherelight[0].pos = mix(pos1, pos2, rnd());

	float y1 = 1.0 + sin(frameSta*0.7123);
	float y2 = 1.0 + sin(frameEnd*0.7123);
	sphereGeometry.pos.y = mix(y1, y2, rnd());
}

// ************************  INTERSECTION FUNCTIONS **************************
bool raySphereIntersection(Ray ray, in Sphere sph, out float dist) {
	float t = -1.0;
	vec3  ce = ray.origin - sph.pos;
	float b = dot(ray.dir, ce);
	float c = dot(ce, ce) - sph.radiusSq;
	float h = b * b - c;
	if (h > 0.0) {
		t = -b - sqrt(h);
	}

	if (t > 0.0) {
		dist = t;
		return true;
	}

	return false;
}

bool rayPlaneIntersection(Ray ray, Plane plane, out float t) {
	float dotVN = dot(ray.dir, plane.abcd.xyz);

	t = -(dot(ray.origin, plane.abcd.xyz) + plane.abcd.w) / dotVN;
	return (t > 0.0);
}
// ***************************************************************************


// Geometry functions ***********************************************************
vec2 uniformPointWithinCircle(in float radius, in float Xi1, in float Xi2) {
	float r = radius * sqrt(Xi1);
	float theta = Xi2;
	return vec2(r*cos(theta), r*sin(theta));
}

vec3 uniformDirectionWithinCone(in vec3 d, in float phi, in float sina, in float cosa) {
	vec3 w = normalize(d);
	vec3 u = normalize(cross(w.yzx, w));
	vec3 v = cross(w, u);
	return (u*cos(phi) + v * sin(phi)) * sina + w * cosa;
}

vec3 localToWorld(in vec3 localDir, in vec3 normal)
{
	vec3 binormal = normalize((abs(normal.x) > abs(normal.z)) ? vec3(-normal.y, normal.x, 0.0) : vec3(0.0, -normal.z, normal.y));
	vec3 tangent = cross(binormal, normal);

	return localDir.x*tangent + localDir.y*binormal + localDir.z*normal;
}

vec3 sphericalToCartesian(in float rho, in float phi, in float theta) {
	float sinTheta = sin(theta);
	return vec3(sinTheta*cos(phi), sinTheta*sin(phi), cos(theta))*rho;
}

vec3 sampleHemisphereCosWeighted(in vec3 n, in float Xi1, in float Xi2) {
	float theta = acos(sqrt(1.0 - Xi1));
	float phi = TWO_PI * Xi2;

	return localToWorld(sphericalToCartesian(1.0, phi, theta), n);
}

vec3 sampleHemisphere(const vec3 n, in float Xi1, in float Xi2) {
	vec2 r = vec2(Xi1, Xi2)*TWO_PI;
	vec3 dr = vec3(sin(r.x)*vec2(sin(r.y), cos(r.y)), cos(r.x));
	return dot(dr, n) * dr;
}

//tacken from sjb
void sampleEquiAngular(
	Ray ray,
	float maxDistance,
	float Xi,
	vec3 lightPos,
	out float dist,
	out float pdf)
{
	// get coord of closest point to light along (infinite) ray
	float delta = dot(lightPos - ray.origin, ray.dir);

	// get distance this point is from light
	float D = length(ray.origin + delta * ray.dir - lightPos);

	// get angle of endpoints
	float thetaA = atan(0.0 - delta, D);
	float thetaB = atan(maxDistance - delta, D);

	// take sample
	float t = D * tan(mix(thetaA, thetaB, Xi));
	dist = delta + t;
	pdf = D / ((thetaB - thetaA)*(D*D + t * t));
}
//*****************************************************************************


///////////////////////////////////////////////////////////////////////
void initCamera(in vec3 pos, in vec3 target, in vec3 upDir, in float fovV, in float lensSize, in float focusDist) {
	vec3 back = normalize(pos - target);
	vec3 right = normalize(cross(upDir, back));
	vec3 up = cross(back, right);
	camera.rotate[0] = right;
	camera.rotate[1] = up;
	camera.rotate[2] = back;
	camera.fovV = fovV;
	camera.pos = pos;
	camera.lensSize = lensSize;
	camera.focusDist = focusDist;
}

void updateCamera(int strata) {
	float strataSize = 1.0 / float(PIXEL_SAMPLES);
	float r1 = strataSize * (float(strata) + rnd());
	//update camera pos
#ifdef OCULUS_VERSION
	float cameraZ = -1.0;
#else
	float cameraZ = 4.0;
#endif
	vec3 upDir = vec3(0.0, 1.0, 0.0);
	vec3 pos1, pos2;
	pos1 = vec3(sin(frameSta*0.154)*2.0, 2.0 + sin(frameSta*0.3)*2.0, cameraZ + sin(frameSta*0.8));
	pos2 = vec3(sin(frameEnd*0.154)*2.0, 2.0 + sin(frameEnd*0.3)*2.0, cameraZ + sin(frameEnd*0.8));
	camera.pos = mix(pos1, pos2, r1);

	pos1 = vec3(sin(frameSta*0.4)*0.3, 1.0, -5.0);
	pos2 = vec3(sin(frameEnd*0.4)*0.3, 1.0, -5.0);
	camera.target = mix(pos1, pos2, r1);

	vec3 back = normalize(camera.pos - camera.target);
	vec3 right = normalize(cross(upDir, back));
	vec3 up = cross(back, right);
	camera.rotate[0] = right;
	camera.rotate[1] = up;
	camera.rotate[2] = back;
}

Ray genRay(in vec2 pixel, in float Xi1, in float Xi2)
{
	Ray ray;

#ifdef OCULUS_VERSION
	vec2 displaySize = vec2(iResolution.x*0.5, iResolution.y);
	vec2 uv;

	if (pixel.x < displaySize.x) {
		ray.origin = camera.pos - camera.rotate[0] * 0.2;
		uv = pixel / displaySize;
	}
	else {
		ray.origin = camera.pos + camera.rotate[0] * 0.2;
		uv = vec2(pixel.x - displaySize.x, pixel.y) / displaySize;
	}

	uv = (uv*2.0 - 1.0)*vec2(displaySize.x / displaySize.y, 1.);

	float fov = camera.fovV;
	float angle = fov / 4.0;
	float a = sin(angle);

	uv *= a;

	if (length(uv) > 1.0) {
		Ray ray;
		ray.origin = vec3(0.0, 0.0, 0.0);
		ray.dir = vec3(0.0, 0.0, 0.0);
		return ray;
	}

	vec3 cameraDirInv = vec3(0.0, 0.0, 1.0);
	vec3 normal;
	normal.x = -uv.x;
	normal.y = -uv.y;
	normal.z = sqrt(1.0 - (uv.x*uv.x + uv.y*uv.y));

	ray.dir = camera.rotate*reflect(cameraDirInv, normal);

	return ray;
#else
	vec2 iPlaneSize = 2.*tan(0.5*camera.fovV)*vec2(iResolution.x / iResolution.y, 1.);
	vec2 ixy = (pixel / iResolution.xy - 0.5)*iPlaneSize;

	if (camera.lensSize > EPSILON) {
		vec2 uv = uniformPointWithinCircle(camera.lensSize, rnd(), rnd());
		vec3 newPos = camera.pos + camera.rotate[0] * uv.x*camera.lensSize + camera.rotate[1] * uv.y*camera.lensSize;
		vec3 focusPoint = camera.pos - camera.focusDist*camera.rotate[2];
		vec3 newBack = normalize(newPos - focusPoint);
		vec3 newRight = normalize(cross(camera.rotate[1], newBack));
		vec3 newUp = cross(newBack, newRight);
		mat3 newRotate;
		newRotate[0] = newRight;
		newRotate[1] = newUp;
		newRotate[2] = newBack;


		ray.origin = newPos;
		ray.dir = newRotate * normalize(vec3(ixy.x, ixy.y, -1.0));
	}
	else {
		ray.origin = camera.pos;
		ray.dir = camera.rotate*normalize(vec3(ixy.x, ixy.y, -1.0));
	}

	return ray;
#endif
}

bool raySceneIntersection(in Ray ray, in float distMin, out RayHit hit, out int objId, out float dist) {
	float nearest_dist = 10000.0;

	//check lights
	for (int i = 0; i < LIGHT_COUNT; i++) {
		float distToLight;
		if (raySphereIntersection(ray, spherelight[i], distToLight) && (distToLight > distMin) && (distToLight < nearest_dist)) {
			nearest_dist = distToLight;

			hit.pos = ray.origin + ray.dir*nearest_dist;
			hit.normal = normalize(hit.pos - spherelight[i].pos);
			hit.materialId = i;
			objId = i;
		}
	}

	//check sphere
	float distToSphere;
	if (raySphereIntersection(ray, sphereGeometry, distToSphere) && (distToSphere > distMin) && (distToSphere < nearest_dist)) {
		nearest_dist = distToSphere;

		hit.pos = ray.origin + ray.dir*nearest_dist;
		hit.normal = normalize(hit.pos - sphereGeometry.pos);

		vec3 n = normalize(vec3(hit.normal.x, 0.0, hit.normal.z));
		float u = acos(dot(vec3(1.0, 0.0, 0.0), n)) / PI;
		float v = acos(dot(vec3(0.0, 1.0, 0.0), hit.normal)) / PI;

		hit.uv = vec2(u, v);

		hit.materialId = MTL_SPHERE;
		objId = 2;
	}

	//check ground
	float distToPlane;
	if (rayPlaneIntersection(ray, ground, distToPlane) && (distToPlane > distMin) && (distToPlane < nearest_dist)) {
		nearest_dist = distToPlane;

		hit.pos = ray.origin + ray.dir*nearest_dist;
		hit.normal = ground.abcd.xyz;
		float uvScale = 2.0;
		hit.uv = vec2(abs(mod(hit.pos.x, uvScale) / uvScale), abs(mod(hit.pos.z, uvScale) / uvScale));
		hit.materialId = MTL_WALL;
		objId = 3;
	}

	dist = nearest_dist;
	if (nearest_dist < 1000.0) {
		hit.E = ray.dir*(-1.0);
		return true;
	}
	else {
		return false;
	}
}

float brdfEvalBrdfPhong(in  vec3 N, in vec3 E, in vec3 L, in float roughness) {
	vec3 R = reflect(E*(-1.0), N);
	float dotLR = dot(L, R);
	dotLR = max(0.0, dotLR);
	return pow(dotLR, roughness + 1.0)*(roughness + 1.0)*(INV_PI);
}

float brdfEvalBrdfDiffuse(in vec3 N, in vec3 L) {
	return clamp(dot(N, L), 0.0, 1.0)*INV_PI;
}

// GGX *****************************************************************************************
float ggx_eval(in float dotNH, float alpha) {
	float cosThetaM = dotNH;

	if (cosThetaM < EPSILON) {
		return 0.0;
	}
	else {
		float alpha2 = alpha * alpha;
		float cosThetaM2 = cosThetaM * cosThetaM;
		float tanThetaM2 = (1.0 - cosThetaM2) / cosThetaM2;
		float cosThetaM4 = cosThetaM2 * cosThetaM2;
		return alpha2 / (PI * cosThetaM4 * pow(alpha2 + tanThetaM2, 2.0));
	}
}

vec3 ggx_sample(vec3 N, float alpha, float Xi1, float Xi2) {
	vec3 Z = N;
	vec3 X = sampleHemisphere(N, Xi1, Xi2);
	vec3 Y = cross(X, Z);
	X = cross(Z, Y);

	float alpha2 = alpha * alpha;
	float tanThetaM2 = alpha2 * Xi1 / (1.0 - Xi1);
	float cosThetaM = 1.0 / sqrt(1.0 + tanThetaM2);
	float sinThetaM = cosThetaM * sqrt(tanThetaM2);
	float phiM = TWO_PI * Xi2;

	return X * (cos(phiM) * sinThetaM) + Y * (sin(phiM) * sinThetaM) + Z * cosThetaM;
}

float ggx_g1(in float dotNV, in float dotHV, float alpha) {
	if ((dotHV / dotNV) < EPSILON) {
		return 0.0;
	}
	else {
		float cosThetaV_2 = dotNV * dotNV;
		float tanThetaV_2 = 1.0 - cosThetaV_2;
		float alpha2 = alpha * alpha;
		return 2.0 / (1.0 + sqrt(1.0 + alpha2 * tanThetaV_2 / cosThetaV_2));
	}
}

vec3 evalBRDF(vec3 n, vec3 l, vec3 v, float m, vec3 cdiff, vec3 cspec) {
	vec3  h = normalize(l + v);
	float dotNH = max(dot(n, h), 0.0);
	float dotNV = max(dot(n, v), 0.0);
	float dotNL = max(dot(n, l), 0.0);
	float dotHV = max(dot(h, v), 0.0);
	float dotHL = dotHV;

	float G = ggx_g1(dotNV, dotHV, m)*ggx_g1(dotNL, dotHL, m);
	float D = ggx_eval(dotNH, m);
	vec3  F = cspec + (1.0 - cspec) * pow(1.0 - dotHL, 5.0);

	// BRDF Torrance-Sparrow specular
	vec3 spec = (F * D * G) / (dotNV * dotNL * 4.0);

	// BRDF Lambertian diffuse
	vec3 diff = (cdiff * (1.0 - F));

	// Punctual Light Source ( cancel pi )
	return (spec + diff) * dotNL;
}

vec3 calcDirectLight(vec3 pos, out vec3 wi, Sphere lightSphere, vec3 lightColor) {
	vec3 Li = lightColor;
	vec3 Lo = vec3(0.0);

	vec3 dirToLightCenter = lightSphere.pos - pos;
	float distToLightCenter2 = dot(dirToLightCenter, dirToLightCenter);
	float cos_a_max = sqrt(1.0 - clamp(lightSphere.radiusSq / distToLightCenter2, 0.0, 1.0));
	float omega = TWO_PI * (1.0 - cos_a_max);	//solid angle
	float cosa = mix(cos_a_max, 1.0, rnd());
	float sina = sqrt(1.0 - cosa * cosa);

	wi = uniformDirectionWithinCone(dirToLightCenter, TWO_PI*rnd(), sina, cosa);
	float pWi = (1.0 / omega);

	Ray shadowRay = Ray(pos, wi);
	float dist;
	raySphereIntersection(shadowRay, lightSphere, dist);

	float tmpDist;
	RayHit tmpHit;
	int tmpObjId;
	raySceneIntersection(shadowRay, EPSILON, tmpHit, tmpObjId, tmpDist);
	float eps = tmpDist * 0.0001;

	if (EQUAL_FLT(tmpDist, dist, eps)) {
		Lo += (Li) / pWi;
	}

	return Lo;
}

vec3 calcLightOnSurface(RayHit hit) {
	vec3 Lo = vec3(0.0);
	Material surfMtl = getMaterialFromLibrary(hit.materialId);

	if (surfMtl.bsdf_ == BSDF_R_LIGHT) {
		Lo = surfMtl.color;
	}
	else {
		vec3 surfColor = surfMtl.color;
		float specVal = 0.7;

		if (hit.materialId == MTL_WALL) {
			surfColor = texture(iChannel0, hit.uv).xyz;
		}
		else if (hit.materialId == MTL_SPHERE) {
			surfColor = texture(iChannel1, hit.uv).xyz;
			specVal = 1.0 - BRIGHTNESS(texture(iChannel1, hit.uv).xyz);
		}

		vec3 wi;

		for (int i = 0; i < LIGHT_COUNT; i++) {
			vec3 Li = materialLibrary[i].color;
			vec3 directLight = calcDirectLight(hit.pos, wi, spherelight[i], Li);

			if (dot(wi, hit.normal) > 0.0) {
				vec3 cdiff = vec3(specVal);
				vec3 cspec = vec3(1.0 - specVal);
				vec3 brdf = evalBRDF(hit.normal, wi, hit.E, 0.4, cdiff, cspec);

				Lo += directLight * brdf*surfColor;
			}
		}
		Lo *= 1.0 / float(LIGHT_COUNT);
	}

	return Lo;
}

vec3 calcLightOnParticle(vec3 particlePos, Sphere lightSphere, vec3 Li) {
	vec3 wi;
	return calcDirectLight(particlePos, wi, lightSphere, Li);
}

vec3 Radiance(in Ray ray, float Xi) {
	vec3 surfaceShaded = vec3(0.0);


	RayHit hit;
	int objId;
	float dist = 100.0;
	if (raySceneIntersection(ray, 0.0, hit, objId, dist)) {
		surfaceShaded = calcLightOnSurface(hit);
	}

	vec3 particleShaded = vec3(0.0);
	for (int i = 0; i < LIGHT_COUNT; i++) {
		vec3 Li = (i == 0) ? materialLibrary[MTL_LIGHT_1].color : materialLibrary[MTL_LIGHT_2].color;
		float particleDist;
		float particlePdf;
		sampleEquiAngular(ray, dist, Xi, spherelight[i].pos, particleDist, particlePdf);
		vec3 particlePos = ray.origin + particleDist * ray.dir;

		particleShaded += VOLUME_SCAATTERING * calcLightOnParticle(particlePos, spherelight[i], Li) / particlePdf;
	}
	particleShaded *= 1.0 / float(LIGHT_COUNT);

	return surfaceShaded + particleShaded;
}

void mainImage(out vec4 fragColor, vec2 fragCoord2)
{
	vec2 fragCoord = (fragCoord2 +0.5) * iResolution.xy;
	frameSta = iTime;
	frameEnd = frameSta + FRAME_TIME;

	seed = /*iTime +*/ iResolution.y * fragCoord.x / iResolution.x + fragCoord.y / iResolution.y;

	float sinTime = sin(iTime*0.2);

#ifdef OCULUS_VERSION
	float fov = radians(110.0);
#else
	float fov = radians(45.0);
#endif
	initCamera(vec3(0.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), fov, CAMERA_LENS_RADIUS, 8.0);

	initMaterialLibrary();
	initScene();

	vec3 accumulatedColor = vec3(0.0);
	for (int si = 0; si < PIXEL_SAMPLES; ++si) {
		updateScene();
		updateCamera(si);

		vec2 screenCoord = fragCoord.xy + vec2((1.0 / float(PIXEL_SAMPLES))*(float(si) + rnd()), rnd());
		Ray ray = genRay(screenCoord, rnd(), rnd());

		if (length(ray.dir) < 0.2) {
			accumulatedColor = vec3(0.0);
		}
		else {
			accumulatedColor += Radiance(ray, (1.0 / float(PIXEL_SAMPLES))*(float(si) + rnd()));
		}
	}

	//devide to sample count
	accumulatedColor = accumulatedColor * (1.0 / float(PIXEL_SAMPLES));

	//gamma correction
	accumulatedColor = pow(accumulatedColor, vec3(1.0 / GAMMA));


	fragColor = vec4(accumulatedColor, 1.0);
}





void main() { mainImage(fragColor, fragCoord); }