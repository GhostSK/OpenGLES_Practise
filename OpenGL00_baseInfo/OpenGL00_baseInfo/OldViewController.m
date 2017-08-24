//
//  ViewController.m
//  OpenGL00_baseInfo
//
//  Created by 胡杨林 on 2017/8/23.
//  Copyright © 2017年 胡杨林. All rights reserved.
//

#import "OldViewController.h"

@interface OldViewController ()

@property (nonatomic, strong)CAEAGLLayer *myEagLayer;

@end

@implementation OldViewController

- (void)viewDidLoad {
    [super viewDidLoad];
#pragma mark OpenGL基础环境设置
    //设置OpenGL版本
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    EAGLContext* context = [[EAGLContext alloc] initWithAPI:api];
    if (!context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    
    // 设置为当前上下文
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
    
    self.myEagLayer = (CAEAGLLayer*) self.view.layer;
    //设置放大倍数
    [self.view setContentScaleFactor:[[UIScreen mainScreen] scale]];
    
    // CALayer 默认是透明的，必须将它设为不透明才能让其可见
    self.myEagLayer.opaque = YES;
    
    // 设置描绘属性，在这里设置不维持渲染内容以及颜色格式为 RGBA8
    self.myEagLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    GLuint colorbuffer;
    glGenRenderbuffers(1, &colorbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, colorbuffer);
    // 为 颜色缓冲区 分配存储空间
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEagLayer];
    GLuint Framebuffer;
    glGenFramebuffers(1, &Framebuffer);
    // 设置为当前 framebuffer
    glBindFramebuffer(GL_FRAMEBUFFER, Framebuffer);
    // 将 _colorRenderBuffer 装配到 GL_COLOR_ATTACHMENT0 这个装配点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, colorbuffer);
    //清屏颜色设定，参数为RGBA
    glClearColor(0.5, 0.5, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT); //只清除颜色
    [context presentRenderbuffer:GL_RENDERBUFFER];
#pragma mark 基础环境到这里设定结束，如果一切正确，你可以看到你设置的clearColor占满屏幕
    glDeleteFramebuffers(1, &colorbuffer);
    colorbuffer = 0;
    glDeleteRenderbuffers(1, &Framebuffer);
    Framebuffer = 0;  //销毁缓冲回收资源
    
    /*
     https://learnopengl-cn.github.io/01%20Getting%20started/04%20Hello%20Triangle/#_2
     你需要记住以下单词：
     顶点数组对象：Vertex Array Object，VAO
     顶点缓冲对象：Vertex Buffer Object，VBO
     索引缓冲对象：Element Buffer Object，EBO或Index Buffer Object，IBO
     */
    /*
     在OpenGL中，任何事物都是在3D空间汇总的，而屏幕和窗口却是2D像素数组
     这导致OpenGl大部分工作都市关于吧3D坐标转变为适应你屏幕的2D像素，
     这个3D转2D的处理过程是由OpenGL的图形渲染管线（Graohics Pipeline大多
     翻译为管线，实际上值得是一堆原始图形数据经过一个输送通道，期间经过各种变化处理最终出现在
     屏幕的过程）管理的。图形渲染管线可以划分为两个主要部分：
     第一部分把你的3D坐标转换为2D坐标
     第二部分吧2D坐标转换为实际的有色像素
     2D坐标和像素是不同的
     2D坐标精确表示一个点在2D空间中的位置，而2D像素则是这个点的近似值，受到分辨率的限制
     如Shader_work_process.png所示，图形渲染管线包含很多部分，每个部分都将在转换顶点数据到最终像素这一过程中处理各自特定的阶段。我们会概括性地解释一下渲染管线的每个部分，让你对图形渲染管线的工作方式有个大概了解。
     
     为了让OpenGL知道我们的坐标和颜色值构成的到底是什么，OpenGL需要你去指定这些数据所表示的渲染类型。我们是希望把这些数据渲染成一系列的点？一系列的三角形？还是仅仅是一个长长的线？做出的这些提示叫做图元(Primitive)，任何一个绘制指令的调用都将把图元传递给OpenGL。这是其中的几个：GL_POINTS、GL_TRIANGLES、GL_LINE_STRIP。
     
     */
    
    /*
     图形渲染管线的第一个部分是顶点着色器Vertex Shader，它把一个单独的顶点作为输入
     顶点着色器主要的目的是把3D坐标转换为另一种3D坐标，同时允许我们对定点属性进行一些基本处理
     
     图元装配阶段(Primitive Assembly)将顶点着色器输出的所有顶点作为输入（如果是GL_POINTS
     那么依然是一个顶点）并将所有的点装配成指定图元的形状 这里例子是一个三角形
     
     图元装配阶段的输出会传递给几何着色器（Geometry Shader） 几何着色器把图元形式的一系列顶点
     的集合作为输入，他可以通过产生新顶点构造出新的图元来生成其他形状  这里生成了另一个三角形
     
     几何着色器的输出会被传入光栅化阶段（Rasterization Stage），这里他会把图元因设为最终屏幕上
     相应的像素，生成供片段着色器（Fragment Shader）使用的片段（Fragment），在片段着色器
     运行之前会执行裁切（Clipping）裁切会丢弃超出你的视图意外的所有像素，用来提升执行效率
     
     ######   OpenGL中的一个片段是OpenGL渲染一个像素所需的所有数据。
     
     片段着色器的主要目的是计算一个像素的最终颜色，这也是所有OpenGL高级效果产生的地方
     通常，片段着色器包含3D场景的数据，比如光照、阴影、光的颜色等等，这些数据可以被用来计算最终像素的颜色
     在所有对应颜色值确定以后，最终的对象会被传到最后一个阶段，叫做Alpha测试和混合Blending阶段，
     这个阶段检测片段对应的深度（和模板（Stencil）值，用来判断这个像素是在其他物体的前后，决定是否
     应该丢弃。这个阶段也会检查alpha透明度，并对物体进行混合Blend，所以，即使在片段着色器中
     计算出了一个像素输出的颜色，在渲染多个三角形的时候最终结果也有可能不同
     
     在现代OpenGL中，我们必须定义至少一个顶点着色器和一个片段着色器，因为GPU中没有默认的这两种
     着色器。
     
     */
    /*
     现在开始我们尝试绘制第一个自己的三角形。在开始绘制徒刑之前，我们必须献给OpenGL输入一些顶点数据，
     OpenGL是一个3D图形库，所以我们在这里指定的坐标都是3D坐标。OpenGL仅当三个卓彪都在-1.0到1.0
     的范围内才会处理她。所有在所谓的标准化设备坐标（Normalized Device Coordinates）范围内
     的坐标才会最终呈现在屏幕上，其他不在范围内的坐标都不会显示。
     */
    float vertices[] =
    {
        0.5f, -0.5f, -1.0f,
        -0.5f, 0.5f, -1.0f,
        -0.5f, -0.5f, -1.0f,
        0.5f, 0.5f, -1.0f,
        -0.5f, 0.5f, -1.0f,
        0.5f, -0.5f, -1.0f,
    };
    /*
     由于OpenGL是在3D空间中工作的，而我们渲染的是一个2D三角形，我们将它顶点的z坐标设置为0.0。这样子的话三角形每一点的深度(Depth，译注2)都是一样的，从而使它看上去像是2D的。
     
     通常深度可以理解为z坐标，它代表一个像素在空间中和你的距离，如果离你远就可能被别的像素遮挡，你就看不到它了，它会被丢弃，以节省资源。
     
     定义这样的顶点数据以后，我们会把它作为输入发送给图形渲染管线的第一个处理阶段：顶点着色器。
     亚辉在GPU上创建内存用于储存我们的顶点数据。还要配置OpenGL如何解释这些内存，并且制定其
     如何发送给显卡。顶点着色器接着会处理我们在内存中制定数量的顶点。
     我们通过顶点缓冲对象（vertex Buffer Objects，VBO）管理这个内存。他会在GPU内存（现存）
     中储存大量顶点。使用这些缓冲对象的好处是我们一个一次性的发送一大批数据到显卡上，而不是每个顶点
     发送一次。从CPU吧数据发送到显卡相对较慢，所以只要可能，我们都要尝试尽量一次性发送尽可能多的数据。
     当数据发送到现存后，顶点着色器几乎能立即访问顶点，这是个非常快的过程。
     顶点缓冲对象VBO是我们在OpenGL教程中出现的第一个OpenGL对象。就像OpenGL中的其他对象一样，这个
     缓冲有一个独一无二的ID，所以我们可以使用glGenBuffers函数和一个缓冲ID生成一个VBO对象：
     unsigned int VBO;
     glGenbuffers(1, &VBO);
     
     OpenGL有着很多缓冲对象类型，顶点缓冲对象的缓冲类型是GL_ARRAY_BUFFER，OpenGL允许我们同时
     绑定多个缓冲，只要他们是不同的缓冲类型，我们可以食用glBindBuffer函数来把新创建的缓冲绑定到
     GL_ARRAY_BUFFER目标上。
     glBindBuffer(GL_ARRAY_BUFFER,VBO);
     
     //自我理解：GL_ARRAY_BUFFER是缓冲类型，相当于类，刚刚创建的VBO是顶点缓冲对象，
     //是GL_ARRAY_BUFFER类所定义的一个对象，但是该对象可以绑定多个缓冲类型（同类型只能绑定一个）
     //换言之每种缓冲类型的当前对象最多只能存在一个
     //因此需要GLBindBuffer来进行绑定操作，否则不懈怠任何缓冲类型属性
     //后续操作的目标是GL_ARRAY_BUFFER，实际上操作的是GL_ARRAY_BUFFER上绑定的所有VBO
     
     从这一刻起，我们使用的任何（在GL_ARRAY_BUFFER目标上的）缓冲调用都会用来配置当前绑定的缓冲（VBO）
     然后我们可以调用glBufferData函数，他会把之前定义的顶点数据复制到缓冲的内存中：
     glBufferData(GL_ARRAY_BUFFER， sizeof(vertices), vertices, GL_STATIC_DRAW);
     glBufferData是一个专门用来把用户定义的数据复制到当前绑定缓冲的函数，第一个参数是目标缓冲的
     类型：定点缓冲对象当前绑定到GL_ARRAY_BUFFER目标上，第二个参数指定传输数据局的大小（以字节为单位）；
     用一个简单地sizeof计算出顶点数据大小即可。第三个参数是我们希望发送的实际数据，第四个参数指定了
     我们希望如何管理给定的数据，有三种形式：
     GL_STATIC_DRAW ：数据不会或几乎不会改变。
     GL_DYNAMIC_DRAW：数据会被改变很多。
     GL_STREAM_DRAW ：数据每次绘制时都会改变。
     
     三角形的位置数据不会改变，每次渲染调用时都会保持原样，所以它的使用类型最好是GL_STATIC_DRAW，
     如果，比如说一个缓冲中的数据将被频繁改写，那么使用另外两个会更好一些，因为这样能够确保显卡吧数据放在能够高速写入的内存部分。
     
     现在我们已经把顶点数据储存在现存中，用VBO这个顶点缓冲对象管理。下面我们会创建一个顶点和片段
     着色器来真正处理这些数据、
     */
    GLuint VBO;  //GLuint 实际上就是GL unsigned int
    glGenBuffers(1, &VBO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    //这里操作的对象是GL_ARRAY_BUFFER。而实际上数据vertices是被装载到了VBO中
    /*顶点着色器：
     顶点着色器（vertex Shader是几个可编程着色器中的一个。如果我们打算做渲染的话，现代OpenGL需要我们
     至少设置一个顶点着色器和一个片段着色器。我们会简要介绍一下着色器和配置两个非常简单的着色器来绘制
     我们第一个三角形。
     我们需要做的第一件事就是用着色器语言GLSL（OpenGL Shader Language）编写顶点着色器，然后编译它。
     这样我们就可以在程序中使用它了。下面你会看到一个非常基础的GLSL顶点着色器代码：
     #version 330 core
     layout (location = 0) in vec3 aPos;
     
     void main()
     {
     gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
     }
     ##################
     在iOS中，你可以创建empty文件，写入这些代码，然后把后缀改为对应的vsh喝fsh
     加载方式是，
     NSString* vertFile = [[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"vsh"];
     
     vert 和 frag 是对应的empty文件的path路径NSString形式
     - (GLuint)loadShaders:(NSString *)vert frag:(NSString *)frag {
     GLuint verShader, fragShader;
     GLint program = glCreateProgram();
     //GLuint不是一个对象，不带*，
     //传递参数的时候，使用了取地址符&，传递过去的是verShader的物理内存地址。
     //在compileShader函数中，传来的内存地址被GLuint指针型参数shader储存，
     //使用的时候用*shader来表示储存到该指针所对应的内存地址
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
     
     - (void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file {
     //读取字符串
     NSString* content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
     const GLchar* source = (GLchar *)[content UTF8String];
     
     *shader = glCreateShader(type);
     glShaderSource(*shader, 1, &source, NULL);
     glCompileShader(*shader);
     }
     ###################
     */
#pragma mark 顶点着色器编译
    NSString *vertexShaderPath = [[NSBundle mainBundle]pathForResource:@"myVertexShader" ofType:@"vsh"];
    NSString *vertexContent = [NSString stringWithContentsOfFile:vertexShaderPath encoding:NSUTF8StringEncoding error:nil];
    //    NSLog(@"vsh字符串为%@",vertexContent);
    const GLchar *vertexShaderSource = (GLchar *)[vertexContent UTF8String];
    
    //    GLuint verShader = VBO;  //用于测试标识符冲突能否正常运行
    GLuint verShader;
    GLuint *verShaderp = &verShader;
    //    verShader = 10010;  //绑定以后verShader的值变化不会引起标识符的变化
    *verShaderp = glCreateShader(GL_VERTEX_SHADER); //严格复制流程结束
    glShaderSource(*verShaderp, 1, &vertexShaderSource, NULL);  //这里使用第一个参数*verShaderp（指针，指向verShader内存地址）
    //和10086（标识符，verShader值）均可编译成功，说明调用方式猜想正确
    glCompileShader(*verShaderp);  //到达这一步时，verShader中装载的应该是已经编译好的shader，与program绑定后即可使用glDeleteShader()函数销毁、
    
    
    /*
     
     可以看到，GLSL看起来很像C语言，每一个着色器都起始于一个版本声明。我们同样明确表示我们会使用
     核心模式。
     下一步，使用 in 关键字，在顶点着色器声明所有的输入顶点属性（input Vertex attribute)
     现在我们只关心位置数据（position），所以我们只需要使用一个顶点属性。GLSL有一个向量数据模型，
     它包含1-4个flaot分量，包含的数量可以从她的后缀数字看出来。由于每个顶点独有一个3D坐标
     我们就创建一个vec3输入变量aPos，我们同样也通过layout（location = 0)设定了输入变量的位置值
     
     为了设置顶点着色器的输出，我们必须吧位置数据赋值给预定义的gl_Position变量。它在幕后是vec4类型的
     在main函数的最后，我们将gl_Position设置的值作为该顶点着色器的输出。由于我们输入的是一个
     三分量的向量，我们必须把它转换为4分量的。我们可以吧vec3的数据作为vec4构造器的参数。同时把w分量
     设置为1.0f来完成。
     
     #####################
     编译着色器
     我们已经写了一个顶点着色器源代码，储存在一个C的字符串中，但是为了能够让OpenGL使用它，必须在
     运行的时候动态编译她的源代码
     我们首先要做的是创建一个着色器对象，注意还是要用ID来引用。所以我们储存这个顶点着色器为unsigned int
     然后用glcreateShader创建这个着色器。
     unsigned int vertexShader;
     vertexShader = glCreateShader(GL_VERTEX_SHADER);
     我们把需要创建的着色器类型已参数形式提供给glCreateShader、由于我们正在创建一个顶点着色器，传递的参数
     是GL_VERTEX_SHADER、
     
     下一步我们把这个着色器源代码附加到着色器对象上。然后编译他：
     glshaderSource(vertexShader, 1, &vertexShaderSource, NULL);
     glCompileShader(vertexShader);
     glShaderSource函数吧要变异的着色器对象作为第一个参数，第二个参数制定了传递的源代码字符串数量，
     这里只有一个，第三个参数㐊顶点着色器真真的个源代码，第四个参数我么你先设置为NULL
     你可能会希望检测在调用glCompileShader后编译是否承购了，如果没有的话还想知道错误是什么
     这样你才能修复他们。检测编译时错误可以通过以下代码实现：
     int success;
     char infoLog[512];
     glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &success);
     首先我们定义一个整形变量来表示是否承购编译，还定义了一个储存错误log的字符数组。然后我们用
     glGetShaderiv检查是否编译成功，如果失败，我们会用glGetShaderInfoLog获取错误信息然后打印他
     if(!success)
     {
     glGetShaderInfoLog(vertexShader, 512, NULL, infoLog);
     std::cout << "ERROR::SHADER::VERTEX::COMPILATION_FAILED\n" << infoLog << std::endl;
     }
     */
#pragma mark 检测编译成功方法无效与未设置上下文有关
    int Vertexsuccess = 999;
    glGetShaderiv(*verShaderp, GL_COMPILE_STATUS, &Vertexsuccess);
    if (Vertexsuccess) {
        NSLog(@"顶点着色器编译成功");
    }else{
        NSLog(@"顶点着色器编译失败");
        GLchar messages[256];
        glGetShaderInfoLog(*verShaderp, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
#pragma mark 片段着色器
    /*
     片段着色器(Fragment Shader)是第二个也是最后一个需要我们创建的着色器。
     片段着色器所做的事计算像素最后的颜色输出。为了让事情更简单我们的片段着色器会一直输出橘黄色
     
     在计算机图形中颜色被表示为有四个元素的数组：红色、绿色、蓝色和透明度。通常缩写为RGBA。
     当在OpenGL或者GLSL中定义一个颜色的时候，我们把颜色每个分量的强度设置到0.0到1.0之间。
     
     C语言下的片段着色器的编写方式
     #version 330 core
     out vec4 FragColor;
     
     void main()
     {
     FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
     }
     */
    NSString *fragPath = [[NSBundle mainBundle]pathForResource:@"myFragmentShader" ofType:@"fsh"];
    NSString *fragString = [NSString stringWithContentsOfFile:fragPath encoding:NSUTF8StringEncoding error:nil];
    //    NSLog(@"fsh字符串为%@",fragString);
    const GLchar* fragmentShaderSource = (GLchar *)[fragString UTF8String];
    GLuint frag;
    GLuint *fragShader = &frag;
    *fragShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(*fragShader, 1, &fragmentShaderSource, NULL);
    glCompileShader(*fragShader);
    
    GLint FragSuccess;
    glGetShaderiv(*fragShader, GL_COMPILE_STATUS, &FragSuccess);
    if (FragSuccess) {
        NSLog(@"片段着色器编译成功");
    }else{
        NSLog(@"片段着色器编译失败");
        GLchar messages[256];
        glGetShaderInfoLog(*fragShader, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    /*
     着色器程序对象(Shader Orifran Object)是多个着色器合并之后并最终连接完成的版本。
     如果要使用刚才编译的着色器我们必须把它链接(Link)成为一个着色器程序对象，然后在渲染对象的
     时候激活这个着色器程序。已经激活的着色器程序的着色器将在我们发送渲染调用的时候被使用
     
     当链接着色器到一个程序的时候，他会把每个着色器的输出链接到下一个着色器的输入。当输入和输出
     不匹配的时候，你会得到一个链接错误。
     */
    GLuint program;
    program = glCreateProgram();
    glAttachShader(program, verShader);
    glAttachShader(program, frag);
    glLinkProgram(program);
    
    //检测链接是否成功
    int linkSuccess;
    glGetProgramiv(program, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess) {
        NSLog(@"link ok");
        glUseProgram(program); //激活着色器程序
    }else{
        NSLog(@"链接错误");
        GLchar messages[256];
        glGetShaderInfoLog(*fragShader, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    /*
     在调用glUseProgram函数后，每个着色器调用和渲染调用都会使用这个程序对象
     也就是之前连接上的着色器。
     在连接完成以后可以删除着色器对象以节约资源，
     */
    glDeleteShader(verShader);
    glDeleteShader(frag);
    /*
     现在我们已经把输入顶点发送到了CPU，并指示了GPU如何在顶点和着色器中处理它。
     然后告知OpenGL如何处理这些数据，如何将顶点数据连接到顶点着色器的属性上
     */
#pragma mark 链接顶点属性
    
    /*
     顶点着色器允许我们制定任何以顶点属性为形式的输入，这是其具有很强灵活性的同时
     还意味着我们必须手动置顶输入数据的哪一个部分对应顶点着色器的哪一个定点属性。
     所以我们必须在渲染前制定OpenGL该如何解释顶点数据。
     可以参考截图：顶点缓冲数据储存格式
     位置数据被储存为32位（4字节）浮点值
     每个位置包含3个这样的值
     在这3个值之间没有空隙或者其他值。这几个值在数组中紧密排列（tightly Packed）
     数据中第一个只在缓冲开始的地方
     
     有了这些信息我们就可以使用glVertexAttribPointer函数告诉OpenGL如何解析顶点数据了
     glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat), (float *)NULL);
     glEnableVertexAttribArray(0);
     
     glVertexAttribPointerS函数参数非常多，我们会逐一介绍
     #########附上顶点着色器代码
     //attribute是应用程序传给顶点着色器用的
     
     //不允许声明时初始化
     
     //attribute限定符标记的是一种全局变量,该变量在顶点着色器中是只读（read-only）的，该变量被用作从OpenGL应用程序向顶点着色器中传递参数，因此该限定符仅能用于顶点着色器。
     attribute vec3 position;
     
     varying lowp vec2 varyTextCoord;
     
     void main()
     {
     gl_Position = vec4(position.x, position.y, position.z, 1.0);
     }
     //示例调用过程
     每一个attribute在vertexShader中毒有一个location，是用来传递数据的入口。我们可以通过下列代码获取这个入口值:
     GLuint position = glGetAttribLocation(self.myProgram, "position");
     glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, NULL);
     glEnableVertexAttribArray(position);
     GLSL基础语法链接http://www.tuicool.com/articles/yEBFvmA
     */
    GLuint position = glGetAttribLocation(program, "position");
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 3, NULL);
    /*
     glVertexAttribPointer函数的参数非常多，逐一介绍如下：
     第一个参数制定我们要配置的定点属性（vsh文件中的attribute属性名）
     第二个参数指定定点属性的大小，定点属性是一个vec3，由三个值组成，所以大小是3
     第三个参数指定数据类型，这里是浮点数 GL_FLOAT
     第四个参数定义我们是否希望数据被标准化（Normailze）如果我们设置为GL_TRUE，所有的数据都会被
     映射到-1到1之间（屏幕标准坐标值）因此设置为GL_FALSE
     第五个参数叫步长（stride），指定连续的定点属性组之间的间隔。由于这里每一个顶点数据是十三个float值
     所以步长值设定为sizeof(FLfloat) * 3，我们可以将这里这是为0来让OpenGL决定具体步长是多少
     （只有数值紧密排列时才可以用），一旦我们有更多的定点属性，就必须小心的定义步长值
     最后一个参数是起始位置的偏移量，表示位置数据在缓冲中起始位置的偏移量
     
     每个定点属性从VBO管理的内存中过去到他的数据，具体从哪个VBO获取则是在调用glVetexAttribPointer
     时绑定到GL_ARRAY_BUFFER的VBO决定的。
     由于在调用glVetexAttribPointer之前绑定的是先前定义的VBO对象，定点属性position会连接到他的数据
     */
    glEnableVertexAttribArray(position);
    
    /*
     现在我们已经定义了OpenGL如何解释顶点数据，现在应该使用glEnableVertexAttribArray函数，
     以顶点属性位置值为参数，启用定点属性。定点属性默认是禁用的。
     
     到这里所有东西已经设置好，我们使用一个顶点缓冲对象VBO将顶点数据初始化到了缓存中，建立了顶点着色器和
     片段着色器，并告诉了OpenGL如何吧顶点数据连接到顶点着色器的定点属性上。在OpenGL中绘制一个物体，
     代码是这样的
     #############注意，这里的代码是C环境
     // 0. 复制顶点数组到缓冲中供OpenGL使用
     glBindBuffer(GL_ARRAY_BUFFER, VBO);
     glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
     // 1. 设置顶点属性指针
     glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0);
     glEnableVertexAttribArray(0);
     // 2. 当我们渲染一个物体时要使用着色器程序
     glUseProgram(shaderProgram);
     // 3. 绘制物体
     someOpenGLFunctionThatDrawsOurTriangle();
     */
    glViewport(0, 0, 414, 736); //设置视口大小
    glDrawArrays(GL_TRIANGLES, 0, 6);
    [context presentRenderbuffer:GL_RENDERBUFFER];
    
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
