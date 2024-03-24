---
title: 记第一次帮别人debug Node.js的经历
date: 2024-03-23 19:44:16
tags: debug
---
学校有门项目课（非常水），接手了上一组的（垃圾）代码，用electron和Node.js写的。

（拜）读了一下午代码终于理清逻辑了，写的真的是乱七八糟，1000行代码放一个Js里，也是服了。大概给分了下组，然后在此基础上写了个认证缓存也很快就写完了。

另个同学要加一个新的日历视图进去，弄半天弄不好找我来debug。

他是要在显示界面上引入第三方包，于是在js里写的

``` javascript
const FullCalendar = require('@fullcalendar/core');
const dayGridPlugin = require('@fullcalendar/daygrid');
```

运行后按command+shift+i查看控制台，错误：

`dashboard.js:1 Uncaught ReferenceError: require is not defined`

疯狂谷歌，发现是因为electron是有两个进程，一个main进程一个renderer进程。默认main进程是使用的Node.js，而rendered进程是无法使用Node的，所以就会出现require无法使用的情况。

解决：

在main.js创建窗口的时候加入两个新的开关
``` javascript
mainWindow = new BrowserWindow({
    width: 800,
    height: 600,
    webPreferences: { 
		nodeIntegration: true,		// 打开允许在renderer进程使用node
        contextIsolation: false,		// 关闭上下文隔离
        preload: path.join(__dirname, "preload.js") },
});

```
之前的代码是开启上下文隔离的，官方解释

> 上下文隔离功能将确保您的 预加载脚本 和 Electron的内部逻辑 运行在所加载的 [webcontent](https://www.electronjs.org/zh/docs/latest/api/web-contents)网页 之外的另一个独立的上下文环境里。

为了安全在Electron 20之后也是默认开启的，但为了引入只能先关闭了。

在之前开启隔离的时候，上下文通信是使用`ContextBridge`实现api传递的

例：
``` javascript
contextBridge.exposeInMainWorld('api_name', {
    sendLoginMessage: () => {
        ipcRenderer.send('LOGIN');
    },
	// other apis
});

```
关闭隔离后`ContextBridge`就无法使用了，改为
``` javascript
window.api_name = {
    sendLoginMessage: () => {
        ipcRenderer.send('LOGIN');
    },
	// other apis
});
```

新问题：

运行后之前的（垃圾）代码有些属性会说undefined。错误信息`Uncaught TypeError: Cannot read properties of undefined (reading 'email')`

代码：
``` javascript
function isNoteSaved() {
  var file = {
    // ...
    currentEmail: this.email.textContent
  }
  // ...
}
```

定义在

```javascript
const email = document.getElementById("email");
```

摸索半天，解决把this去掉，应该是与关闭上下文隔离有关。

新问题：

不会出现其他问题了，也能正确require了，但是还是会有报错

`Uncaught SyntaxError: Cannot use import statement outside a module (at main.js:6:1)`

查看到不是自己的`main.js`而是要导入的`fullcalendar`的`main.js`，点进去看，错误行：

``` javascript
import './vdom.js';
```

查询才发现Js还分CommonJs和Es（行……），最主要的语法层面的区别就是import和export的使用上。也不想再继续写JavaScript了，也就了解了下CommonJs使用require导入，Es使用import导入。Es也没有`__dirname`这个变量。

更详细的说明可见博文：[Node.js 如何处理 ES6 模块 - 阮一峰的网络日志](https://www.ruanyifeng.com/blog/2020/08/how-nodejs-use-es6-module.html)

简单说要导入的包可能用了Es语法格式的导入（在自己的代码中），所以和目前electron没有开启Es支持的CommonJs里不兼容。

尝试在`package.json`中打开`”type”: “module”`，按Es格式更改后还是不行，直接是electron层面的报错，谷歌一下是electron就是不支持Es和module，只能放弃，另寻支持的module。

同学换了一个使用`jQeury`的calendar module，一切正常但一直报错`Uncaught ReferenceError: jQuery is not defined`，但在Js里已经定义了

``` javascript
window.$ = window.jQuery = require('jquery');
```

寻找半天终于发现，是自己写的Js放在了导入module的Js之后。调整下顺序，解决。

折腾半天终于可以在electron里用一个第三方的日历库显示日历样式。

第一次写Js，但再也不想写Js了。嗯。

