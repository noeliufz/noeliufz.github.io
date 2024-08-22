---
title: Nes模拟器6502CPU的Debug
date: 2024-06-29T10:30:47.000Z
tags: debug
---
最近在跟着[NES ebook](https://bugzmanov.github.io/nes_ebook/chapter_1.html)写NES模拟器。项目是用Rust写的，但是我想锻炼一下自己的C++能力就按照思路自己用C++写。

昨日写完6502 CPU的部分，用p6502汇编的代码的[贪吃蛇 by wkjagt](https://gist.github.com/wkjagt/9043907)进行测试，但会有奇怪的bug。

bug表现为按下按键后，如果方向改为上或下，蛇的位置会固定刷新在一个奇怪的位置，增长速度也会快，会正常撞墙结束游戏，但是恢复在左右方向就会正常。如图是按下方向上后的蛇的位置（白点处）。

![bug](/img/nes/bug.png)

另外，奖励的苹果的位置大多时间显示不出来，运行了几十次会有一两次能正常显示且颜色正常变化。

想着这快2000行代码那么多条指令也不知道到底出现问题在哪里，为了避免盲目检查，先分析一下问题。

看了原始的汇编代码的游戏逻辑和内存分布。

`$00-01`为存储苹果位置的地址，打印发现内容正常。

`$10-11`为存储蛇头位置的地址，发现在按下方向键后会重置为0，可疑。

`$02`为目前方向，发现在按下按键后能正常变化。

`$03`为蛇长，一切正常。

游戏主逻辑为

```ASSEMBLY
loop:
  ;the main game loop
  jsr readKeys         ;jump to subroutine readKeys
  jsr checkCollision   ;jump to subroutine checkCollision
  jsr updateSnake      ;jump to subroutine updateSnake
  jsr drawApple        ;jump to subroutine drawApple
  jsr drawSnake        ;jump to subroutine drawSnake
  jsr spinWheels       ;jump to subroutine spinWheels
  jmp loop             ;jump to loop (this is what makes it loop)
```

根据上面的分析可知`readKeys`正常。结合游戏表现，撞墙能正常结束游戏，`checkCollision`应该也是正常的。在改变方向前，蛇的增长也是正常的，`updateSnake`不确定是否有问题。苹果大多时间不能显示但也有能显示出的时候，且能显示的时候表现是正常的，`drawApple`可能会有问题但应该不是主要问题。蛇显示都是正常的，只是位置更新有问题`drawSnake`应该是没有问题的。

分析后思路更清晰了，感觉应该是在`updateSnake`中改变方向后的问题，结合之前发现`$10`存储蛇头位置的地址数值会在方向改变之后清零，去看了下操作`$10`地址值的代码有哪些。

在`updateSnake`中会进入`updateloop`循环，其中会根据方向进入不同分支。观察分支代码，只有上下方向会调用`sta $10`对地址`$10`进行操作（将`a`寄存器的值存入地址`$10`），与我这个bug只会在上下方向出问题一样。

检查代码

```ASSEMBLY
up:
  lda $10   ;put value stored at address $10 (the least significant byte, meaning the
            ;position in a 8x32 strip) in register A
  sec       ;set carry flag
  sbc #$20  ;Subtract with Carry: subtract hex $20 (dec 32) together with the NOT of the
            ;carry bit from value in register A. If overflow occurs the carry bit is clear.
            ;This moves the snake up one row in its strip and checks for overflow
  sta $10   ;store value of register A at address $10 (the least significant byte
            ;of the head's position)
  bcc upup  ;If the carry flag is clear, we had an overflow because of the subtraction,
            ;so we need to move to the strip above the current one
  rts       ;return
```

发现在`sta`之前会先执行`sbc`操作（Substract with Borrow，带借位减法）对寄存器`a`进行更新，检查一下自己`sbc`操作的代码果然有问题！问题在于每次计算完成后调用了一个helper function还会再对carry bit进行一次计算导致寄存器`a`的值异常。改好后就能成功运行啦！蛇的运行也正常了，苹果也都能显示出来了，玩了一会一切正常！

改后长这样

```cpp
void CPU::SBC(const AddressingMode &mode)
{
    // A - M - C̅ -> A
    uint16_t addr = get_operand_address(mode);
    uint8_t data = read(addr);

    uint16_t value = static_cast<uint16_t>(data);
    uint16_t carry_in = get_flag(C) ? 0 : 1;
    uint16_t result = static_cast<uint16_t>(registers.a) - value - carry_in;

    registers.a = static_cast<uint8_t>(result & 0xFF);

    set_flag(N, registers.a & 0x80);
    set_flag(Z, registers.a == 0);
    set_flag(C, result < 0x100);
    set_flag(V, ((registers.a ^ result) & (registers.a ^ data) & 0x80) != 0);
}
```

![正常运行](/img/nes/normal.png)

本以为要对着这2000行代码发呆无从下手，分析一下定位问题后解决还挺快的，就是正确定位bug更难哇！

