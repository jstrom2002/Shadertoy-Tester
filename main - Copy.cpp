# pragma comment(lib, "glfw3.lib")

#include <iostream>
#include <vector>
#include <string>
#include <chrono>//for date/month/year
#include <ctime>

#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <stb_image.h>

#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>

#include <learnopengl/filesystem.h>
#include <learnopengl/shader.h>
#include <learnopengl/camera.h>
#include <learnopengl/model.h>

void framebuffer_size_callback(GLFWwindow* window, int width, int height);
void mouse_callback(GLFWwindow* window, double xpos, double ypos);
//void mouse_button_callback(GLFWwindow* window, double xpos, double ypos);
void mouse_button_callback(GLFWwindow* window, int button, int action, int mods);
void scroll_callback(GLFWwindow* window, double xoffset, double yoffset);
void processInput(GLFWwindow *window);
unsigned int loadTexture(const char *path);
void setupFBOs();
void renderQuad();
void loadSkyboxTexture(std::string);
void SceneDraw(GLFWwindow* window);
glm::vec4 getDateVec();

// settings
const unsigned int SCR_WIDTH = 1768;
const unsigned int SCR_HEIGHT = 992;

// camera
Camera camera(glm::vec3(0.0f, 0.0f, 3.0f));
float lastX = (float)SCR_WIDTH / 2.0;
float lastY = (float)SCR_HEIGHT / 2.0;
bool firstMouse = true;
float walkVal = 10.4;

// timing
float deltaTime = 0.0f;
float lastFrame = 0.0f;
float renderSeconds = 0;//for framerate
int renderCycles = 0;

//Shaders
Shader* experimentalFinal;
Shader* experimentalShader;

//mouse
bool mousePressed[3];
glm::vec4 mouseVec;

//VAOs
unsigned int skyboxTexture;
unsigned int cubeVAO, cubeVBO;
unsigned int planeVAO, planeVBO;
unsigned int cubeTexture;
unsigned int floorTexture;

//FBOs
unsigned int experimentalFBO;
unsigned int experimentalRBO;
unsigned int particleRBO;
unsigned int particleFBO;
unsigned int particleTex;
unsigned int mainFBO;
unsigned int mainRBO;
unsigned int mainTex;
unsigned int pingpongFBO[2];
unsigned int pingpongColorbuffers[2];
unsigned int quadVAO;

//textures
unsigned int iChannel0;	
unsigned int iChannel1;		
unsigned int iChannel2;		
unsigned int iChannel3;

int main(){
	// glfw: initialize and configure
	// ------------------------------
	glfwInit();
	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
	glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

	// glfw window creation
	// --------------------
	GLFWwindow* window = glfwCreateWindow(SCR_WIDTH, SCR_HEIGHT, "LearnOpenGL", NULL, NULL);
	glfwMakeContextCurrent(window);
	if (window == NULL)
	{
		std::cout << "Failed to create GLFW window" << std::endl;
		glfwTerminate();
		return -1;
	}
	glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);
	glfwSetCursorPosCallback(window, mouse_callback);
	glfwSetScrollCallback(window, scroll_callback);
	glfwSetMouseButtonCallback(window, mouse_button_callback);

	// tell GLFW to capture our mouse
	glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);

	// glad: load all OpenGL function pointers
	// ---------------------------------------
	if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress))
	{
		std::cout << "Failed to initialize GLAD" << std::endl;
		return -1;
	}


	//load shaders
	glm::mat4 projection = glm::perspective(camera.Zoom, (float)SCR_WIDTH / (float)SCR_HEIGHT, 0.1f, 1000.0f);

	experimentalShader = new Shader("experimentalvs.glsl", "experimentalfs.glsl");
	
	experimentalFinal = new Shader(

		//VERTEX SHADER:
		"experimentalvs.glsl", 
		
		//FRAGMENT SHADER:		
		//"1.glsl"				//my test shader
		//"2.glsl"				//minimalistic ray tracer
		//"3.glsl"				//'Elevated' by Inigo Quilez -- not working
		//"4.glsl"				//'Rainforest' by Inigo Quilez -- not working
		//"5.glsl"				//clouds shader
		//"6.glsl"				//smoke shader
		//"7.glsl"				//'Seascape' by Alexander Alexseev
		//"8.glsl"				//'Shoreline' by S.Guillitte 
		//"9.glsl"				//ray-traced geometric reflections
		//"10.glsl"				//infinite roadway
		//"11.glsl"				//ray-marched reflections
		//"12.glsl"				//raindrop shader -- not working
		//"13.glsl"				// by Morgan McGuire
		//"14.glsl"				//FLUID SIM SHADER by Clement Roche
		//"15.glsl"				//Horizon Zero Dawn cloud shader
		//"16.glsl"				//'Light at the End of the Tunnel' -- not working
		//"17.glsl"				//Caverneous fly-through
		//"18.glsl"				//Topologica VR
		//"19.glsl"				//Mandel-monster
		//"20.glsl"				//Bone mandel
		//"21.glsl"				//Skyline
		//"22.glsl"				//Mystery mountains by David Hoskins -- has issues
		//"23.glsl"				//Clouds by Inigo Quilez -- requires a special noise texture that I cannot find
		//"24.glsl"				//Oceanic by Frank Hugenrot
		//"25.glsl"				//Star Nest by Pablo Roman Andiolli
		//"26.glsl"				//Protean Clouds
		//"27.glsl"				//Single Scattering
		//"28.glsl"				//Cheap Cloud Flythrough
		//"29.glsl"				//Horizon Clouds
		//"30.glsl"				//PBR Volumetric Clouds
		//"31.glsl"				//Fires
		//"32.glsl"				//301's Fire Shader - Remix 3
		//"33.glsl"				//Brady's Volumetric Fire
		//"34.glsl"				//Wind of Change by Roman Bobinev
		//"35.glsl"				//GLSL smallpt
		//"36.glsl"				//Planet Shadertoy by Neinder Nijhoff
		//"37.glsl"				//Tokyo by Neinder Nijhoff
		//"38.glsl"				//Greek Temple by Inigo Quilez -- not working
		//"39.glsl"				//Mountains by David Hoskins
		//"40.glsl"				//Sirenian Dawn by nimitz -- not working
	);
	experimentalFinal->use();
	experimentalFinal->setInt("iChannel0", 0);
	experimentalFinal->setInt("iChannel1", 1);
	experimentalFinal->setInt("iChannel2", 2);
	experimentalFinal->setInt("iChannel3", 3);

	// configure global opengl state
	// -----------------------------
	glEnable(GL_DEPTH_TEST);
	glDepthFunc(GL_LESS);

	glEnable(GL_BLEND);
	glDepthMask(GL_TRUE);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glAlphaFunc(GL_GREATER, 0.1);
	glEnable(GL_ALPHA_TEST);

	SceneDraw(window);//experimental -- non-functional

	glfwTerminate();
	return 0;
}////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////






void SaveFramebufferToFile(int buff) {
	glPixelStorei(GL_PACK_ALIGNMENT, 1);
	glBindFramebuffer(GL_FRAMEBUFFER, buff);
	glReadBuffer(GL_COLOR_ATTACHMENT0);
	char cFileName[64];
	FILE *fScreenshot = NULL;
	int nSize = SCR_WIDTH * SCR_HEIGHT * 3;

	// read framebuffer data 
	GLubyte* pixels = new GLubyte[nSize];
	if (pixels == NULL) return;
	glReadPixels(0, 0, SCR_WIDTH, SCR_HEIGHT, GL_RGB, GL_UNSIGNED_BYTE, pixels);

	// Save to TGA file
	// ----------------
		//check and get next file name in sequence
		int nShot = 0;
		while (nShot < 500) {
			sprintf(cFileName, "screenshots/screenshot_%d.tga", nShot);
			fScreenshot = fopen(cFileName, "rb");
			if (fScreenshot == NULL) break;
			else fclose(fScreenshot);
			++nShot;
			if (nShot > 499) {
				std::cout << "Screenshot limit of 500 reached.\n";
				return;
			}
		}

		fScreenshot = fopen(cFileName, "wb");

		//convert to BGR format    
		unsigned char temp;
		int i = 0;
		while (i < nSize) {
			temp = pixels[i];           //grab blue
			pixels[i] = pixels[i + 2];//assign red to blue
			pixels[i + 2] = temp;     //assign blue to red
			i += 3;     //skip to next blue byte
		}

		unsigned char TGAheader[12] = { 0,0,2,0,0,0,0,0,0,0,0,0 };
		unsigned char header[6] = { SCR_WIDTH % 256, SCR_WIDTH / 256, SCR_HEIGHT % 256,SCR_HEIGHT / 256,24,0 };
		fwrite(TGAheader, sizeof(unsigned char), 12, fScreenshot);
		fwrite(header, sizeof(unsigned char), 6, fScreenshot);
		fwrite(pixels, sizeof(GLubyte), nSize, fScreenshot);
		fclose(fScreenshot);
	delete[] pixels;
	return;
}




// process all input: query GLFW whether relevant keys are pressed/released this frame and react accordingly
// ---------------------------------------------------------------------------------------------------------
void processInput(GLFWwindow *window)
{
	if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS)
		glfwSetWindowShouldClose(window, true);

	float cameraSpeed = walkVal * deltaTime;
	if (glfwGetKey(window, GLFW_KEY_W) == GLFW_PRESS)
		camera.ProcessKeyboard(FORWARD, cameraSpeed);
	if (glfwGetKey(window, GLFW_KEY_S) == GLFW_PRESS)
		camera.ProcessKeyboard(BACKWARD, cameraSpeed);
	if (glfwGetKey(window, GLFW_KEY_A) == GLFW_PRESS)
		camera.ProcessKeyboard(LEFT, cameraSpeed);
	if (glfwGetKey(window, GLFW_KEY_D) == GLFW_PRESS)
		camera.ProcessKeyboard(RIGHT, cameraSpeed);

	if (glfwGetKey(window, GLFW_KEY_END) == GLFW_PRESS){
		SaveFramebufferToFile(0);
	}
	if (glfwGetKey(window, GLFW_KEY_HOME) == GLFW_PRESS) {
		camera.Position = glm::vec3(0,0,0);
	}
}

// glfw: whenever the window size changed (by OS or user resize) this callback function executes
// ---------------------------------------------------------------------------------------------
void framebuffer_size_callback(GLFWwindow* window, int width, int height)
{
	// make sure the viewport matches the new window dimensions; note that width and 
	// height will be significantly larger than specified on retina displays.
	glViewport(0, 0, width, height);
}


// glfw: whenever the mouse moves, this callback is called
// -------------------------------------------------------
void mouse_callback(GLFWwindow* window, double xpos, double ypos){
	
	//update in NDC coords
	mouseVec[0] = ((xpos/SCR_WIDTH)-0.5)*2.0;
	mouseVec[1] = ((ypos/SCR_HEIGHT)-0.5)*2.0;
	
	if (firstMouse)
	{
		lastX = xpos;
		lastY = ypos;
		firstMouse = false;
	}

	float xoffset = xpos - lastX;
	float yoffset = lastY - ypos; // reversed since y-coordinates go from bottom to top

	lastX = xpos;
	lastY = ypos;

	camera.ProcessMouseMovement(xoffset, yoffset);
}



void mouse_button_callback(GLFWwindow* window, int button, int action, int mods){	
	if (button == GLFW_MOUSE_BUTTON_LEFT && action == GLFW_PRESS) {
		mouseVec[2] = 1;
	}

	if (button == GLFW_MOUSE_BUTTON_LEFT && action == GLFW_RELEASE) {
		mouseVec[2] = 0;
	}

	if (button == GLFW_MOUSE_BUTTON_RIGHT && action == GLFW_PRESS) {
		mouseVec[3] = 1;
	}

	if (button == GLFW_MOUSE_BUTTON_RIGHT && action == GLFW_RELEASE) {
		mouseVec[3] = 0;
	}
}

void scroll_callback(GLFWwindow* window, double xoffset, double yoffset){
	//camera.ProcessMouseScroll(yoffset);
}

// utility function for loading a 2D texture from file
// ---------------------------------------------------
unsigned int loadTexture(char const * path)
{
	unsigned int textureID;
	glGenTextures(1, &textureID);

	int width, height, nrComponents;
	unsigned char *data = stbi_load(path, &width, &height, &nrComponents, 0);
	if (data)
	{
		GLenum format;
		if (nrComponents == 1)
			format = GL_RED;
		else if (nrComponents == 3)
			format = GL_RGB;
		else if (nrComponents == 4)
			format = GL_RGBA;

		glBindTexture(GL_TEXTURE_2D, textureID);
		glTexImage2D(GL_TEXTURE_2D, 0, format, width, height, 0, format, GL_UNSIGNED_BYTE, data);
		glGenerateMipmap(GL_TEXTURE_2D);

		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

		stbi_image_free(data);
	}
	else
	{
		std::cout << "Texture failed to load at path: " << path << std::endl;
		stbi_image_free(data);
	}

	return textureID;
}///////////////////////////////////////////


// renderQuad() renders a 1x1 XY quad in NDC
	// -----------------------------------------
void renderQuad() {
	if (quadVAO == 0) {
		float quadVertices[] = { // vertex attributes for a quad that fills the entire screen in Normalized Device Coordinates.
		// positions         // texCoords
		-1.0f,  1.0f,  0.0f,  0.0f, 1.0f,
		-1.0f, -1.0f,  0.0f,  0.0f, 0.0f,
		 1.0f, -1.0f,  0.0f,  1.0f, 0.0f,

		-1.0f,  1.0f,  0.0f,  0.0f, 1.0f,
		 1.0f, -1.0f,  0.0f,  1.0f, 0.0f,
		 1.0f,  1.0f,  0.0f,  1.0f, 1.0f
		};
		// setup plane VAO
		unsigned int quadVBO;
		glGenVertexArrays(1, &quadVAO);
		glGenBuffers(1, &quadVBO);
		glBindVertexArray(quadVAO);
		glBindBuffer(GL_ARRAY_BUFFER, quadVBO);
		glBufferData(GL_ARRAY_BUFFER, sizeof(quadVertices), &quadVertices, GL_STATIC_DRAW);
		glEnableVertexAttribArray(0);
		glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)0);
		glEnableVertexAttribArray(1);
		glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(float), (void*)(3 * sizeof(float)));
	}
	glBindVertexArray(quadVAO);
	glDrawArrays(GL_TRIANGLES, 0, 6);
	glBindVertexArray(0);
}
//////////////////////////////////////




void setupFBOs() {

	glGenFramebuffers(1, &experimentalFBO);
	glBindFramebuffer(GL_FRAMEBUFFER, experimentalFBO);

	glGenTextures(1, &iChannel0);
	glBindTexture(GL_TEXTURE_2D, iChannel0);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB16F, SCR_WIDTH, SCR_HEIGHT, 0, GL_RGB, GL_FLOAT, NULL);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, iChannel0, 0);

	glBindFramebuffer(GL_FRAMEBUFFER, iChannel1);
	glBindTexture(GL_TEXTURE_2D, iChannel1);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB16F, SCR_WIDTH, SCR_HEIGHT, 0, GL_RGB, GL_FLOAT, NULL);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT1, GL_TEXTURE_2D, iChannel1, 0);

	glBindFramebuffer(GL_FRAMEBUFFER, iChannel2);
	glBindTexture(GL_TEXTURE_2D, iChannel2);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB16F, SCR_WIDTH, SCR_HEIGHT, 0, GL_RGB, GL_FLOAT, NULL);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT1, GL_TEXTURE_2D, iChannel2, 0);

	glBindFramebuffer(GL_FRAMEBUFFER, iChannel3);
	glBindTexture(GL_TEXTURE_2D, iChannel3);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB16F, SCR_WIDTH, SCR_HEIGHT, 0, GL_RGB, GL_FLOAT, NULL);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT1, GL_TEXTURE_2D, iChannel3, 0);

	if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
		MessageBox(0, "intermediate framebuffer not complete!", 0, 0);
	glBindFramebuffer(GL_FRAMEBUFFER, 0);


	///////////////////////////////

	   
	glGenFramebuffers(1, &mainFBO);
	glBindFramebuffer(GL_FRAMEBUFFER, mainFBO);
	// create a color attachment textures
	glGenTextures(1, &mainTex);

	glBindTexture(GL_TEXTURE_2D, mainTex);
	//glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, camera.viewport.width, camera.viewport.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
	//glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, camera.viewport.width, camera.viewport.height, 0, GL_RGB, GL_UNSIGNED_BYTE, NULL);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB16F, SCR_WIDTH, SCR_HEIGHT, 0, GL_RGB, GL_FLOAT, NULL);
	//glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA16F, camera.viewport.width, camera.viewport.height, 0, GL_RGBA, GL_FLOAT, NULL);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, mainTex, 0);
	glBindTexture(GL_TEXTURE_2D, 0);

	//add depth buffer in one
	glGenRenderbuffers(1, &mainRBO);
	glBindRenderbuffer(GL_RENDERBUFFER, mainRBO);
	glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT, SCR_WIDTH, SCR_HEIGHT);
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, mainRBO);
	glBindRenderbuffer(GL_RENDERBUFFER, 0);

	if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
		MessageBox(0, "intermediate framebuffer not complete!", 0, 0);
	glBindFramebuffer(GL_FRAMEBUFFER, 0);


	///////////////////////////////
}/////////////////////////////////////////////////////////////////////////////

	void setShaderInputs(float renderSeconds, int renderCycles) {
		experimentalShader->use();
		experimentalShader->setVec3("iResolution", glm::vec3(SCR_WIDTH, SCR_HEIGHT, SCR_WIDTH/SCR_HEIGHT));
		//experimentalShader->setVec3("iResolution", glm::vec3(400, 400, 1));

		//experimentalShader->setVec3("iChannelResolution[0]", glm::vec3(32, 32, 1));
		//experimentalShader->setVec3("iChannelResolution[1]", glm::vec3(256,256, 1));
		//experimentalShader->setVec3("iChannelResolution[2]", glm::vec3(1024, 1024, 1));
		//experimentalShader->setVec3("iChannelResolution[3]", glm::vec3(1024, 1024, 1));
		experimentalShader->setFloat("iTime", renderSeconds);
		experimentalShader->setFloat("iTimeDelta", deltaTime);
		experimentalShader->setInt("iFrame", renderCycles);
		experimentalShader->setFloat("iFrameRate", renderSeconds);
		experimentalShader->setVec4("iMouse", mouseVec);
		experimentalShader->setVec4("iDate", getDateVec());

		experimentalFinal->use();
		experimentalFinal->setVec3("iResolution", glm::vec3(SCR_WIDTH, SCR_HEIGHT, SCR_WIDTH / SCR_HEIGHT));
		experimentalFinal->setVec3("iChannelResolution[0]", glm::vec3(SCR_WIDTH, SCR_HEIGHT, SCR_WIDTH / SCR_HEIGHT));
		//experimentalShader->setVec3("iChannelResolution[0]", glm::vec3(400, 400, 1));
		//experimentalShader->setVec3("iChannelResolution[1]", glm::vec3(400, 400, 1));
		//experimentalShader->setVec3("iChannelResolution[2]", glm::vec3(400, 400, 1));
		//experimentalShader->setVec3("iChannelResolution[3]", glm::vec3(400, 400, 1));
		experimentalFinal->setFloat("iTime", renderSeconds);
		experimentalFinal->setFloat("iTimeDelta", deltaTime);
		experimentalFinal->setInt("iFrame", renderCycles);
		experimentalShader->setFloat("iFrameRate", renderSeconds);
		experimentalFinal->setVec4("iMouse", mouseVec);
		experimentalFinal->setVec4("iDate", getDateVec());
	}////

	void SceneDraw(GLFWwindow* window) {
		setupFBOs();
		clock_t clk = clock();

		unsigned int chan0 = loadTexture(
			//"wood.png"
			//"greynoise.png"
			//"grey noise small.png"
			//"london.jpg"
			"rgba noise medium.png"
			//"stars.jpg"
			//"font1.png"
		);
		unsigned int chan1 = loadTexture(
			"greynoise.png"
		);
		//unsigned int chan2 = loadTexture("wood.png");
		//unsigned int chan3 = loadTexture("wood.png");

		while (!glfwWindowShouldClose(window)) {
			float currentFrame = glfwGetTime();
			deltaTime = currentFrame - lastFrame;
			lastFrame = currentFrame;

			processInput(window);
			setShaderInputs(renderSeconds, renderCycles);

			//// render
			//// ------
			////draw 1st buffer
			//glBindFramebuffer(GL_FRAMEBUFFER, experimentalFBO);
			//glClearColor(0.3f, 0.3f, 0.3f, 1.0f);
			//glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
			////glViewport(0, 0, SCR_WIDTH, SCR_HEIGHT);
			//glViewport(0, 0, 400, 400);
			//experimentalShader->use();
			//glActiveTexture(GL_TEXTURE0);
			//glBindTexture(GL_TEXTURE_2D, chan0);//use past frame
			////glActiveTexture(GL_TEXTURE1);
			////glBindTexture(GL_TEXTURE_2D, chan1);
			////glActiveTexture(GL_TEXTURE2);
			////glBindTexture(GL_TEXTURE_2D, chan2);
			////glActiveTexture(GL_TEXTURE3);
			////glBindTexture(GL_TEXTURE_2D, chan3);
			//renderQuad();

			//=======================================

			//draw final quad
			glBindFramebuffer(GL_FRAMEBUFFER, 0);
			glClearColor(0.1f, 0.1f, 0.1f, 1.0f);
			glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
			glViewport(0, 0, SCR_WIDTH, SCR_HEIGHT);
			experimentalFinal->use();
			glActiveTexture(GL_TEXTURE0);
			glBindTexture(GL_TEXTURE_2D, iChannel0);
			//glActiveTexture(GL_TEXTURE1);
			//glBindTexture(GL_TEXTURE_2D, iChannel1);
			//glActiveTexture(GL_TEXTURE2);
			//glBindTexture(GL_TEXTURE_2D, iChannel2);
			//glActiveTexture(GL_TEXTURE3);
			//glBindTexture(GL_TEXTURE_2D, iChannel3);
			renderQuad();


			//update things
			renderCycles++;
			renderSeconds = std::abs((float)(clock() - clk) / CLOCKS_PER_SEC);

			glfwSwapBuffers(window);
			glfwPollEvents();
		}
	}////////////////////////////////////////////////////////



	glm::vec4 getDateVec() {//return vec4 of year, month, day, time in seconds
   		 
		//get all the time data
		typedef std::chrono::duration<int, ratio_multiply<std::chrono::hours::period, ratio<24> >::type> days;
		std::chrono::system_clock::time_point now = std::chrono::system_clock::now();
		std::chrono::system_clock::duration tp = now.time_since_epoch();
		days d = std::chrono::duration_cast<days>(tp);
		tp -= d;
		std::chrono::hours h = std::chrono::duration_cast<std::chrono::hours>(tp);
		tp -= h;
		std::chrono::minutes m = std::chrono::duration_cast<std::chrono::minutes>(tp);
		tp -= m;
		std::chrono::seconds s = std::chrono::duration_cast<std::chrono::seconds>(tp);
		tp -= s;

		time_t tt = std::chrono::system_clock::to_time_t(now);
		tm utc_tm = *gmtime(&tt);
		tm local_tm = *localtime(&tt);
		
		//UTC time
		//std::cout << utc_tm.tm_year + 1900 << '-';
		//std::cout << utc_tm.tm_mon + 1 << '-';
		//std::cout << utc_tm.tm_mday << ' ';
		//std::cout << utc_tm.tm_hour << ':';
		//std::cout << utc_tm.tm_min << ':';
		//std::cout << utc_tm.tm_sec << '\n';

		//local time
		//std::cout << local_tm.tm_year + 1900 << '-';
		//std::cout << local_tm.tm_mon + 1 << '-';
		//std::cout << local_tm.tm_mday << ' ';
		//std::cout << local_tm.tm_hour << ':';
		//std::cout << local_tm.tm_min << ':';
		//std::cout << local_tm.tm_sec << '\n';

		glm::vec4 dateVec;
		dateVec[0] = local_tm.tm_year + 1900;
		dateVec[1] = local_tm.tm_mon;
		dateVec[2] = local_tm.tm_mday;
		dateVec[3] = local_tm.tm_sec;
		return dateVec;
	}//////////////////////////////////////////////////