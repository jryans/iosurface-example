/*
    File: ServerOpenGLView.m
Abstract: 
This class implements the server specific subclass of NSOpenGLView. 
It handles the server side rendering, which calls into the GLUT-based
Atlantis rendering code to draw into an IOSurface using an FBO.  It
also performs local rendering of each frame for display purposes.

It also shows how to bind IOSurface objects to OpenGL textures, and
how to use those for rendering with FBOs.

 Version: 1.2

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Inc. ("Apple") in consideration of your agreement to the following
terms, and your use, installation, modification or redistribution of
this Apple software constitutes acceptance of these terms.  If you do
not agree with these terms, please do not use, install, modify or
redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software.
Neither the name, trademarks, service marks or logos of Apple Inc. may
be used to endorse or promote products derived from the Apple Software
without specific prior written permission from Apple.  Except as
expressly stated in this notice, no other rights or licenses, express or
implied, are granted by Apple herein, including but not limited to any
patent rights that may be infringed by your derivative works or by other
works in which the Apple Software may be incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

Copyright (C) 2014 Apple Inc. All Rights Reserved.

*/

#import "ServerOpenGLView.h"
#import "ServerController.h"
#import "BoingRenderer.h"

#import <OpenGL/OpenGL.h>
#import <OpenGL/gl3.h>
#import <OpenGL/CGLIOSurface.h>
#import <GLKit/GLKit.h>

programInfo_t program[NUM_PROGRAMS] = {
    { "lighting.vsh",   "color.fsh"         },	// PROGRAM_LIGHTING
    { "color.vsh",      "color.fsh"         },  // PROGRAM_PASSTHRU
    { "texture.vsh",    "textureRect.fsh"   },  // PROGRAM_TEXTURE_RECT
};


@interface ServerOpenGLView()
{
    GLuint quadVAOId, quadVBOId;
    BOOL quadInit;
    GLuint depthBufferName;
    BoingRenderer *renderer;
}
@end

@implementation ServerOpenGLView

- (instancetype)initWithFrame:(NSRect)frame
{
	NSOpenGLPixelFormat *pix_fmt;
	
	NSOpenGLPixelFormatAttribute attribs[] =
	{
		NSOpenGLPFAAllowOfflineRenderers,
		NSOpenGLPFAAccelerated,
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFAColorSize, 32,
		NSOpenGLPFADepthSize, 24,
        NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core, // Core Profile is the future
		0
	};
	
	pix_fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes:attribs];
	if(!pix_fmt)
	{
		NSLog(@"couldn't create pixel format\n");
		[NSApp terminate:nil];
	}
	
	self = [super initWithFrame:frame pixelFormat:pix_fmt];
	[pix_fmt release];
	
	[[self openGLContext] makeCurrentContext];
		
	return self;
}

- (void)prepareOpenGL
{
    [super prepareOpenGL];
    
    glGenVertexArrays(1, &quadVAOId);
    glGenBuffers(1, &quadVBOId);
    glBindVertexArray(quadVAOId);
    
    [self setupShaders];
    
    // Create a BoingRenderer object which handles the rendering of a Boing ball.
    renderer = [[BoingRenderer alloc] init];
    [renderer initShaders:program];
    
    glBindVertexArray(0);
}

- (void)update
{
	// Override to do nothing.
}

- (NSArray *)rendererNames
{
	NSMutableArray *rendererNames;
	GLint i, numScreens;
	
	rendererNames = [[NSMutableArray alloc] init];
	
	numScreens = [[self pixelFormat] numberOfVirtualScreens];
	for(i = 0; i < numScreens; i++)
	{
		[[self openGLContext] setCurrentVirtualScreen:i];
		[rendererNames addObject:@((const char *)glGetString(GL_RENDERER))];
	}
	
	return [rendererNames autorelease];
}

- (void)setRendererIndex:(uint32_t)index
{
	[[self openGLContext] setCurrentVirtualScreen:index];
}

// Create an IOSurface backed texture
// Create an FBO using the name of this texture and bind the texture to the color attachment of the FBO
- (GLuint)setupIOSurfaceTexture:(IOSurfaceRef)ioSurfaceBuffer fboName:(GLuint *)fboName
{
	GLuint name, namef;
	CGLContextObj cgl_ctx = (CGLContextObj)[[self openGLContext] CGLContextObj];
	
	glGenTextures(1, &name);
	
	glBindTexture(GL_TEXTURE_RECTANGLE, name);
    // At the moment, CGLTexImageIOSurface2D requires the GL_TEXTURE_RECTANGLE target
	CGLTexImageIOSurface2D(cgl_ctx, GL_TEXTURE_RECTANGLE, GL_RGBA, 512, 512, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV,
					ioSurfaceBuffer, 0);
	glTexParameteri(GL_TEXTURE_RECTANGLE, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_RECTANGLE, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_RECTANGLE, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_RECTANGLE, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);	
	
	// Generate an FBO and bind the texture to it as a render target.

	glBindTexture(GL_TEXTURE_RECTANGLE, 0);
	
    glGenFramebuffers(1, &namef);
	glBindFramebuffer(GL_FRAMEBUFFER, namef);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_RECTANGLE, name, 0);

	if(!depthBufferName)
	{
	    glGenRenderbuffers(1, &depthBufferName);
	    glRenderbufferStorage(GL_TEXTURE_RECTANGLE, GL_DEPTH, 512, 512);
	}
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_RECTANGLE, depthBufferName);
	    
	glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    *fboName = namef;
    
	return name;
}

// Render to the current IOSurface via the corresponding FBO previously setuped in -setupIOSurfaceTexture:fboName
- (void)renderToCurrentIOSurface
{
	glBindFramebuffer(GL_FRAMEBUFFER, [(ServerController *)[NSApp delegate] currentFBOName]);
 
    glClearColor(0.675f, 0.675f, 0.675f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
    
    glViewport(0,0,512,512);
    
    // Delegate to the BoingRenderer object to setup an appropriate projection matrix
    [renderer makeOrthographicForWidth:512 height:512];
    
    // Let the BoingRenderer object update the physics stuff
    [renderer update];
    
    // Delegate to the BoingRenderer object for drawing the boling ball
    [renderer render:program];
	
	// Bind back to system drawable.
	glBindFramebuffer(GL_FRAMEBUFFER, 0);

	glFlush();	
}

// Fill the view with the IOSurface backed texture 
- (void)renderTextureFromCurrentIOSurface
{
	NSRect bounds = [self bounds];
    GLfloat width = self.bounds.size.width;
    GLfloat height = self.bounds.size.height;
    
    GLfloat quad[] = {
        //x, y           s, t
        0.0f, 0.0f,      0.0f, 0.0f,
        width, 0.0f,     512.0f, 0.0f,
        0.0f, height,    0.0f, 512.0f,
        width, height,   512.0f, 512.0f,
    };
    
    if (!quadInit) {
        glBindVertexArray(quadVAOId);
        glBindBuffer(GL_ARRAY_BUFFER, quadVBOId);
        glBufferData(GL_ARRAY_BUFFER, sizeof(quad), quad, GL_STATIC_DRAW);
        // positions
        glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, GL_FALSE, 4*sizeof(GLfloat), NULL);
        // texture coordinates
        glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, GL_FALSE, 4*sizeof(GLfloat), (const GLvoid*)(2*sizeof(GLfloat)));
        
        quadInit = YES;
    }
	
	glViewport(0, 0, (GLint)bounds.size.width, (GLint)bounds.size.height);
    
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
	glClear(GL_COLOR_BUFFER_BIT);
    
    glUseProgram(program[PROGRAM_TEXTURE_RECT].id);
    
    GLKMatrix4 projection = GLKMatrix4MakeOrtho(0.0, (GLfloat)bounds.size.width, 0.0f, (GLfloat)bounds.size.height, -1.0f, 1.0f);
    GLKMatrix4 modelView = GLKMatrix4Identity;
    GLKMatrix4 mvp = GLKMatrix4Multiply(projection, modelView);
    glUniformMatrix4fv(program[PROGRAM_TEXTURE_RECT].uniform[UNIFORM_MVP], 1, GL_FALSE, mvp.m);
    
    glUniform1i(program[PROGRAM_TEXTURE_RECT].uniform[UNIFORM_TEXTURE], 0);
	
    // Render quad from our iosurface texture
	glBindTexture(GL_TEXTURE_RECTANGLE, [(ServerController *)[NSApp delegate] currentTextureName]);
    glEnable(GL_TEXTURE_RECTANGLE);
    
    glBindVertexArray(quadVAOId);
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glEnableVertexAttribArray(ATTRIB_TEXCOORD);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    glDisableVertexAttribArray(ATTRIB_VERTEX);
    glDisableVertexAttribArray(ATTRIB_TEXCOORD);
    glDisable(GL_TEXTURE_RECTANGLE);
}

- (BOOL)isOpaque
{
	return YES;
}

- (void)drawRect:(NSRect)theRect
{
	// Only the Master app renders to the IOSurface
	[self renderToCurrentIOSurface];
    
    // Render a view size quad with the IOSurface backed texture
	glDisable(GL_DEPTH_TEST);
	[self renderTextureFromCurrentIOSurface];
	
	[[self openGLContext] flushBuffer];
	
	// This flush is necessary to ensure proper behavior if the MT engine is enabled.
	glFlush();
}

- (void)setupShaders
{
	for (int i = 0; i < NUM_PROGRAMS; i++)
	{
		char *vsrc = readFile(pathForResource(program[i].vert));
		char *fsrc = readFile(pathForResource(program[i].frag));
		GLsizei attribCt = 0;
		GLchar *attribUsed[NUM_ATTRIBS];
		GLint attrib[NUM_ATTRIBS];
		GLchar *attribName[NUM_ATTRIBS] = {
			"inVertex", "inColor", "inNormal", "inTexCoord",
		};
		const GLchar *uniformName[NUM_UNIFORMS] = {
			"MVP", "ModelView", "ModelViewIT", "lightDir", "ambient", "diffuse", "specular", "shininess", "constantColor", "tex",
		};
		
		// auto-assign known attribs
		for (int j = 0; j < NUM_ATTRIBS; j++)
		{
			if (strstr(vsrc, attribName[j]))
			{
				attrib[attribCt] = j;
				attribUsed[attribCt++] = attribName[j];
			}
		}
		
		glueCreateProgram(vsrc, fsrc,
                          attribCt, (const GLchar **)&attribUsed[0], attrib,
                          NUM_UNIFORMS, &uniformName[0], program[i].uniform,
                          &program[i].id);
		free(vsrc);
		free(fsrc);
	}
}

@end
