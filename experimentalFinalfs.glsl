#version 330 core
out vec4 fragColor;
in vec2 fragCoord;

uniform vec3      iResolution;           // viewport resolution (in pixels)
uniform float     iTime;                 // shader playback time (in seconds)
uniform float     iTimeDelta;            // render time (in seconds)
uniform int       iFrame;                // shader playback frame
uniform float     iChannelTime[4];       // channel playback time (in seconds)
uniform vec3      iChannelResolution[4]; // channel resolution (in pixels)
uniform vec4      iMouse;                // mouse pixel coords. xy: current (if MLB down), zw: click
uniform sampler2D iChannel0;			// input channel. XX = 2D/Cube
uniform sampler2D iChannel1;			// input channel. XX = 2D/Cube
uniform sampler2D iChannel2;			// input channel. XX = 2D/Cube
uniform sampler2D iChannel3;			// input channel. XX = 2D/Cube
uniform vec4      iDate;                 // (year, month, day, time in seconds)
uniform float     iSampleRate=441000;           // sound sample rate (i.e., 44100)


void main() {
	fragColor = texture(iChannel0, fragCoord*vec2(0.1,0.2) + vec2(0.1,0.2));
}


//
//void mainImage(out vec4 fragColor, in vec2 fragCoord)
//{
//	vec2 uv = fragCoord / iResolution.xy;
//	vec4 data = texture(iChannel0, uv);
//
//	vec3 col = vec3(0.0);
//	if (data.w < 0.0)
//	{
//		col = data.xyz;
//	}
//	else
//	{
//		// decompress velocity vector
//		float ss = mod(data.w, 256.0) / 255.0;
//		float st = floor(data.w / 256.0) / 255.0;
//
//		// motion blur (linear blur across velocity vectors
//		vec2 dir = (-1.0 + 2.0*vec2(ss, st))*0.25;
//		col = vec3(0.0);
//		for (int i = 0; i < 32; i++)
//		{
//			float h = float(i) / 31.0;
//			vec2 pos = uv + dir * h;
//			col += texture(iChannel0, pos).xyz;
//		}
//		col /= 32.0;
//	}
//
//	// vignetting	
//	col *= 0.5 + 0.5*pow(16.0*uv.x*uv.y*(1.0 - uv.x)*(1.0 - uv.y), 0.1);
//
//	fragColor = vec4(col, 1.0);
//}


	////Motion blur from mu6k: https://www.shadertoy.com/view/lsyXRK
	//vec2 totex(vec2 p){
	//	p.x = p.x*iResolution.y / iResolution.x + 0.5;
	//	p.y += 0.5;
	//	return p;
	//}

	//vec3 sample_color(vec2 p){
	//	return texture(iChannel2, totex(p)).xyz;
	//}

	//void main() {
		//vec2 uv = fragCoord.xy / iResolution.xy;
		//vec2 p = fragCoord;//(fragCoord.xy - iResolution.xy*.5) / iResolution.yy;

		//if (abs(p.y) > .41) {
		//	fragColor = vec4(0.0, 0.0, 0.0, 1.0);
		//	return;
		//}

		//vec4 fb = texture(iChannel2, uv);

		//float amp = 1. / fb.w*0.1;
		//vec4 noise = texture(iChannel0, (fragCoord + floor(iTime*vec2(12.0, 56.0))) / 64.0);

		//vec3 col = vec3(0.0);
		//col += sample_color(p*((noise.x + 2.0)*amp + 1.0));
		//col += sample_color(p*((noise.y + 1.0)*amp + 1.0));
		//col += sample_color(p*((noise.z + 0.0)*amp + 1.0));
		//col += sample_color(p*((noise.w - 1.0)*amp + 1.0));
		//col += sample_color(p*((noise.x - 2.0)*amp + 1.0));
		//col *= 0.2;
		//col.y *= 1.2;
		//col = pow(clamp(col, 0.0, 1.0), vec3(0.45));
		//col = mix(col, vec3(dot(col, vec3(0.33))), -0.5);

		//fragColor = vec4(col, 1.0);
//}