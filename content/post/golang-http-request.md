+++
Categories = ["码农向"]
Tags = ["golang"]
date = "2016-01-12T18:05:00+08:00"
title = "golang发送http请求"

+++

本篇记录一下golang中发送一个http请求的基本方法。  
在本例中，我将尝试向某个URL发送GET请求，并获取其返回的body。  

<!--more-->

##### <b>开门见山的示例代码</b>
******

``` go
import (
	"os"
	"fmt"
	"net/http"
	"io/ioutil"
)

func GetHttpBody(str_api string) ([]byte) {
	const (
		Http_username = "apiuser"
		Http_passwd = "apipasswd"
	)

	client := &http.Client{}
	req, err_req := http.NewRequest("GET", str_api, nil)
	if err_req != nil {
		fmt.Println("Can't add http request.", err_req)
		os.Exit(1)
	}
	req.Header.Add("Accept", "application/json")
	req.SetBasicAuth(Http_username, Http_passwd)

	resp, err_resp := client.Do(req)
	if err_req != nil {
		fmt.Println("Can't get http response.", err_resp)
		os.Exit(1)
	}
	resp_body, _ := ioutil.ReadAll(resp.Body)
	defer resp.Body.Close()
	return resp_body
}
```

##### <b>为了防止自己不懂，尝试解释一下</b>
******

*该实例是将go作为http客户端来用，而不是作为server。*  

``` go
client := &http.Client{}
```

首先需要创建一个http client。其实我也不知道为什么是这么创建的。创建http客户端的时候，
还可以控制它的重定向策略等等行为以及其它客户端设置。由于我自己对http协议基本不怎么了解，
所以就不去深究它还能加哪些控制方法了。  
接着便是新建一个`http.Request`。其中`http.Request.Header.Add`给这个请求添加一条
http头。`http.Request.SetBasicAuth`方法用来做基于http协议的、明文密码的基本身份认证。
`http.Request`的第一个参数为http请求的方法，第二个参数为请求的URL，如果是`POST`等
方法，则可以在第三个参数加上要POST的内容。第三个参数的类型为`io.Reader`。
`client.DO`将上面创建好的请求发送出去，并返回一个`http.Response`，于是我们就可以通过
`http.Response.Body`获取到服务器返回的http body。  
`http.Response.Body`作为一个`io.Reader`，记得在读取完成后`Close`掉。

皆大欢喜皆大欢喜。。。
