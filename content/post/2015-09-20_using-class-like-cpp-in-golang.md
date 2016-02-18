+++
Categories = ["码农向"]
Tags = ["golang"]
date = "2015-09-20T21:05:59+08:00"
title = "在golang中使用C++风格的类"

+++

对于接触过C++且刚入门golang的用户而言，有一点可能会让他们抓狂，
就是golang这货居然只有结构体（struct），没有类（class）！！！  
其实不用担心，我们大可以用struct实现类似于class的功能。。。

<!--more-->

##### <b>目的：</b>
******
使struct不仅仅能存储成员变量，还能拥有其成员函数。并且控制外部函数对私有成员变量的访问。
当然本文仅仅是为了实现上述目的而已，并不关心什么多态、继承等等一大堆乱七八糟的特性（好吧，其实是本渣并不懂那些高级特性）。

##### <b>C++中类的使用：</b>
******
我们先来看一段C++中是怎么样使用类的。  
首先我们来创建一个头文件`classa.h`，如你所见，类名叫classa：  
``` cpp
class classa {
private:
	int id;

public:
	void SetID(int);
	int GetID();
};
```
然后我们再创建一个源文件`classa.cpp`，用来实现classa的`SetID`和`GetID`方法：
``` cpp
#include "classa.h"

void classa::SetID(int newid) {
	this->id = newid;
}

int classa::GetID() {
	return this->id;
}
```
最后，建立`main.cpp`用来初始化一个类的实例，并尝试调用类中的方法：
``` cpp
#include <iostream>
#include "classa.h"

using namespace std;

int main(int argc, char* argv[]) {
	classa ca;
	ca.SetID(4);
	cout << ca.GetID() << endl;
	return 0;
}
```
使用`g++ -o main main.cpp classa.cpp`编译上述文件，并运行`./main`，
如果输出了一个数字4，那这个classa类就应当是以正确的姿势被调用了。

##### <b>golang中为struct添加成员函数</b>
******
不多废话了，作为对比，我们把上述C++代码翻译成golang代码。  
假定我们目前的工作目录为`GOPATH`，我们在当前路径的子目录下创建一个
名叫`packagea`的包，包文件在`GOPATH`下的路径为`src/packagea/packagea.go`，
内容如下：
``` go
package packagea

type StructClass struct {
	id int 
}

func (this *StructClass) SetID(newid int) {
	this.id = newid
}

func (this *StructClass) GetID() int {
	return this.id
}
```
同样，编写`main`包以使用`packagea`包，`main`包的位置应该在哪就不用多说了吧。  
`main`包的内容如下：
``` go
package main

import (
	"fmt"
	"packagea"
)

func main() {
	var (
		sc packagea.StructClass = packagea.StructClass{}
	)
	sc.SetID(4)
	fmt.Println(sc.GetID())
}
```
*为了便于新手（其实是我自己）理解，我尽量不会使用`:=`来声明一个变量，
而是使用臭长臭长的显式声明，以容易对变量的类型一目了然。*  
如果你希望以指向结构体的指针的形式来声明`sc`这个结构体，只需把
`sc packagea.StructClass = packagea.StructClass{}`替换为
`sc *packagea.StructClass = &packagea.StructClass{}`即可。

##### <b>总结</b>
******
之前网上找的教程基本上都是把结构体和跟它们关联的函数放在`main.go`（与方法调用者
在同一个包里）。
如果我们希望把它们模块化，当然需要把一个模块的东西放到单独的包中。这个时候需要
注意的是，小写字母开头的变量和方法都只能在同一个包中被使用，类似于C++类
中的`protect`属性。至于`private`属性？你把每个结构体以及它们关联的方法单独放到
一个包不久行了。。。  
本文所说的这种用法其实应该是go里面很常见的用法，只是本人愚笨，搞了好久才搞清楚。
所以在这里记录一下，以便以后哪天又忘了的话可以翻阅。。。

