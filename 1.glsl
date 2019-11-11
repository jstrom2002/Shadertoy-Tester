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





void mainImage(out vec4 fragColor, vec2 fragCoord) {

	//vec2 coord = (-1.0 + 2.0*fragCoord.xy / iResolution.xy) * vec2(iResolution.x / iResolution.y, 1.0)//convert Shadertoy coords to NDC

	vec2 coord = fragCoord;
	//vec2 coord = (-iResolution.xy + 2.0*(fragCoord+1.0)) / iResolution.y;//convert NDC to Shadertoy coords

	// Set the camera
	float speed = 1.9;
	vec3 direction = normalize(vec3(coord, 1.0));
	vec3 origin = vec3(1225.0 + iTime * speed, 1225.0 + iTime * speed, 1225.0 + iTime * speed);
	vec3 forward = -origin;
	vec3 up = vec3(sin(iTime * 0.3), 2.0, 0.0);
	mat3 rotation;
	rotation[2] = normalize(forward);
	rotation[0] = vec3(1, 0, 0);
	rotation[1] = vec3(0, 1, 0);
	direction = rotation * direction;

	float zoom = 3.0;
	vec3 tempCol;
	vec3 temp = noised(origin.xy*direction.xy * zoom);
	if (dot(temp, temp) > 2.4) { tempCol += temp; }
	tempCol *= fbmd_8(origin*direction * zoom).xzy;
	tempCol += 0.4;
	tempCol *= vec3(0.1, 0.7, 1.0);
	fragColor = vec4(tempCol, 1);
}/////////////////////////////////////////////////////////////////////////////////////////////////





void main() { mainImage(fragColor, fragCoord); }