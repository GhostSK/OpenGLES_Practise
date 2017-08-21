//
//  TestView.m
//  OpenGLES02_shader
//
//  Created by 胡杨林 on 2017/8/17.
//  Copyright © 2017年 胡杨林. All rights reserved.
//

#import "TestView.h"
#import <OpenGLES/ES2/gl.h>

@interface TestView()

@property (nonatomic, strong)EAGLContext *myContext;
@property (nonatomic, strong)CAEAGLLayer *myEagLayer;
@property (nonatomic, assign)GLuint myProgram;

@property (nonatomic, assign)GLuint myColorRenderBuffer;
@property (nonatomic, assign)GLuint myColorFrameBuffer;

- (void)setupLayer;

@end

@implementation TestView

+ (Class)layerClass{
    return [CAEAGLLayer class];
}

- (void)layoutSubviews{
    
    [self setupLayer];
    [self setupContext];
    [self destoryRenderAndFrameBuffer];
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    [self render];

}
- (void)render {
    glClearColor(0, 1.0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    //设置背景颜色并清除颜色缓冲
    
    CGFloat scale = [[UIScreen mainScreen] scale];  //获取视图放大倍数
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
    //设置视图大小
    
    //读取文件路径
    NSString *vertFile = [[NSBundle mainBundle]pathForResource:@"shaderv" ofType:@"vsh"];
    NSString *fragFile = [[NSBundle mainBundle]pathForResource:@"shaderf" ofType:@"fsh"];
    //加载shader
    self.myProgram = [self loadShaders:vertFile frag:fragFile];
    
    //链接
    glLinkProgram(self.myProgram);
    GLint linkSuccess;
    glGetProgramiv(self.myProgram, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {  //链接错误
        GLchar messages[256];
        glGetProgramInfoLog(self.myProgram, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"连接错误log输出为%@",messageString);
        return;
    }else{
        NSLog(@"连接成功");
        glUseProgram(self.myProgram);  //链接成功，则使用该program
    }
    
    //前三个是顶点坐标， 后面两个是纹理坐标
    GLfloat attrArr[] =
    {
        0.5f, -0.5f, -1.0f,     1.0f, 0.0f,
        -0.5f, 0.5f, -1.0f,     0.0f, 1.0f,
        -0.5f, -0.5f, -1.0f,    0.0f, 0.0f,
        0.5f, 0.5f, -1.0f,      1.0f, 1.0f,
        -0.5f, 0.5f, -1.0f,     0.0f, 1.0f,
        0.5f, -0.5f, -1.0f,     1.0f, 0.0f,
    };
    
    GLuint attiBuffer;
    glGenBuffers(1, &attiBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, attiBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    /*
     void glVertexAttribPointer( GLuint index, GLint size, GLenum type, GLboolean normalized, GLsizei stride,const GLvoid * pointer);
     参数：
     index 指定要修改的定点属性的索引值
     size 指定每个定点属性的组件数量， 必须为1、2、3、4中的一个，默认为4 如position由xyz三个值组成，颜色rgba四个
     type 指定数组中每个组件的数据类型，可用的符号常量有GL_BYTE, GL_UNSIGNED_BYTE, GL_SHORT,GL_UNSIGNED_SHORT, GL_FIXED, 和 GL_FLOAT，初始值为GL_FLOAT。
     normailzed 指定当被访问时，固定点数据值是否应该被归一化（GL_TRUE） 或者直接转化为固定值（GL_FALSE）
     stride 指定连续顶点之间的属性的偏移量，实质上可以认为是每个顶点属性所携带的数据总长度，初始值为0
     pointer：指定第一个组件在数组的第一个定点属性中的偏移量，该数组与GL_ARRAY_BUFFER绑定，储存于缓冲区，初始值为0
     */
    GLuint position = glGetAttribLocation(self.myProgram, "position");
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, NULL);
    glEnableVertexAttribArray(position);

    GLuint textColor = glGetAttribLocation(self.myProgram, "textCoordinate");
    glVertexAttribPointer(textColor, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (float *)NULL + 3);
    glEnableVertexAttribArray(textColor);
    
    //加载纹理
    [self setupTexture:@"for_test"];
    
    //获取shader里面的变量，这里记得要在glLinkProgram后面
    GLuint rotate = glGetUniformLocation(self.myProgram, "rotateMatrix");
    
    float radians = 10 * 3.141592654 / 180.0;
    float s = sinf(radians);
    float c = cosf(radians);
    
    //z轴旋转矩阵
    GLfloat zRotation[16] = { //
        c, -s, 0, 0.2, //
        s, c, 0, 0,//
        0, 0, 1.0, 0,//
        0.0, 0, 0, 1.0//
    };
    
    //设置旋转矩阵
    glUniformMatrix4fv(rotate, 1, GL_FALSE, (GLfloat *)&zRotation[0]);
    
    glDrawArrays(GL_TRIANGLES, 0, 6);
    
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
    
    
}
/**
 *  c语言编译流程：预编译、编译、汇编、链接
 *  glsl的编译过程主要有glCompileShader、glAttachShader、glLinkProgram三步；
 *  @param vert 顶点着色器
 *  @param frag 片元着色器
 *
 *  @return 编译成功的shaders
 */
- (GLuint)loadShaders:(NSString *)vert frag:(NSString *)frag{
    GLuint verShader, fragShader;
    //Vertex shader 是每个顶点执行一次，fragment则是每个片段执行一次。
    //fragment shader是用来输出颜色的
    //vertex shader用来输出顶点坐标？
    GLint program = glCreateProgram();
    //编译
    [self compileShader:&verShader type:GL_VERTEX_SHADER file:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];
    
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);
    
    //释放不需要的shader
    glDeleteShader(verShader);
    glDeleteShader(fragShader);
    return program;
}

- (void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file{
    //读取字符串
    NSString *content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    const GLchar *source = (GLchar *)[content UTF8String];
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
}

- (void)setupLayer{
    self.myEagLayer = (CAEAGLLayer *)self.layer;
    //设置放大倍数
    [self setContentScaleFactor:[[UIScreen mainScreen] scale]];
    
    //CALayer 默认透明 必须设为不透明才可见
    self.myEagLayer.opaque = YES;
    //设置描绘属性，在这里设置不维持渲染内容以及颜色格式为RGBA8
    self.myEagLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking,kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
}


- (void)setupContext{
    //指定OpenGL渲染API的版本 这里使用OpenGL ES2.0
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    EAGLContext *context = [[EAGLContext alloc]initWithAPI:api];
    if (!context) {
        NSLog(@"初始化OpenGLES2.0上下文失败");
        exit(1);
    }
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"设置当前OpenGL上下文失败");
        exit(1);
    }
    
    
    self.myContext = context; //设置为当前上下文
}

- (void)setupRenderBuffer{
    GLuint buffer;
    glGenRenderbuffers(1, &buffer);
    self.myColorRenderBuffer = buffer;
    glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
    //为颜色缓冲区 分配存储空间
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEagLayer];
}


- (void)setupFrameBuffer{
    GLuint buffer;
    glGenFramebuffers(1, &buffer);
    self.myColorFrameBuffer = buffer;
    //设置为当前frameBuffer
    glBindFramebuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0);
    // 将colorRenderBuffer装配到GL_COLOR_ATTACHMENT0这个装配点
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.myColorRenderBuffer);
}

- (void)destoryRenderAndFrameBuffer{
    glDeleteFramebuffers(1, &_myColorFrameBuffer);
    self.myColorFrameBuffer = 0;
    glDeleteRenderbuffers(1, &_myColorRenderBuffer);
    self.myColorRenderBuffer = 0;
}



- (GLuint)setupTexture:(NSString *)fileName{
    //获取图片的CGImageRef
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    if (!spriteImage) {
        NSLog(@"读取图片失败");
        exit(1);
    }
    //读取图片大小
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    GLubyte *spriteData = (GLubyte *)calloc(width * height * 4, sizeof(GLubyte)); //rgba共4个byte
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width * 4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    //在CGContextRef上绘图
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    CGContextRelease(spriteContext);
    //绑定纹理到默认的纹理ID 这里只有一张图片，就相当于默认于着色器里面的colorMap，如果有多张图，则可能要添加选择colorMap步骤？
    glBindTexture(GL_TEXTURE_2D, 0);
    /*
     glTexParameteri() 是纹理过滤参数
     第一个参数：target：只找到了GL_TEXTURE_2D作为有效值的案例，似乎是强制指定2D纹理模式，待确认
     第二个参数：
     #define GL_TEXTURE_MAG_FILTER                            放大过滤
     #define GL_TEXTURE_MIN_FILTER                            缩小过滤
     #define GL_TEXTURE_WRAP_S                                S轴（横轴）方向的贴图模式
     #define GL_TEXTURE_WRAP_T                                T轴（纵轴）方向的贴图模式
     //另外还有垂直于屏幕的坐标轴R轴   在2D纹理中，由于没有R轴，可以横改为U纵轴改为V，即UV坐标系
     第三个参数：
     缩放模式对应的参数：
     #define GL_NEAREST     使用纹理中坐标最接近的一个像素的颜色作为需要绘制的像素颜色
     #define GL_LINEAR      使用纹理中坐标最接近的若干个颜色，通过加权平均算法得到需要绘制的像素颜色
     GL_NEAREST只经过简单比较，运算速度较快（除非加权模式有图形卡加速）但是容易出现锯齿，效果差
     GL_LINEAR经过加权平均计算，效果较好，消耗性能较大
     贴图模式对应的参数：
     #define GL_REPEAT         超出纹理范围的坐标整数部分被忽略，形成重复效果。
     #define GL_CLAMP_TO_EDGE   超出纹理范围的坐标被截取成0和1，形成纹理边缘延伸的效果。
     #define GL_MIRRORED_REPEAT     超出纹理范围的坐标整数部分被忽略，但当整数部分为奇数时进行取反，形成镜像效果。
    GL_CLAMP_TO_BORDER: 超出纹理范围的部分被设置为边缘色。 ——本选项未见，可能不在ES2中
     
     好的参考文献：http://www.jianshu.com/p/1829b4acc58d
     
     
     
     */
    
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    float fw = width, fh = height;
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    glBindTexture(GL_TEXTURE_2D, 0);
    free(spriteData);
    return 0;
}


@end

































