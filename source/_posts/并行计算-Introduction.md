---
title: 并行计算-Introduction
date: 2024-03-26 14:24:04
tags: 并行计算
math: true
---
# Acknowledgement

The content of this post is based on a summary of the Parallel systems (COMP8300) course at the Australian National University,
which I have greatly benefited from. Thanks to lecturers Dr. Alberto F. Martin, Prof. John Taylor.

# Introduction
## Parallel computing: concept and rationale
### The idea:

Split computation into tasks that can be executed simultaneously on diffrerent processors.

### Motivation:

**Speed** at a cost-effective price.

Reduce the time to solution to acceptable levels.

Tackle larger-scale.

Keep power consumption and heat dissipation under control.

### Parallel programming:
the art of writing the parallel code
### Parallel computer:
the hardware on which we run our parallel code

## Scales of parallelism
(* requires significant parallel programming effort)
### Within a CPU/core:
pipelined instruction execution, multiple instruction issue (super-scalar 超标量), other forms of instruction level parallelism, SIMD  (Single Instruction Multiple Data) units*

### Within a chip: 
multiple cores*, hardware multithreading*, accelerator units* (with multiple cores), transactional memory (事务内存)*

### Within a node:
multiple sockets* (CPU chips), interleaved memory access (multiple DRAM chips), disk block striping / RAID (multiple disks)

### Within s SAN (system area network):
multiple nodes* (clusters, typical supercomputers), parallel filesystems

### Within the internet:
grid/cloud computing*

## Moore's Law & Dennard Scaling
Two "laws" underpin exponential performance increase of microprocessors

### Moore's Law
> Transistor density will double approximately every two years.

### Dennard Scaling
> As MOSFET features shrink. switching time and power consumption will fall proportionately.

> MOSFET（Metal Oxide Semiconductor Field Effect Transistor-金属氧化物半导体场效应晶体管）

The (dynamic) power consumption of a chip can be modelled as:
$$
P = QfCV^2
$$
where ***Q*** # of transistors, ***f*** frequency, ***C*** capacitance, and ***V*** voltage apply. 

#### Dennard's scaling law (until early 2000s)
According to Dennard's law, if we scale feature size down by a factor of $\dfrac{1}{\kappa}$, we can scale up frequency by $\kappa$, and scale down the capacitance and voltage by $\dfrac{1}{\kappa}$, resulting in a **reduced** power consumptiong of assuming $Q_\kappa = \kappa^2Q_0$ :
$$
P_0 = Q_0f_0C_0V_0^2\to Q_\kappa f_\kappa C_\kappa V_\kappa^2 = Q_0 (\kappa f_0)(\dfrac{1}{\kappa}C_0)(\dfrac{1}{\kappa}V_0)^2 = (\dfrac{1}{\kappa^2})P_0
$$
If we allow ourselves to keep $P_\kappa$ a constance, the number of transistors $Q_\kappa$ we can fit on the same chip is:
$$
Q_\kappa = \kappa^2 Q_0
$$
As long as we keep scaling feature size down by $\dfrac{1}{\kappa}$, we can fit $\kappa^2$ more transistors on the same chip, increase their frequency by $\kappa$, and use the same power as before.

#### The end of Dennard scaling and uni-processor era (2002-2004)
With feature size below $\approx 100nm$ (nowadays around $\approx 10 mn$), we have that:
$$
P = QfCV^2 + VI_{\text{leakage}}
$$
(Note: for "large enough" feature size, the term **$VI_{\text{leakage}}$** is negligible.)

Unfortunately, $I_{\text{leakage}}$ grows exponentially with downscaled $V$ as we decrease feature size by $\dfrac{1}{\kappa}$. Thus, the term $VI_{\text{leakage}}$ blows up and dominates power consumption.

To keep power under control, large number of transistors are switched off (dark silicon effect), operated at lower frequencies (dim silicon effect) or organized in different ways.

## Why parallel programming is hard
- Writing (correct and efficient) parallel programs is hard
- Getting (close to ideal) speed up is hard. Overheads include:
  - idling (e.g. caused by load unbalance, synchronization, serial sections, etc.)
  - redundant / extra operations when splitting a computation into tasks
  - communication time among processes
- Amdahl's Law (阿姆达尔定律):
  - Let $f$ the fraction of a computation that cannot be split into parallel tasks. Then, max speed up achievable for arbitraty large $p$ processors is $\dfrac{1}{f}$.

[阿姆达尔定律](https://hackernoon.com/zh/%E6%B7%B1%E5%85%A5%E7%A0%94%E7%A9%B6%E9%98%BF%E5%A7%86%E8%BE%BE%E5%B0%94%E5%AE%9A%E5%BE%8B%E5%92%8C%E5%8F%A4%E6%96%AF%E5%A1%94%E5%A4%AB%E6%A3%AE%E5%AE%9A%E5%BE%8B)

- Counterargument (Gustafson's Law):
  - $1-f$ is not fixed, but increases with the data/problem size $N$
  - This law says that increase of problem size for large machines can retain scalability with
respect to the number of processors.