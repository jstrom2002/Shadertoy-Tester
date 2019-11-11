# Shadertoy-Tester
OpenGL program to quickly load and test Shadertoy's shaders on my machine.
Somewhat hastily slapped together, only uses the default framebuffer.
Please note that the mainImage() method has an input, fragCoord, that this program defines as bounded between [0,1] from the vertex shader
output. Therefore, most Shadertoy shaders do a conversion to this range of values for the uv coordinates, so this must be fixed.
Also note that this progam is very not cross-platform, its set up to work on my Windows pc only so it might require so additional defines.

Requires glfw3.
