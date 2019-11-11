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


//////TEST SHADER -- for experimentation only:
//vec2 hash(vec2 p) {
//	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
//	return -1.0 + 2.0*fract(sin(p)*43758.5453123);
//}
//float hash1(vec2 p)
//{
//	p = 50.0*fract(p*0.3183099);
//	return fract(p.x*p.y*(p.x + p.y));
//}
//
//float hash1(float n)
//{
//	return fract(n*17.0*fract(n*0.3183099));
//}
//
//vec2 hash2(float n) { return fract(sin(vec2(n, n + 1.0))*vec2(43758.5453123, 22578.1459123)); }
//
//
//vec2 hash2(vec2 p)
//{
//	const vec2 k = vec2(0.3183099, 0.3678794);
//	p = p * k + k.yx;
//	return fract(16.0 * k*fract(p.x*p.y*(p.x + p.y)));
//}
//
//
//const mat2 m = mat2(1.6, 1.2, -1.2, 1.6);
//mat2 m2 = mat2(0.8, 0.6, -0.6, 0.8);
//mat2 im2 = mat2(0.8, -0.6, 0.6, 0.8);
//const mat3 m3 = mat3(0.00, 0.80, 0.60,
//		-0.80, 0.36, -0.48,
//		-0.60, -0.48, 0.64);
//const vec3  kSunDir = vec3(-0.624695, 0.468521, -0.624695);
//const float kMaxTreeHeight = 2.0;
//const mat3 m3i = mat3(0.00, -0.80, -0.60,
//	0.80, 0.36, -0.48,
//	0.60, -0.48, 0.64);
//
//float noise(vec2 p) {
//
//	float res = 0.;
//	float f = 1.;
//	for (int i = 0; i < 3; i++)
//	{
//		p = m2 * p*f + .6;
//		f *= 1.2;
//		res += sin(p.x + sin(2.*p.y));
//	}
//	return res / 3.;
//}
//
//float noise(in vec3 x)
//{
//	vec3 p = floor(x);
//	vec3 w = fract(x);
//
//	vec3 u = w * w*w*(w*(w*6.0 - 15.0) + 10.0);
//
//	float n = p.x + 317.0*p.y + 157.0*p.z;
//
//	float a = hash1(n + 0.0);
//	float b = hash1(n + 1.0);
//	float c = hash1(n + 317.0);
//	float d = hash1(n + 318.0);
//	float e = hash1(n + 157.0);
//	float f = hash1(n + 158.0);
//	float g = hash1(n + 474.0);
//	float h = hash1(n + 475.0);
//
//	float k0 = a;
//	float k1 = b - a;
//	float k2 = c - a;
//	float k3 = e - a;
//	float k4 = a - b - c + d;
//	float k5 = a - c - e + g;
//	float k6 = a - b - e + f;
//	float k7 = -a + b + c - d + e - f - g + h;
//
//	return -1.0 + 2.0*(k0 + k1 * u.x + k2 * u.y + k3 * u.z + k4 * u.x*u.y + k5 * u.y*u.z + k6 * u.z*u.x + k7 * u.x*u.y*u.z);
//}
//
//vec3 noised(vec2 p) {//noise with derivatives
//	float res = 0.;
//	vec2 dres = vec2(0.);
//	float f = 1.;
//	mat2 j = m2;
//	for (int i = 0; i < 3; i++)
//	{
//		p = m2 * p*f + .6;
//		f *= 1.2;
//		float a = p.x + sin(2.*p.y);
//		res += sin(a);
//		dres += cos(a)*vec2(1., 2.*cos(2.*p.y))*j;
//		j *= m2 * f;
//
//	}
//	return vec3(res, dres) / 3.;
//}
//
//
//
//float displacement = 1;
//float frequency = 1;
//int seed = 0;
//bool enableDistance = false;
//const int X_NOISE_GEN = 1619;
//const int Y_NOISE_GEN = 31337;
//const int Z_NOISE_GEN = 6971;
//const int SEED_NOISE_GEN = 1013;
//const int SHIFT_NOISE_GEN = 8;
//#define EPS 0.0001
//
//int IntValueNoise3D(int x, int y, int z, int seed)
//{
//	// All constants are primes and must remain prime in order for this noise
//	// function to work correctly.
//	int n = (
//		X_NOISE_GEN    * x
//		+ Y_NOISE_GEN * y
//		+ Z_NOISE_GEN * z
//		+ SEED_NOISE_GEN * seed)
//		& 0x7fffffff;
//	n = (n >> 13) ^ n;
//	return (n * (n * n * 60493 + 19990303) + 1376312589) & 0x7fffffff;
//}
//float ValueNoise3D(int x, int y, int z, int seed)
//{
//	return 1.0 - (IntValueNoise3D(x, y, z, seed) / 1073741824.0);
//}
//
//
//float Voronoi(float x, float y, float z){
//	x *= frequency;
//	y *= frequency;
//	z *= frequency;
//
//	int xInt = (x > 0.0 ? int(x) : int(x - 1));
//	int yInt = (y > 0.0 ? int(y) : int(y - 1));
//	int zInt = (z > 0.0 ? int(z) : int(z - 1));
//
//	float minDist = 2147483647.0;
//	float xCandidate = 0;
//	float yCandidate = 0;
//	float zCandidate = 0;
//
//	// Inside each unit cube, there is a seed point at a random position.  Go
//	// through each of the nearby cubes until we find a cube with a seed point
//	// that is closest to the specified position.
//	for (int zCur = zInt - 2; zCur <= zInt + 2; zCur++) {
//		for (int yCur = yInt - 2; yCur <= yInt + 2; yCur++) {
//			for (int xCur = xInt - 2; xCur <= xInt + 2; xCur++) {
//
//				// Calculate the position and distance to the seed point inside of
//				// this unit cube.
//				float xPos = xCur + ValueNoise3D(xCur, yCur, zCur, seed)*0.5;
//				float yPos = yCur + ValueNoise3D(xCur, yCur, zCur, seed + 1)*5;
//				float zPos = zCur + ValueNoise3D(xCur, yCur, zCur, seed + 2)*0.5;
//				float xDist = xPos - x;
//				float yDist = yPos - y;
//				float zDist = zPos - z;
//				float dist = xDist * xDist + yDist * yDist + zDist * zDist;
//
//				if (dist < minDist) {
//					// This seed point is closer to any others found so far, so record
//					// this seed point.
//					minDist = dist;
//					xCandidate = xPos;
//					yCandidate = yPos;
//					zCandidate = zPos;
//				}
//			}
//		}
//	}
//
//	float value;
//	if (enableDistance) {
//		// Determine the distance to the nearest seed point.
//		float xDist = xCandidate - x;
//		float yDist = yCandidate - y;
//		float zDist = zCandidate - z;
//		value = (sqrt(xDist * xDist + yDist * yDist + zDist * zDist)
//			) * 1.732051 - 1.0;
//	}
//	else {
//		value = 0.0;
//	}
//
//	// Return the calculated distance with the displacement value applied.
//	return value + (displacement * float(ValueNoise3D(
//		int((floor(xCandidate))),
//		int((floor(yCandidate))),
//		int((floor(zCandidate))),
//		seed
//	)));
//}
//
//float Voronoi(vec3 v) { return Voronoi(v.x, v.y, v.z); }
//
//float fbm(vec2 n) {
//	float total = 0.0, amplitude = 0.1;
//	for (int i = 0; i < 7; i++) {
//		total += noise(n) * amplitude;
//		n = m * n;
//		amplitude *= 0.4;
//	}
//	return total;
//}
//float fbm_4(in vec3 x)
//{
//	float f = 2.0;
//	float s = 0.5;
//	float a = 0.0;
//	float b = 0.5;
//	for (int i = 0; i < 4; i++)
//	{
//		float n = noise(x);
//		a += b * n;
//		b *= s;
//		x = f * m3*x;
//	}
//	return a;
//}
//
//float fbm_9(in vec2 x)
//{
//	float f = 1.9;
//	float s = 0.55;
//	float a = 0.0;
//	float b = 0.5;
//	for (int i = 0; i < 9; i++)
//	{
//		float n = noise(x);
//		a += b * n;
//		b *= s;
//		x = f * m2*x;
//	}
//	return a;
//}
//vec4 fbmd_8(in vec3 x)
//{
//	float f = 1.92;
//	float s = 0.5;
//	float a = 0.0;
//	float b = 0.5;
//	vec3  d = vec3(0.0);
//	mat3  m = mat3(1.0, 0.0, 0.0,
//		0.0, 1.0, 0.0,
//		0.0, 0.0, 1.0);
//	for (int i = 0; i < 7; i++)
//	{
//		vec4 n = vec4(noised(x.xy).xyz,1);
//		a += b * n.x;          // accumulate values		
//		d += b * m*n.yzw;      // accumulate derivatives
//		b *= s;
//		x = f * m3*x;
//		m = f * m3i*m;
//	}
//	return vec4(a, d);
//}
//float sdEllipsoidY(in vec3 p, in vec2 r)
//{
//	float k0 = length(p / r.xyx);
//	float k1 = length(p / (r.xyx*r.xyx));
//	return k0 * (k0 - 1.0) / k1;
//}	
//
//// Computes the inverse of a given quaternion
//vec4 QtnInverse(vec4 qtn)
//{
//	return vec4(qtn.xyz * -1.0, qtn.w);
//}
//
//// Compute the product of two quaternions
//vec4 QtnProduct(vec4 qtnA, vec4 qtnB)
//{
//	vec3 vecA = qtnA.w * qtnB.xyz;
//	vec3 vecB = qtnB.w * qtnA.xyz;
//	vec3 orthoVec = cross(qtnA.xyz, qtnB.xyz);
//
//	return vec4(vecA + vecB + orthoVec,
//		(qtnA.w * qtnB.w) - dot(qtnA.xyz, qtnB.xyz));
//}
//
//// Perform rotation by applying the given quaternion to
//// the given vector
//vec3 QtnRotate(vec3 vec, vec4 qtn)
//{
//	vec4 qv = QtnProduct(qtn, vec4(vec, 0.0));
//	return QtnProduct(qv, QtnInverse(qtn)).xyz;
//}
//
//float SphereDF(vec3 coord, float r)
//{
//	vec3 sphPos = vec3(0.0, 0.0, 2.0);
//	return length(coord - sphPos) - r;
//}
//
//float CubeDF(vec3 coord, float scale)
//{
//	vec3 cubePos = vec3(0.0, 0.0, 0.0);
//	vec3 d = abs(coord - cubePos) - scale;
//	return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
//}
//
//float CubeFieldDF(vec3 coord, float cubeSize)
//{
//	coord = QtnRotate(coord, vec4(normalize(vec3(1.0, 1.0, 1.0)) * sin(iTime), cos(iTime)));
//	vec3 repAxes = vec3(0.5, 0.5, 0.5);
//	float dist = CubeDF(mod(coord, repAxes) - repAxes / 2.0, cubeSize);
//
//	if (dist < EPS)//EPS = error of a float, ie 0.0001
//	{
//		// Cube is regular, with X = n, Y = n, and Z = n
//		// Centroid will be at the endpoint of a half-size cube,
//		// so vec3(n / 2, n / 2, n / 2) for a cube sitting at the
//		// global origin
//
//		// Our cubes aren't sitting at the origin and exist in
//		// ray-relative coordinates, which means we need to account
//		// for that when we calculate the centroid
//
//		// Generate cube-relative ray position        
//		vec3 localCoord = mod(coord,
//			repAxes);
//
//		// Evaluate difference between the generated local position
//		// and the cube's local centroid
//		vec3 localCentro = vec3(repAxes.x / 2.0,
//			repAxes.x / 2.0,
//			repAxes.x / 2.0);
//
//		vec3 offsets = localCentro - localCoord;
//
//		// Add offsets back into the world-space ray position to locate
//		// the world-space centroid
//		vec3 centro = coord + offsets;
//
//		// Extract one-dimensional integer coordinate from the known centroid
//		vec3 ecaVec = normalize(centro) * 256.0;
//		float oneDTexel = ((ecaVec.x + (ecaVec.y * 256.0)) +
//			(ecaVec.z * (256.0 * 256.0)));
//
//		// Map onto 2D (easier than 3D->2D for me, ymmv)
//		vec2 twoDTexel = vec2(mod(oneDTexel, 256.0), oneDTexel / 256.0);
//
//		// Convert to useful uvs
//		vec2 ecaUV = twoDTexel / vec2(256.0, 256.0);
//
//		// Extract ECA texel
//		float eca = texture(iChannel0, ecaUV).x;
//
//		// Return valid distance if the ECA texel is nonzero; return absolute doubled offsets 
//		// otherwise (will force rays to step through the cube) 
//		if (eca > 0.0)
//		{
//			return dist;
//		}
//
//		else
//		{
//			// Evaluating the distance to the next cube in the current ray direction is
//			// /hard/ and requires rasterizing the current cube, so force the ray-marcher to continue
//			// by returning a value slightly above the draw threshold instead
//			return EPS * 10.0;
//		}
//	}
//
//	return dist;
//}
//
//float DistField(vec3 coord, float sphRad, float cubeSize)
//{
//	return max(SphereDF(coord, sphRad),
//		CubeFieldDF(coord, cubeSize));
//}
//
//vec3 GetNormal(vec3 samplePoint, float eps,	float r, float cubeSize)
//{
//	float normXA = DistField(vec3(samplePoint.x + eps, samplePoint.y, samplePoint.z), r, cubeSize);
//	float normXB = DistField(vec3(samplePoint.x - eps, samplePoint.y, samplePoint.z), r, cubeSize);
//	float normYA = DistField(vec3(samplePoint.x, samplePoint.y + eps, samplePoint.z), r, cubeSize);
//	float normYB = DistField(vec3(samplePoint.x, samplePoint.y - eps, samplePoint.z), r, cubeSize);
//	float normZA = DistField(vec3(samplePoint.x, samplePoint.y, samplePoint.z + eps), r, cubeSize);
//	float normZB = DistField(vec3(samplePoint.x, samplePoint.y, samplePoint.z - eps), r, cubeSize);
//	return normalize(vec3(normXA - normXB,
//		normYA - normYB,
//		normZA - normZB));
//}
//
//vec3 RayDir(float fovRads, vec2 viewSizes, vec2 pixID)
//{
//	vec2 xy = pixID - (viewSizes / 2.0);
//	float z = viewSizes.y / tan(fovRads / 2.0);
//	return normalize(vec3(xy, z));
//}
//
//
//float rule110(float x, float y, float z){
//	float p = y;
//	if (x <= 0.5)	{
//		if (y <= 0.5)
//		{
//			if (z <= 0.5) //000
//			{
//				p = 0;
//				return p;
//			}
//			if (z > 0.5) //001
//			{
//				p = 1;
//				return p;
//			}
//		}
//		if (y > 0.5)
//		{
//			if (z <= 0.5) //010
//			{
//				p = 1;
//				return p;
//			}
//			if (z > 0.5) //011
//			{
//				p = 1;
//				return p;
//			}
//		}
//	}
//	if (x > 0.5)
//	{
//		if (y <= 0.5)
//		{
//			if (z <= 0.5) //100
//			{
//				p = 0;
//				return p;
//			}
//			if (z > 0.5) //101
//			{
//				p = 1;
//				return p;
//			}
//		}
//		if (y > 0.5)
//		{
//			if (z <= 0.5) //110
//			{
//				p = 1;
//				return p;
//			}
//			if (z > 0.5) //111
//			{
//				p = 0;
//				return p;
//			}
//		}
//	}
//}
//
//
//void mainImage(out vec4 fragColor, vec2 fragCoord) {
//
//		// Set the camera
//		vec3 direction = normalize(vec3(fragCoord, 1.0));
//		vec3 origin = vec3(
//			1225+pow((iTime * 0.7),1), 
//			1225+pow((iTime * 0.8),1), 
//			1225+pow((iTime * 0.7),1)
//		);
//		vec3 forward = -origin;
//		vec3 up = vec3(sin(iTime * 0.3), 2.0, 0.0);
//		mat3 rotation;
//		rotation[2] = normalize(forward);
//		rotation[0] = vec3(1, 0, 0);//normalize(cross(up, forward));
//		rotation[1] = vec3(0, 1, 0);//cross(rotation[2], rotation[0]);
//		direction = rotation * direction;
//
//
//		////Voronoi leaves shader
//		//vec3 baseColor = vec3(0.15, 0.5, 0.05);
//		//vec3 tempCol = Voronoi(origin*direction * 5) * 0.5 + baseColor;
//
//		vec3 tempCol = fbmd_8(origin*direction*5).xzy *vec3(1,1,1)  + 0.7;
//		tempCol *= vec3(0.2,0.7,1.0);
//
//	fragColor = vec4(vec3(
//////////////////////////////////TEST AREA///////////////////////////////////////////
//
//tempCol
//
//
//	/*noise(
//		vec2(
//			iTime,
//			Voronoi(fragCoord.x * 10 , 10, fragCoord.y * 10)
//		)
//	)
//
//	**/
//
//
//	
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////
//),1);}/////////////////////////////////////////////////////////////////////////////////////////////////









////RAYTRACED BILLBOARDING SHADER
//#define MAX_DISTANCE 1e5
//#define PI 3.14
//
////returns distance to triangle or MAX_DISTANCE if triangle wasn't hit and outputs uv
//float rayTriangle(vec3 rayPos, vec3 rayDir, vec3 p1, vec3 p2, vec3 p3, out vec2 uv) {
//	const float EPSILON = 1e-5;
//	vec3 edge1 = p2 - p1,
//		edge2 = p3 - p1,
//		pdir = cross(rayDir, edge2);
//	float a = dot(edge1, pdir);
//	if (a > -EPSILON && a < EPSILON) return MAX_DISTANCE;
//
//	float f = 1. / a;
//	vec3 s = rayPos - p1;
//	float u = f * dot(s, pdir);
//	if (u < 0. || u > 1.) return MAX_DISTANCE;
//
//	s = cross(s, edge1);
//	float v = f * dot(rayDir, s);
//	if (v < 0. || u + v > 1.) return MAX_DISTANCE;
//
//	float dst = f * dot(edge2, s);
//	if (dst < EPSILON) dst = MAX_DISTANCE;
//
//	uv = vec2(u, v);
//	return dst;
//}
//
////returns distance to plane or MAX_DISTANCE if plane wasn't hit and outputs uv
//float rayPlane(vec3 rayPos, vec3 rayDir, vec3 planePos, vec3 planeDir, vec3 planeRight, vec3 planeUp, vec2 planeSize, out vec2 uv) {
//	float dst = dot(planePos - rayPos, planeDir) / dot(rayDir, planeDir);
//
//	if (dst < 0.) {
//		dst = MAX_DISTANCE;
//	}
//	else {
//		vec3 hp = (rayPos + rayDir * dst) - planePos;
//		uv = vec2(dot(hp, planeRight), dot(hp, planeUp)) / planeSize * 0.5 + 0.5;
//		if (uv.x < 0. || uv.x > 1. || uv.y < 0. || uv.y > 1.) dst = MAX_DISTANCE;
//	}
//
//	return dst;
//}
//
////return distance to billboard or MAX_DISTANCE if billboard wasn't hit and outputs uv
//float rayBillboard(vec3 rayPos, vec3 rayDir, vec3 billboardPos, vec2 billboardSize, out vec2 uv) {
//	vec3 dvec = billboardPos - rayPos;
//	float dst = dot(dvec, rayDir);
//
//	if (dst < 0.) {
//		dst = MAX_DISTANCE;
//	}
//	else {
//		//uv through reprojection
//		vec2 screenUv = (rayPos + rayDir * dst).xy,
//			screenPos = billboardPos.xy;
//
//		uv = screenUv;
//		uv = (screenUv - screenPos) / (billboardSize / length(dvec))*.5 + .5;
//		if (uv.x < 0. || uv.x > 1. || uv.y < 0. || uv.y > 1.) dst = MAX_DISTANCE;
//	}
//
//	return dst;
//}
//
//
//void mainImage(out vec4 o, in vec2 u)
//{
//	vec3 rp = vec3(0., 0., -30.),
//		rd = vec3(u,1.0);//normalize(vec3((u*2. - iResolution.xy) / iResolution.x, 1.));
//
//	vec2 planeUv, billboardUv;
//	vec3 planeDir = vec3(sin(iTime), 0., cos(iTime));
//	float dst = rayPlane(rp, rd, vec3(0.),
//		planeDir,
//		vec3(sin(iTime + PI * .5), 0., cos(iTime + PI * .5)),
//		vec3(0., 1., 0.),
//		vec2(1., 8.), planeUv);
//
//	float bdst = rayBillboard(rp, rd, planeDir*15., vec2(20., 10.), billboardUv);
//	if (bdst < dst) {
//		planeUv = billboardUv;
//		dst = bdst;
//	}
//
//
//	if (dst < MAX_DISTANCE) {
//		o = vec4(planeUv, 0., 1.);
//	}
//	else {
//		o = vec4(0.);
//	}
//}//////////////////////////////////////////////////////////////////////////////































////BILLBOARD ENGINE
//vec4 shape(vec2 uv, vec3 objDiff, vec3 objCol, vec3 bCol) {
//
//	if (objDiff.z > 0.0)
//		if ((uv.x >= (objDiff.x - (iResolution.x / 2.0) * (1.0 / (objDiff.z*objDiff.z))))
//			&&
//			(uv.x <= (objDiff.x + (iResolution.x / 2.0) * (1.0 / (objDiff.z*objDiff.z))))
//			&&
//			(uv.y >= (objDiff.y - (iResolution.y / 2.0) * (1.0 / (objDiff.z*objDiff.z))))
//			&&
//			(uv.y <= (objDiff.y + (iResolution.y / 2.0) * (1.0 / (objDiff.z*objDiff.z))))
//
//
//			) {
//			return vec4(objCol, 1.0);
//		}
//	return vec4(bCol, 1.0);
//}
//void mainImage(out vec4 fragColor, in vec2 fragCoord)
//{
//	vec3 objPos = vec3(0.5,0.5,120.0);//vec3(0.5, 0.5, iTime*60.0 + 24.0);
//	vec3 objDiff = vec3(0);
//	vec2 cameraAngle = vec2(iMouse.xy);// -vec2(0.5, 0.5);
//	vec3 camPos = vec3(cameraAngle, -1);
//	objDiff = objPos - camPos;
//	vec3 objCol = vec3(0);//object color
//	vec3 bCol = vec3(1.0, 1.0, 1.0);//background color
//	fragColor = shape(fragCoord, objDiff, objCol, bCol);
//}///////////////////////////////////////////////////////////////////////////////











void main() {mainImage(fragColor, fragCoord);}