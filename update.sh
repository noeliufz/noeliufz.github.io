#!/bin/sh

#!/bin/bash

hexo clean
hexo g

# 构建命令
# command="pyftsubset source/fonts/MicrosoftJhengHei-full.ttf"
command="pyftsubset source/fonts/KingHwa-full.ttf"

# 递归查找 HTML 文件并作为参数添加到命令中

find public -type f -name "*.html" -exec printf -- "--text-file=\"%s\" " {} + | tee /dev/tty | xargs $command
