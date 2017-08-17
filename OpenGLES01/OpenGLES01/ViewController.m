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
        //第一组
        0.5, -0.5, 0.0f,    0.0f, 1.0f, //右下
        0.5, 0.5, -0.0f,    0.0f, 0.0f, //右上
        -0.5, 0.5, 0.0f,    1.0f, 0.0f, //左上
        //本组与第二组位置坐标相同，纹理坐标反置（中心旋转180度），顺利得到旋转180°后的左下半部分图片
        //图片被倒放渲染在右上方三角形内
        
        
        //第二组
        0.5, -0.5, 0.0f,    1.0f, 0.0f, //右下
        0.5, 0.5, -0.0f,    1.0f, 1.0f, //右上
        -0.5, 0.5, 0.0f,    0.0f, 1.0f, //左上
        //这三个顶点绘制了右上方的三角形并拼接了右上方的纹理，无变形
        //第三组
        0.5, -0.5, 0.0f,    1.0f, 0.0f, //右下
        -0.5, 0.5, 0.0f,    0.0f, 1.0f, //左上
        -0.5, -0.5, 0.0f,   0.0f, 0.0f, //左下
        //这三个顶点绘制了左下方的三角形并拼接了左下方的纹理，无变形
        
        //第四组
        -0.5, -0.5, 0.0,   0.0, 0.0, //左下
        -0.5, 0.5, 0.0, 0.0, 1.0,  //左上
        0.5, 0.5, 0.0, 1.0, 1.0,  //右上
        0.0, -0.8, 0.0, 0.5, 0.0, //下中
        
        0.5, -0.5, 0.0, 1.0, 0.0, //右下
        -0.5, -0.5, 0.0,   0.0, 0.0, //左下
        0.5, 0.5, 0.0, 1.0, 1.0,  //右上
        
    };
    
    //顶点数据缓存
    GLuint buffer;
    glGenBuffers(1, &buffer);  //申请一个标识符
    glBindBuffer(GL_ARRAY_BUFFER, buffer);  //把标识符绑定到GL_ARRAY_BUFFER上
    glBufferData(GL_ARRAY_BUFFER, sizeof(squareVertexData), squareVertexData, GL_STATIC_DRAW); //把顶点数据从CPU内存GPU内存
    /*
     最后一个参数：
     GL_STATIC_DRAW ：数据不会或几乎不会改变。
     GL_DYNAMIC_DRAW：数据会被改变很多。
     GL_STREAM_DRAW ：数据每次绘制时都会改变。
     */
    
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
    self.mEffect.texture2d0.enabled = GL_TRUE;  //纹理是否可用
    self.mEffect.texture2d0.name = textureInfo.name;
    //对着色器赋值，由于着色器已被设为currentEffect，会即时刷新到屏幕去
}

/**
 *  渲染场景代码
 */
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    glClearColor(0.3f, 0.6f, 1.0f, 1.0f);  //设置清屏颜色
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT); //参数为清屏属性选择，有颜色 深度 模型三个选项
    //该方法会反复刷新渲染，rect范围为整个屏幕
    //启动着色器
    [self.mEffect prepareToDraw];
    glDrawArrays(GL_TRIANGLE_FAN, 9, 4);
    /*
     mode参数有以下选项   自行测试结果为
     #define GL_POINTS   绘制点
     #define GL_LINES     绘制直线 1连接2  3连接4 以此类推
     #define GL_LINE_LOOP   字面意思为绘制线圈，A-B-C-D-E-F-G-A实际效果与上一条相同
     #define GL_LINE_STRIP   字面意义为线条带，A-B-C-D-E-F-G(不会连接回第一点)实际同上一条
     #define GL_TRIANGLES     把每三个顶点作为一个独立的三角形，顶点3n－2、3n－1和3n定义了第n个三角形，总共绘制N/3个三角形
     #define GL_TRIANGLE_STRIP  绘制三角形ABC ACD ADE AEF AFG A点为屏幕正中心点，BCDEFG为序列点
     #define GL_TRIANGLE_FAN   绘制三角形ABC ACD ADE AEF AFG A为序列第一点
     
     
     以下为百科内容，不过是 void glBegin(GLenum mode)的mode参数的，不是glDrawArrays的
     　　GL_POINTS：把每一个顶点作为一个点进行处理，顶点n即定义了点n，共绘制N个点
     　　GL_LINES：把每一个顶点作为一个独立的线段，顶点2n－1和2n之间共定义了n条线段，总共绘制N/2条线段
     　　GL_LINE_STRIP：绘制从第一个顶点到最后一个顶点依次相连的一组线段，第n和n+1个顶点定义了线段n，总共绘制n－1条线段
     　　GL_LINE_LOOP：绘制从第一个顶点到最后一个顶点依次相连的一组线段，然后最后一个顶点和第一个顶点相连，第n和n+1个顶点定义了线段n，总共绘制n条线段
     　　GL_TRIANGLES：把每个顶点作为一个独立的三角形，顶点3n－2、3n－1和3n定义了第n个三角形，总共绘制N/3个三角形
     　　GL_TRIANGLE_STRIP：绘制一组相连的三角形，对于奇数n，顶点n、n+1和n+2定义了第n个三角形；对于偶数n，顶点n+1、n和n+2定义了第n个三角形，总共绘制N-2个三角形
     　　GL_TRIANGLE_FAN：绘制一组相连的三角形，三角形是由第一个顶点及其后给定的顶点确定，顶点1、n+1和n+2定义了第n个三角形，总共绘制N-2个三角形
     　　GL_QUADS：绘制由四个顶点组成的一组单独的四边形。顶点4n－3、4n－2、4n－1和4n定义了第n个四边形。总共绘制N/4个四边形
     　　GL_QUAD_STRIP：绘制一组相连的四边形。每个四边形是由一对顶点及其后给定的一对顶点共同确定的。顶点2n－1、2n、2n+2和2n+1定义了第n个四边形，总共绘制N/2-1个四边形
     　　GL_POLYGON：绘制一个凸多边形。顶点1到n定义了这个多边形。
     
     */
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
