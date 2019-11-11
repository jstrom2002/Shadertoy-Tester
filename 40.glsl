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




// Sirenian Dawn by nimitz (twitter: @stormoid)
// https://www.shadertoy.com/view/XsyGWV
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Contact the author for other licensing options

/*
	See: https://en.wikipedia.org/wiki/Terra_Sirenum

	Things of interest in this shader:
		-A technique I call "relaxation marching", see march() function
		-A buffer based technique for anti-alisaing
		-Cheap and smooth procedural starfield
		-Non-constant fog from iq
		-Completely faked atmosphere :)
		-Terrain based on noise derivatives
*/

/*
	More about the antialiasing:
		The fragments with high enough iteration count/distance ratio
		get blended with the past frame, I tried a few different
		input for the blend trigger: distance delta, color delta,
		normal delta, scene curvature.  But none of them provides
		good enough info about the problem areas to allow for proper
		antialiasing without making the whole scene blurry.

		On the other hand iteration count (modulated by a power
		of distance) does a pretty good job without requiring to
		store past frame info in the alpha channel (which can then
		be used for something else, nothing in this case)

*/

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
	fragColor = vec4(
		texture(
			iChannel0, 
			fragCoord, //fragCoord.xy / iResolution.xy).rgb, 
			1.0
		);
}



void main() { mainImage(fragColor, fragCoord); }