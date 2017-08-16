//
//  ViewController.m
//  OpenGLES01
//
//  Created by 胡杨林 on 2017/8/15.
//  Copyright © 2017年 胡杨林. All rights reserved.
//

#import "ViewController.h"
#import <GLKit/GLKit.h>

@interface ViewController ()

@property (nonatomic, strong)EAGLContext *mContext;
@property (nonatomic, strong)GLKBaseEffect *mEffect;

@property (nonatomic, assign)int mCount;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupConfig];
    [self uploadVertexArray];
    [self uploadTexture];
}

- (void)setupConfig {
    
    /*
     OpenGL自身是一个巨大的状态机(State Machine)：一系列的变量描述OpenGL此刻应当如何运行。OpenGL的状态通常被称为OpenGL上下文(Context)。我们通常使用如下途径去更改OpenGL状态：设置选项，操作缓冲。最后，我们使用当前OpenGL上下文来渲染。
     
     假设当我们想告诉OpenGL去画线段而不是三角形的时候，我们通过改变一些上下文变量来改变OpenGL状态，从而告诉OpenGL如何去绘图。一旦我们改变了OpenGL的状态为绘制线段，下一个绘制命令就会画出线段而不是三角形。
     
     当使用OpenGL的时候，我们会遇到一些状态设置函数(State-changing Function)，这类函数将会改变上下文。以及状态使用函数(State-using Function)，这类函数会根据当前OpenGL的状态执行一些操作。只要你记住OpenGL本质上是个大状态机，就能更容易理解它的大部分特性。
     
     */
    
    //新建OpenGLES 上下文
    self.mContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2]; //2.0，还有1.0和3.0
    GLKView* view = (GLKView *)self.view; //storyboard记得添加
    view.context = self.mContext;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;  //颜色缓冲区格式
    [EAGLContext setCurrentContext:self.mContext];
    //本段落用来初始化一个上下文并将其设为当前上下文
}

- (void)uploadVertexArray {
    //顶点数据，前三个是顶点坐标，后面两个是纹理坐标
    /*
     OpenGLES的世界坐标系是[-1, 1]，故而点(0, 0)是在屏幕的正中间。
     纹理坐标系的取值范围是[0, 1]，原点是在左下角。故而点(0, 0)在左下角，点(1, 1)在右上角。
     索引数组是顶点数组的索引，把squareVertexData数组看成4个顶点，每个顶点会有5个GLfloat数据，索引从0开始。
     */
    
    
    GLfloat squareVertexData[] =
    {
        0.5, -0.5, 0.0f,    1.0f, 0.0f, //右下
        0.5, 0.5, -0.0f,    1.0f, 1.0f, //右上
        -0.5, 0.5, 0.0f,    0.0f, 1.0f, //左上
        
        0.5, -0.5, 0.0f,    1.0f, 0.0f, //右下
        -0.5, 0.5, 0.0f,    0.0f, 1.0f, //左上
        -0.5, -0.5, 0.0f,   0.0f, 0.0f, //左下
    };
    
    //顶点数据缓存
    GLuint buffer;
    glGenBuffers(1, &buffer);  //申请一个标识符
    glBindBuffer(GL_ARRAY_BUFFER, buffer);  //把标识符绑定到GL_ARRAY_BUFFER上
    glBufferData(GL_ARRAY_BUFFER, sizeof(squareVertexData), squareVertexData, GL_STATIC_DRAW); //把顶点数据从CPU内存GPU内存
    
    glEnableVertexAttribArray(GLKVertexAttribPosition); //顶点数据缓存  开启对应的顶点属性
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 0);  //读取顶点数据
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0); //纹理
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 3);  //读取纹理数据
}

- (void)uploadTexture {
    //纹理贴图
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"for_test" ofType:@"jpg"];
    NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:@(1), GLKTextureLoaderOriginBottomLeft, nil];//GLKTextureLoaderOriginBottomLeft 纹理坐标系是相反的
    GLKTextureInfo* textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:options error:nil];  //读取纹理贴图，装填进textureInfo
    //着色器
    self.mEffect = [[GLKBaseEffect alloc] init];
    self.mEffect.texture2d0.enabled = GL_TRUE;
    self.mEffect.texture2d0.name = textureInfo.name;
    //对着色器赋值，由于着色器已被设为currentEffect，会即时刷新到屏幕去
}

/**
 *  渲染场景代码
 */
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    glClearColor(0.3f, 0.6f, 1.0f, 1.0f);  //设置背景颜色
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    //该方法会反复刷新渲染，rect范围为整个屏幕
    //启动着色器
    [self.mEffect prepareToDraw];
    glDrawArrays(GL_TRIANGLES, 0, 6);
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSString *path = [[NSBundle mainBundle]pathForResource:@"test_02" ofType:@"png"];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@(1), GLKTextureLoaderOriginBottomLeft, nil];
    GLKTextureInfo *info = [GLKTextureLoader textureWithContentsOfFile:path options:options error:nil];
    //上文用于装填TextureInfo，由于Effect已建立，直接替换info.name即可完成渲染替换
    self.mEffect.texture2d0.name = info.name;
}

@end
