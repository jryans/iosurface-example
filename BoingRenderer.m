/*
    File: BoingRenderer.m
Abstract: 
This class handles the rendering of a Boing ball using Core Profile.

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

#import "BoingRenderer.h"
#import <GLKit/GLKit.h>

typedef struct
{
	float x;
	float y;
	float z;
	float nx;
	float ny;
	float nz;
	float r;
	float g;
	float b;
	float a;
} Vertex;

static float lightDir[3]    = { 0.8, 4.0, 1.0 };
static float ambient[4]     = { 0.35, 0.35, 0.35, 0.35 };
static float diffuse[4]     = { 1.0-0.35, 1.0-0.35, 1.0-0.35, 1.0 };
static float specular[4]    = { 0.8, 0.8, 0.8, 1.0 };
static float shininess      = 10.0;


@interface BoingRenderer()
{    
    // Cribbed from BoingX
    float angle;
    float angleDelta;
    float r;
    float xPos, yPos;
    float xVelocity, yVelocity;
    float scaleFactor;
    
    GLKVector3 lightDirNormalized;
    GLKMatrix4 projectionMatrix;
    GLuint vboId, vaoId;
}
@end

@implementation BoingRenderer

-(void)generateBoingData
{
	int x;
	int index = 0;
	
	float v1x, v1y, v1z;
	float v2x, v2y, v2z;
	float d;
	
	int theta, phi;
	
	float theta0, theta1;
	float phi0, phi1;
	
	Vertex quad[4];
	
	Vertex *boingData = malloc(8 * 16 * 6 * sizeof(Vertex));
	
	float delta = M_PI / 8.0f;
	
	// 8 vertical segments
	for(theta = 0; theta < 8; theta++)
	{
		theta0 = theta*delta;
		theta1 = (theta+1)*delta;
		
		// 16 horizontal segments
		for(phi = 0; phi < 16; phi++)
		{
			phi0 = phi*delta;
			phi1 = (phi+1)*delta;
			
			// Generate 4 points per quad
			quad[0].x = r * sin(theta0)*cos(phi0);
			quad[0].y = r * cos(theta0);
			quad[0].z = r * sin(theta0)*sin(phi0);
			
			quad[1].x = r * sin(theta0)*cos(phi1);
			quad[1].y = r * cos(theta0);
			quad[1].z = r * sin(theta0)*sin(phi1);
			
			quad[2].x = r * sin(theta1)*cos(phi1);
			quad[2].y = r * cos(theta1);
			quad[2].z = r * sin(theta1)*sin(phi1);
			
			quad[3].x = r * sin(theta1)*cos(phi0);
			quad[3].y = r * cos(theta1);
			quad[3].z = r * sin(theta1)*sin(phi0);
			
			// Generate normal
			if(theta >= 4)
			{
				v1x = quad[1].x - quad[0].x;
				v1y = quad[1].y - quad[0].y;
				v1z = quad[1].z - quad[0].z;
				
				v2x = quad[3].x - quad[0].x;
				v2y = quad[3].y - quad[0].y;
				v2z = quad[3].z - quad[0].z;
			}
			else
			{
				v1x = quad[0].x - quad[3].x;
				v1y = quad[0].y - quad[3].y;
				v1z = quad[0].z - quad[3].z;
				
				v2x = quad[2].x - quad[3].x;
				v2y = quad[2].y - quad[3].y;
				v2z = quad[2].z - quad[3].z;
			}
			
			quad[0].nx = (v1y * v2z) - (v2y * v1z);
			quad[0].ny = (v1z * v2x) - (v2z * v1x);
			quad[0].nz = (v1x * v2y) - (v2x * v1y);
			
			d = 1.0f/sqrt(quad[0].nx*quad[0].nx +
						  quad[0].ny*quad[0].ny +
						  quad[0].nz*quad[0].nz);
			
			quad[0].nx *= d;
			quad[0].ny *= d;
			quad[0].nz *= d;
			
			// Generate color
			if((theta ^ phi) & 1)
			{
				quad[0].r = 1.0f;
				quad[0].g = 1.0f;
				quad[0].b = 1.0f;
				quad[0].a = 1.0f;
			}
			else
			{
				quad[0].r = 1.0f;
				quad[0].g = 0.0f;
				quad[0].b = 0.0f;
				quad[0].a = 1.0f;
			}
			
			// Replicate vertex info
			for(x = 1; x < 4; x++)
			{
				quad[x].nx = quad[0].nx;
				quad[x].ny = quad[0].ny;
				quad[x].nz = quad[0].nz;
				quad[x].r = quad[0].r;
				quad[x].g = quad[0].g;
				quad[x].b = quad[0].b;
				quad[x].a = quad[0].a;
			}
			
            // OpenGL draws triangles under the hood. Core Profile officially drops support
            // of the GL_QUADS mode in the glDrawArrays/Elements calls.
			// Store vertices as in two consisting triangles
			boingData[index++] = quad[0];
			boingData[index++] = quad[1];
			boingData[index++] = quad[2];
            
            boingData[index++] = quad[2];
            boingData[index++] = quad[3];
            boingData[index++] = quad[0];
		}
	}
	
	// Create a VAO (vertex array object).
	glGenVertexArrays(1, &vaoId);
	glBindVertexArray(vaoId);
	
	// Create a VBO (vertex buffer object) to hold our data.
    glGenBuffers(1, &vboId);
	glBindBuffer(GL_ARRAY_BUFFER, vboId);
	glBufferData(GL_ARRAY_BUFFER, 8 * 16 * 6 * sizeof(Vertex), boingData, GL_STATIC_DRAW);
	
    // positions
    glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLubyte *)(uintptr_t)offsetof(Vertex,x));
    // colors
    glVertexAttribPointer(ATTRIB_COLOR, 4, GL_FLOAT, GL_TRUE, sizeof(Vertex), (GLubyte *)(uintptr_t)offsetof(Vertex,r));
    // normals
    glVertexAttribPointer(ATTRIB_NORMAL, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLubyte *)(uintptr_t)offsetof(Vertex,nx));
    
    // At this point the VAO is set up with three vertex attributes referencing the same buffer object.
	
	free(boingData);
}

- (void)initShaders:(programInfo_t *)program
{
	for (int i = 0; i < NUM_PROGRAMS; i++)
	{
        // set constant uniforms
        glUseProgram(program[i].id);
        
        if (i == PROGRAM_LIGHTING)
        {
            // Set up lighting stuff used by the shaders
            glUniform3fv(program[i].uniform[UNIFORM_LIGHTDIR], 1, lightDirNormalized.v);
            glUniform4fv(program[i].uniform[UNIFORM_AMBIENT], 1, ambient);
            glUniform4fv(program[i].uniform[UNIFORM_DIFFUSE], 1, diffuse);
            glUniform4fv(program[i].uniform[UNIFORM_SPECULAR], 1, specular);
            glUniform1f(program[i].uniform[UNIFORM_SHININESS], shininess);
        }
        else if (i == PROGRAM_PASSTHRU)
        {
            glUniform4f(program[i].uniform[UNIFORM_CONSTANT_COLOR], 0.0f,0.0f,0.0f,0.4f);
        }
	}
}

- (instancetype)init
{
    if (self = [super init])
    {
		angleDelta = -0.05f;
		scaleFactor = 1.6;
		r = scaleFactor * 48.0f;
		
		xVelocity = 1.5f;
		yVelocity = 0.0f;
		xPos = r*2.0f;
		yPos = r*5.0f;
        
        // normalize light dir
        lightDirNormalized = GLKVector3Normalize(GLKVector3MakeWithArray(lightDir));
        
        projectionMatrix = GLKMatrix4Identity;
        
        [self generateBoingData];
    }
    return self;
}

- (void)makeOrthographicForWidth:(CGFloat)width height:(CGFloat)height
{
    projectionMatrix = GLKMatrix4MakeOrtho(0, width, 0, height, 0.0f, 2000.0);
}

- (void)update
{
	// Do "physics" stuff
	yVelocity -= 0.05f;
	
	xPos += xVelocity*scaleFactor;
	yPos += yVelocity*scaleFactor;
	
	if(xPos < (r+10.0f))
	{
		xPos = r+10.f;
		xVelocity = -xVelocity;
		angleDelta = -angleDelta;
	}
	else if(xPos > (310*scaleFactor-r))
	{
		xPos = 310*scaleFactor-r;
		xVelocity = -xVelocity;
		angleDelta = -angleDelta;
	}
	if(yPos < r)
	{
		yPos = r;
		yVelocity = -yVelocity;
	}
	
	angle += angleDelta;
	if(angle < 0.0f)
		angle += 360.0f;
	else if(angle > 360.0f)
		angle -= 360.0f;
}

- (void)render:(programInfo_t *)program
{
    GLKMatrix4 modelViewMatrix, MVPMatrix, modelViewMatrixIT;
    GLKMatrix3 normalMatrix;
    
    glBindVertexArray(vaoId);
    
    // Draw "shadow"
    glUseProgram(program[PROGRAM_PASSTHRU].id);
    
    glEnable(GL_CULL_FACE);
    glDisable(GL_DEPTH_TEST);
    glDepthMask(GL_FALSE);
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA_SATURATE, GL_ONE_MINUS_SRC_ALPHA);
	
	// Make the "shadow" move around a bit. This is not a real shadow projection.
    GLKVector3 pos = GLKVector3Normalize(GLKVector3Make(xPos, yPos, -100.0f));                                     
    modelViewMatrix = GLKMatrix4MakeTranslation(xPos + (pos.v[0]-lightDirNormalized.v[0])*20.0,
                                                yPos + (pos.v[1]-lightDirNormalized.v[1])*10.0,
                                                -800.0f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, -16.0f, 0.0f, 0.0f, 1.0f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, angle, 0.0f, 1.0f, 0.0f);
    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, 1.05f, 1.05f, 1.05f);
    
    MVPMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    glUniformMatrix4fv(program[PROGRAM_PASSTHRU].uniform[UNIFORM_MVP], 1, GL_FALSE, MVPMatrix.m);
    
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glEnableVertexAttribArray(ATTRIB_COLOR);
    
	glDrawArrays(GL_TRIANGLES, 0, 8*16*6);
    
    // Draw real Boing
    glUseProgram(program[PROGRAM_LIGHTING].id);
    
	glEnable(GL_DEPTH_TEST);
	glDepthMask(GL_TRUE);
	glDepthFunc(GL_LESS);
	glDisable(GL_BLEND);
    
    // ModelView
    modelViewMatrix = GLKMatrix4MakeTranslation(xPos, yPos, -100.0f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, -16.0f, 0.0f, 0.0f, 1.0f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, angle, 0.0f, 1.0f, 0.0f);
    glUniformMatrix4fv(program[PROGRAM_LIGHTING].uniform[UNIFORM_MODELVIEW], 1, GL_FALSE, modelViewMatrix.m);
    
    // MVP
    MVPMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    glUniformMatrix4fv(program[PROGRAM_LIGHTING].uniform[UNIFORM_MVP], 1, GL_FALSE, MVPMatrix.m);
    
    // ModelViewIT (normal matrix)
    bool success;
    modelViewMatrixIT = GLKMatrix4InvertAndTranspose(modelViewMatrix, &success);
    if (success) {
        normalMatrix = GLKMatrix4GetMatrix3(modelViewMatrixIT);
        glUniformMatrix3fv(program[PROGRAM_LIGHTING].uniform[UNIFORM_MODELVIEWIT], 1, GL_FALSE, normalMatrix.m);
    }
    
    glEnableVertexAttribArray(ATTRIB_NORMAL);
    
    glDrawArrays(GL_TRIANGLES, 0, 8*16*6);
    
    glDisableVertexAttribArray(ATTRIB_VERTEX);
    glDisableVertexAttribArray(ATTRIB_COLOR);
    glDisableVertexAttribArray(ATTRIB_NORMAL);
    
    glUseProgram(0);
}

- (void)dealloc
{
    if (vboId) {
        glDeleteBuffers(1, &vboId);
        vboId = 0;
    }
    if (vaoId) {
        glDeleteVertexArrays(1, &vaoId);
        vaoId = 0;
    }
    
    [super dealloc];
}

@end
