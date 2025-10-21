---
title: Arch Linux安装（自用）
date: 2024-12-16T20:15:36.000Z
tags: Arch
---
# ArchLinux安装方法
制作镜像略

# 进入系统后

## 连接网络

```sh
iwctl
device list
station wlan0 scan
station wlan0 get-networks
station wlan0 connect <name>
```

## 换源
`reflector --country China --latest 10 --sort rate --save /etc/pacman.d/mirrorlist`

后续脚本中不再换源

## 使用`archinstall`脚本
注意挂载`efi`为`/boot`

## （出现意外）修复grub
挂载`/`到`/mnt`
挂载`efi`为`/boot`

```sh
mount -t proc /proc /mnt/proc
mount --rbind /sys /mnt/sys
mount --rbind /dev /mnt/dev
mount --rbind /run /mnt/run
# 进入新系统
arch-chroot /mnt
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
efibootmgr --create --disk /dev/nvme0n1p1 --part 1 --label "Arch" --loader /EFI/GRUB/grubx64.efi
# 最后一句中实际文件是在/boot/EFI/GRUB/grubx64.efi中，但不要加/boot
```

# 安装Hyprland
使用已有配置库Hyprdots安装

# 关闭内置显示器
`hyprctl keyword monitor "eDP-1,disable"`
`hyprctl keyword monitor "HDMI-A-1,1920x1080@75,0x0,1.0”`

# 防止合盖睡眠
修改`/etc/systemd/login.conf`中`HandleLidSwitch`系列值为`ignore`

# 修复Hyprland下微信无法使用fcitx5
arch Linux AUR中已有官方微信`wechat-bin`

在`/etc/environment`中添加`QT_IM_MODULE=fcitx`

