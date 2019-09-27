//
//  SMUGraphHelper.m
//  AudioLab
//
//  Created by Eric Larson.
//  Copyright © 2013 Eric Larson. All rights reserved.
//

#import "SMUGraphHelper.h"




struct point {
    GLfloat x;
    GLfloat y;
};

const GLfloat vertices[] = {
    0.1, 0.1,
    -0.1, 0.1,
    0.1,  -0.1,
    -0.1,  -0.1,
};
const GLfloat texCoords[] = {
    0., 1.,
    1., 1.,
    0., 0.,
    1., 0.,
};

typedef struct {
    float Position[2];
    float TexCoord[2]; // New
} Vertex;


@interface __GraphBounds : NSObject
{
    float   top,
    bottom,
    left,
    right,
    center,
    middle,
    width,
    height;

}

@end

@implementation __GraphBounds

-(instancetype)init{
    self = [super init];
    
    top = 1.0;
    bottom = -1.0;
    left = -1.0;
    right = 1.0;
    center = (left+right)/2;
    middle = (top+bottom)/2;
    width = right-left;
    height = top-bottom;
    
    return self;
}

-(instancetype)initWithTop:(float)inTop
                    bottom:(float)inBottom
                      left:(float)inLeft
                     right:(float)inRight{
    self = [super init];
    
    top = inTop;
    bottom = inBottom;
    left = inLeft;
    right = inRight;
    center = (left+right)/2;
    middle = (top+bottom)/2;
    width = right-left;
    height = top-bottom;
    
    return self;
}

-(void)setBoundsWithTop:(float)inTop
                 bottom:(float)inBottom
                   left:(float)inLeft
                  right:(float)inRight{
    top = inTop;
    bottom = inBottom;
    left = inLeft;
    right = inRight;
    center = (left+right)/2;
    middle = (top+bottom)/2;
    width = right-left;
    height = top-bottom;
    
}

-(float)getWidth{
    return width;
}

-(float)getHeight{
    return height;
}

-(float)getMiddle{
    return middle;
}

-(float)getCenter{
    return center;
}

@end

@interface __GraphData : NSObject
{
    struct point points[kGraphMaxSize];
    GLKVector4 colors[kGraphMaxSize];
    unsigned int graphSize;
    unsigned int maxGraphSize;
}

@end

@implementation __GraphData

-(instancetype)init{
    self = [super init];
    
    for(int i = 0; i < kGraphMaxSize; i++) {
        float x = (i - kGraphMaxSize/2) / 100.0;
        points[i].x = x;
        points[i].y = 0;
    }
    graphSize = kGraphMaxSize;
    maxGraphSize = kGraphMaxSize;
    
    return self;
}

-(void)setColor:(int) k{
    //iOS7 color palette with gradients
    UInt8 R[] = {0xFF,0xFF, 0x52,0x5A, 0xFF,0xFF, 0x1A,0x1D, 0xEF,0xC6, 0xDB,0x89, 0x87,0x0B, 0xFF,0xFF, };
    UInt8 G[] = {0x5E,0x2A, 0xED,0xC8, 0xDB,0xCD, 0xD6,0x62, 0x4D,0x43, 0xDD,0x8C, 0xFC,0xD3, 0x95,0x5E, };
    UInt8 B[] = {0x3A,0x68, 0xC7,0xFB, 0x4C,0x02, 0xFD,0xF0, 0xB6,0xFC, 0xDE,0x90, 0x70,0x18, 0x00,0x3A, };
    
    for(int i = 0; i < kGraphMaxSize; i++) {
        float grad1 = ((float)i)/kGraphMaxSize;
        float grad2 = 1-grad1;
        float r = ( ((float)R[(2*k)%16])*grad1 + ((float)R[(2*k+1)%16])*grad2 )/255.0;
        float g = ( ((float)G[(2*k)%16])*grad1 + ((float)G[(2*k+1)%16])*grad2 )/255.0;
        float b = ( ((float)B[(2*k)%16])*grad1 + ((float)B[(2*k+1)%16])*grad2 )/255.0;
        
        colors[i] = GLKVector4Make(r,g,b,0.9); // set color
    }
    
}

-(struct point*)getPoints{
    return points;
}

-(int)getNumPointsInBytes{
    return sizeof(points[0])*graphSize;
}

-(struct point)getPointAt:(unsigned int)index{
    return points[index];
}

-(void)setPointAt:(unsigned int)index
            withX:(float)x
            withY:(float)y
{
    points[index].x = x;
    points[index].y = y;
}

-(GLKVector4*)getColors{
    return colors;
}

-(int)getNumColorPointsInBytes{
    return sizeof(colors[0])*graphSize;
}


-(void)setGraphSize:(unsigned int)gSize{
    graphSize = gSize;
}

-(unsigned int)getGraphSize{
    return graphSize;
}

@end


@interface SMUGraphHelper()
{

    NSMutableArray<__GraphData *> *graphs;
    unsigned int numGraphs;
    enum PlotStyle plotStyle;
    
    GLuint *vbo;
    GLuint *color;
    GLuint vertexTex;
    
    EAGLContext     *context;
    GLKBaseEffect   *effect;
    
    __GraphBounds *bounds;
    GLKTextureInfo *spriteTexture;
}
@end

@implementation SMUGraphHelper

-(instancetype)initWithController:(GLKViewController*) selfinput
         preferredFramesPerSecond:(int) framesPerSecond
                        numGraphs:(int) numArrays
                        plotStyle:(enum PlotStyle) plotStyleInput
                maxPointsPerGraph:(int) maxGraphSize{
    
    self = [super init];
    
    //================================================
    // setup the OpenGL view
    //================================================
    // init the context for using OpenGL, try for ES3.0 (supported on some devices, starting in iOS7)
    context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    
    
    if (!context){
        // Fall back to the ES2.0, supported on most every device
        NSLog(@"OpenGL 3.0 not supported on device, trying 2.0");
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    }
    
    if(!context){
        [NSException raise:@"Failed to create OpenGLES context, exiting"
                    format:@"Context is %@",context];
    }
    
    selfinput.preferredFramesPerSecond = framesPerSecond; // draw every 1/Nth of a second
    
    // cast the current view as GLKView (view must inherit from GLKView, set in storyboard)
    GLKView *view = (GLKView *)selfinput.view;
    view.context = context;
    
    [EAGLContext setCurrentContext:context];
    effect = [[GLKBaseEffect alloc] init];
    
    // setup data arrays for graphing
    bounds      = [[__GraphBounds alloc]init];
    plotStyle   = plotStyleInput;
    numGraphs   = numArrays;
    graphs = [[NSMutableArray alloc]initWithCapacity:numArrays];
    
    vbo   = (unsigned int *)malloc(sizeof(GLuint)*numArrays);
    color = (unsigned int *)malloc(sizeof(GLuint)*numArrays);
    
    // setup each line for OpenGL graphing
    for(int k=0;k<numGraphs;k++){
        graphs[k] = [[__GraphData alloc]init];
        [graphs[k] setColor:k];
        
        glGenBuffers(1, &vbo[k]);
        glBindBuffer(GL_ARRAY_BUFFER, vbo[k]);
        glBufferData(GL_ARRAY_BUFFER, [graphs[k] getNumPointsInBytes], [graphs[k] getPoints], GL_DYNAMIC_DRAW);
        
        glGenBuffers(1, &color[k]);
        glBindBuffer(GL_ARRAY_BUFFER, color[k]);
        glBufferData(GL_ARRAY_BUFFER, [graphs[k] getNumColorPointsInBytes], [graphs[k] getColors], GL_STATIC_DRAW);
    }
    
    return self;
}

-(void)dealloc{
    
    [EAGLContext setCurrentContext:context];
    for(int k=0;k<numGraphs;k++){
        glDeleteBuffers(1, &vbo[k]);
        glDeleteBuffers(1, &color[k]);
    }
    effect = nil;
    
    free(vbo);
    free(color);
}

-(void)tearDownGL{
    
    [EAGLContext setCurrentContext:context];
    
    for(int k=0;k<numGraphs;k++){
        glDeleteBuffers(1, &vbo[k]);
        glDeleteBuffers(1, &color[k]);
    }
    
    effect = nil;
    
    free(vbo);
    free(color);
    
}


-(void) setBoundsWithTop:(float)inTop
                  bottom:(float)inBottom
                    left:(float)inLeft
                   right:(float)inRight
{
    [bounds setBoundsWithTop:inTop bottom:inBottom left:inLeft right:inRight];
}

-(void) setFullScreenBounds
{
    [bounds setBoundsWithTop:1.0 bottom:-1.0 left:-1.0 right:1.0];
}

-(void) setScreenBoundsTopHalf
{
    [bounds setBoundsWithTop:1.0 bottom:0.0 left:-1.0 right:1.0];
}

-(void) setScreenBoundsBottomHalf
{
    [bounds setBoundsWithTop:0.0 bottom:-1.0 left:-1.0 right:1.0];
}

-(void) update{
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 0.0f);
    effect.transform.modelviewMatrix = modelViewMatrix;
}



-(void) setGraphData:(float*)data
      withDataLength:(int)dataLength
       forGraphIndex:(int)arrayNum
{
    // just call the default stuff
    [self setGraphData:data
        withDataLength:dataLength
         forGraphIndex:arrayNum
     withNormalization:1.0
         withZeroValue:0.0];
}

-(void) setGraphData:(float*)data
      withDataLength:(int)dataLength
       forGraphIndex:(int)arrayNum
   withNormalization:(float)normalization
        withZeroValue:(float)minValue

{
    
    if(data==NULL){
        printf("Memory not yet allocated for data buffer\n");
        return;
    }
    
    if(arrayNum>numGraphs){
        printf("tried to access graph number %d, when num graphs initialized is N=%d\n",arrayNum,numGraphs);
        return;
    }
    
    if(dataLength>kGraphMaxSize){
        printf("Request to print more points than allocated for max array size, clipping array length from %d to %d\n",dataLength,kGraphMaxSize);
        dataLength=kGraphMaxSize;
    }
    
    float lengthOverTwo = ((float)dataLength)/2.0; // for plotting the x value
    float xnormalizer = ([bounds getWidth]/2.0)/lengthOverTwo;
    float addToPlot = [bounds getMiddle];
    
    normalization -= minValue;
    if(plotStyle == PlotStyleSeparated){
        normalization *= ((float)numGraphs);
        addToPlot = -1 + (((float)arrayNum)) / ((float)numGraphs) * 2 + 1.0/((float)numGraphs);
    }
    
    [graphs[arrayNum] setGraphSize:dataLength];
    
    normalization *= ([bounds getHeight]/2.0);
    addToPlot *= ([bounds getHeight]/2.0);
    for(int i = 0; i < dataLength; i++) {
        float x = (((float)i) - lengthOverTwo) * xnormalizer;
        float y = (((data[i]-minValue) / normalization) + addToPlot);
        [graphs[arrayNum] setPointAt:i
                               withX:(x + [bounds getCenter])
                               withY:(y  + [bounds getMiddle])];
    }
}


-(void) draw{
    
    // Clear the view
    glClear(GL_COLOR_BUFFER_BIT);
    
    effect.useConstantColor = GL_FALSE;
    
    
    [effect prepareToDraw];
    
    
    for(int k=0;k<numGraphs;k++){
        
        glBindBuffer(GL_ARRAY_BUFFER, vbo[k]);
        glBufferData(GL_ARRAY_BUFFER, [graphs[k] getNumPointsInBytes], [graphs[k] getPoints], GL_DYNAMIC_DRAW);
        glEnableVertexAttribArray(GLKVertexAttribPosition);
        glVertexAttribPointer(GLKVertexAttribPosition,   // attribute
                              2,                   // number of elements per vertex, here (x,y)
                              GL_FLOAT,            // the type of each element
                              GL_FALSE,            // take our values as-is
                              0,                   // no space between values
                              0                    // use the vertex buffer object
                              );
        
        // set the color
        glBindBuffer(GL_ARRAY_BUFFER, color[k]);
//        //glColorPointer(4, GL_FLOAT, 0, graphs[k].colors);
        glEnableVertexAttribArray(GLKVertexAttribColor);
        glVertexAttribPointer(GLKVertexAttribColor,
                              4,
                              GL_FLOAT,
                              GL_FALSE,
                              0,
                              0);
        
        glDrawArrays(GL_LINE_STRIP, 0, [graphs[k] getGraphSize]); // just draw the data that was sent in
        
        glDisableVertexAttribArray(GLKVertexAttribPosition);
        glDisableVertexAttribArray(GLKVertexAttribColor);
    }
}

@end
