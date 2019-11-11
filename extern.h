#ifndef EXTERN_H
#define EXTERN_H
#include <vector>
#include <glm/glm.hpp>

extern class AudioClass;
extern class Camera;
extern class Clock;
//extern class CollisionBox;
extern class Console;
extern class DrawObject;
extern class DialogTree;
extern class GUIelement;
//extern class Light;
//extern class OBJmodel;
extern class Material;
extern class Mouse;
extern class Scene;
extern class ScriptTree;
extern class Shader;
extern class Surface;
extern class Text;
extern class Texture;
extern class TextureDrawer;
extern class Viewport;
extern class Window;
extern class UIDrawer;

extern Window window;
extern Camera camera;
extern Clock _clock;
//extern Scene scene;
//extern DialogTree dialogtree;
//extern DrawObject* drawobject;//use instead drawobject member of Window class
extern Mouse mouse;
extern Text text;
extern TextureDrawer texturedrawer;
//extern UIDrawer uidrawer;
//extern Viewport viewport;

extern bool windowclose;
extern bool captureMouse;
extern bool captureKeyboard;
extern bool firstmouse;
extern bool freelook;
extern bool inVehicle;
extern bool cullFaces;
extern bool FPSmode;
extern unsigned int keyTimer;
extern double lastX, lastY, xoffset, yoffset;
extern bool pressed[549];
extern bool mousePressed[12];
extern bool mouseReleased[12];
extern float walkVal;
extern float runVal;
extern int userSelection;
extern std::string currentScreen;

//debugging info
extern unsigned int originalContext;

//UI rendering settings
extern glm::vec3 tonemap;
extern float playerHealth;
extern float exposure;
extern float brightness;
extern float contrast;
extern float saturation;
extern float hue;
extern float lightness;
extern float gamma;
extern bool cullFrustum;
extern bool hdrOn;
extern bool bloomOn;
extern bool TAAon;
extern float bloomThreshold;
extern int bloomPasses;
extern bool focalBlurOn;
extern int focalBlurPasses;
extern float focalBlurFactor;
extern float focalDepth;
extern float anisotropyVal;
extern bool shadowsOn;
extern bool showLights;
extern bool multisample;//turn on and off multisample anti-aliasing
extern int textureFiltering;
extern unsigned char AAsamples;
extern int numMipmaps;
extern int shadowRes;
extern int envRes;
extern int selectedOBJ;
extern bool needGetSelectedOBJ;
extern int fontNum;
extern bool greyscale;
extern float greyblend;

//testing params for the engine
extern bool renderHitboxes;
extern bool renderDepth;
extern bool renderNormals;
extern bool rendergAlbedo;
extern bool rendergPosition;
extern bool rendergPrevAlbedo;
extern bool rendergNormal;
extern bool rendergVelocity;
extern bool renderNormals;
extern bool renderTAA;

//SSAO
extern bool renderAO;
extern bool SSAOon;
extern float SSAOblend;
extern int SSAOkernelSize;
extern float SSAOradius;
extern float SSAObias;
extern glm::vec2 SSAOnoiseScale;

//security settings
extern std::wstring hostname;    //name of internet provider host
extern std::vector<std::string> IPs;	//IP addresses in all formats(IPv6, IPv4, etc.)
extern std::string productKey;			//the key for the program, used to unlock it when it runs
extern std::string password;	//user-defined password
extern std::string serialnumber;//contains the program's serial number
#endif