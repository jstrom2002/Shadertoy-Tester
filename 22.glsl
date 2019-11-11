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



//// [2TC 15] Mystery Mountains.
// David Hoskins.

// Add texture layers of differing frequencies and magnitudes...
#define F +texture(iChannel0,.3+p.xz*s/3e3)/(s+=s) 

void mainImage(out vec4 c, vec2 w)
{
	vec4 p = vec4(w, 1, 1) - .5, d = p, t;
	p.z += iTime * 20.;d.y -= .4;

	for (float i = 1.5;i > 0.;i -= .002)
	{
		float s = .5;
		t = F F F F F F;
		c = 1. + d.x - t * i; c.z -= .1;
		if (t.x > p.y*.007 + 1.3)break;
		p += d;
	}
}







void main() { mainImage(fragColor, fragCoord); }