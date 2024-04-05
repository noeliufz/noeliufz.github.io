---
title: Hexo Fluid主题使用Python库fonttools压缩字体
date: 2024-04-05 17:38:42
tags:
  - 博客搭建
excerpt: Hexo Fluid主题使用font-spider遇到一些问题，最后选择使用Python库fonttools压缩字体
---
博客想使用第三方字体，奈何字体体积很大，部署后发现加载速度太慢。

尝试使用Node的包font-spider进行字体压缩，但由于使用的主题（fluid）会引入第三方css，其中又会引入自己其他的css，在其中路径是`//at.alicdn.com/...`的格式，会导致font-spider出现`web font not found`和错误，说路径上的文件不存在。应该是把在线格式理解成本地格式了，故放弃使用font-spider。

之后发现font-spider是用fontmin实现的，下载安装后又出现Node的EsJs和CommonJs引入包语法不一样的问题，不想折腾直接放弃。

之后又发现Python包fonttools也可以实现字体压缩，也是用保留字体中指定文字子集的方法，下载尝试后解决问题。

fonttools安装
```shell
pip install fonttools
```

详细使用方法可
```shell
pyftsubset --help
```

其中一种方法是指定文件中的文本，在原字体文件夹下生成一个比原文件名多一个`.subset`的字体文件。
```shell
pyftsubset font-file --text-file=<path>
```

在hexo博客生成后，简单粗暴让字体只保留`public/`文件夹下所有html文件中的文字，于是（让ChatGPT）写一个shell脚本：
```shell
#!/bin/sh   
  
hexo clean  
hexo g  
  
# 构建命令  
command="pyftsubset source/fonts/字体文件.ttf"  
  
# 递归查找 HTML 文件并作为参数添加到命令中  
find public -type f -name "*.html" -exec printf -- "--text-file=\"%s\" " {} + | xargs $command
```
原字体文件保存在`source/fonts`下，在同文件夹下会生成一个`字体文件.subset.ttf`的文件。

在`source/css`下创建一个`custom.css`，将字体指定为新字体文件。
```css
@font-face {  
  font-family: "字体家族名";  
  src: url("字体文件.subset.ttf") format('truetype'),  
}
```
在fluid主题设置`_config.fluid.yml`中指定custom css
```yml
custom_css: "./css/custom.css"
```
同样指定全局字体
```yml
font:  
  font_size: 16px  
  font_family: 字体家族名
  letter_spacing: 0.02em  
  code_font_size: 85%
```

一切搞定，每次更新后运行一下脚本，压缩后字体大小从21M降到300k。
