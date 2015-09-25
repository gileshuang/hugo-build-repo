+++
Categories = ["码农向"]
Tags = ["golang"]
date = "2015-09-25T11:13:06+08:00"
title = "golang中对slice切片进行append时的内存拷贝"

+++

Golang中有一个神奇的类型：slice。  
之所以说它神奇，是因为它是有容量的，因此对于熟悉C语言的用户而言，
很难在C语言中找到一个跟slice对应的数据结构。  
本文不对slice的众多特性进行说明，只谈论跟其append操作相关的内容。

<!--more-->

##### <b>Slice的长度与容量</b>
******
数组切片 slice 本质上还是基于数组实现的，大概可以抽象为：一个指向原生数组的指针；
数组切片中的元素个数；数组切片已分配的存储空间。  
既然是基于数组，数组本身是不可变长度的，而要实现可变长度，就需要对其存储空间
进行管理。那 go 是怎么对 slice 的存储空间进行管理的呢？  
这时就需要注意到 slice 的中文名称了，数组切片。也就是说，go 本质上将数组弄成一个个
切片，当目前所包含的切片容量不足以容纳所需的元素的时候，就开辟一块新的切片。  
因此，除了长度（length，用`len()`函数获取）之外，slice 还包含了另一个属性：容量
（capacity，用`cap()`函数获取）。Slice 的长度表示该 slice 中已经存放了多少个元素，
而容量则表示该 slice 已经分配了足以存放多少元素的空间。  
我们可以用一下方法创建一个长度为 4、可容量为 8、用于存放 int 类型元素的 slice：
``` go
var sliceA []int = make([]int, 4, 8)
```
当我们不指定 make() 的第三个参数 cap 时，切片容量默认等于初始长度，如以下方法可
创建一个长度和容量都为 8 的 slice：
``` go
var sliceB []int = make([]int, 8)
```

##### <b>使用 append() 方法添加元素</b>
******
前面说过 slice 是可变长度的，我们可以利用 append() 函数来为 slice 增加元素。  
*前面也说过，本文只讨论 append() 方法，不讨论取子切片、copy() 等其它操作。*  
那么，作为以数组为基础的数据结构，它是怎么做到动态扩展长度的呢？其实就是通过创建
并合并新的切片。  
为了方便讨论，我们姑且把初始化时数组切片的容量称为它的单位容量。<b>请注意这一说法是
无论在 Google 官方文档还是国内翻译文档都未见使用，仅是为了方便讨论论是创造的。</b>  
当进行 append() 操作时，若当前容量足以容纳所有元素，则 append() 会直接把需要添加的
元素直接拷贝到当前已分配的空间内，已有的数据还都在原处，皆大欢喜。而且因为空间是预先
分配好的，不涉及多余的内存申请操作，因此能兼顾动态扩展的灵活性和预分配空间的效率。  
然而，如果当前空间不足的话，又会怎么样呢？  
如果遇到这种情况，append() 会尝试先给这个 slice 分配一个大小为一个单位容量的数组，
如果还不够，继续分配。  

这个时候<b>坑来了，坑来了，坑来了</b>，重要的事情据说要说三遍。。。  
append() 在为 slice 增加容量的时候，会创建新的 slice，然后把<b>已有的数据拷贝过去，
拷贝过去，拷贝了过去</b>，因为我掉到过这个坑，所以还是要说三遍。。。  
也就是说，不管你对已存在的数据有没有进行修改，它都要拷贝一遍。如果你认为这个拷贝操作
仅仅是多消耗了一些性能的话，那我们看看下面的例子：
``` go
package main

import (
	"fmt"
	"time"
)

type StructClass struct {
	id int
}

func (this *StructClass) SetID(newid int) {
	this.id = newid
}

func (this *StructClass) PrintID() {
	go func() {
		for {
			// 每秒输出一次 id 值。
			time.Sleep(time.Second * 1)
			fmt.Println(this.id)
		}
	} ()
}

func main() {
	var (
		i int = 0
		pool []StructClass = make([]StructClass, 0, 4)
	)
	pool = append(pool, StructClass{})
	// 这里将 pool[0] 的 id 设置成 1 了。
	pool[0].SetID(1)
	// 启动一个 goroutine，反复输出 pool[0] 的 id。
	pool[0].PrintID()

	time.Sleep(time.Second * 5)
	for i = 0; i <=5; i = i + 1 {
		pool = append(pool, StructClass{})
	}
	// 请注意此时 pool[0] 的 id 被设置成了 2。
	pool[0].SetID(2)
	time.Sleep(time.Second * 5)
}
```
我们先来分析一下程序应该怎么运行。  
首先创建了一个容量为 4，长度为 0 的 slice，该 slice 的每个元素都是一个封装了
一个 goroutine 的结构体。至于怎么制造这么一个结构体，
请参考[《在golang中使用C++风格的类》](/2015/09/20/using-class-like-cpp-in-golang/)一文。
这时，我们为 pool 添加了一个元素，并为这个元素的成员`id`赋予初值，然后让它下属
的 PrintID 方法每隔一秒打印一次它的`id`值。  
紧接着，我们为 pool 添加了六个元素，不过暂时不对它们进行操作。添加这六个元素的目的仅仅
是为了迫使 append() 方法为 pool 添加一块区域。  
大约五秒钟后，我们将 pool[0] 的`id`设置为2，并等待其输出五秒后退出。  

按道理来说，`pool[0].SetID(2)`之后，程序应该是反复输出数字2，然而运行的结果是，程序
全程只输出数字1。  
<b>原因是</b>，当 slice 元素个数超过四个时，append() 会分配一块大小为 8 的空间，
然后把所有元素拷贝进去。虽然 slice 本身是一个指向数组的指针，但它包含的元素都是
实实在在的数据。在这个例子中，拷贝数据时，append() 实实在在地把 pool[0] 的 id 以及各函数的
定义都拷贝过去了，但正在运行的 goroutine 并不属于数据，因此本例中的那个正在运行
的 goroutine 还傻傻地去原来的地方读取 id 值（注意，此处读取 id 用的是指向结构体的指针，
该指针还是指向原来的数据）。  

##### <b>代码修正</b>
******
既然我们知道了引发问题的原因，那事情也就好解决了。  
我们只需在创建 slice 的时候，往里面存放指向 StructClass 的指针，而不是直接
存放 StructClass 结构体就行了。
上述代码其它部分保持不变，将`main`函数修改为如下：
``` go
func main() {
	var (
		i int = 0
		pool []*StructClass = make([]*StructClass, 0, 4)	// 改了这行
	)
	pool = append(pool, new(StructClass))	// 还有这行
	// 这里将 pool[0] 的 id 设置成 1 了。
	pool[0].SetID(1)
	// 启动一个 goroutine，反复输出 pool[0] 的 id。
	pool[0].PrintID()

	time.Sleep(time.Second * 5)
	for i = 0; i <=5; i = i + 1 {
		pool = append(pool, new(StructClass))	// 还有这行
	}
	// 请注意此时 pool[0] 的 id 被设置成了 2。
	pool[0].SetID(2)
	time.Sleep(time.Second * 5)
}
```
因为我懒，所以上述代码的运行结果我都懒得贴了。感兴趣的可以自己测试一下，修改后
的代码正如我们期望的那样，先输出1，五秒后输出2。  
若 slice 存放的是指针，那在 append() 进行拷贝操作的时候，只是将指针的指向的地址拷贝过去，
`pool[0].SetID(2)`语句修改的 id 和`pool[0].PrintID()`取的 id 引用的地址始终是不变的。  

#### 所以说，谁说带垃圾回收的语言不用考虑指针T\_T

