# 多阶段编程 (Multi-stage Programming, MSP) 与 MDTT

本文旨在通过“计算的阶段分离”这一视角，解释多阶段编程的概念、现状以及 MDTT 项目在其中的独特定位。

## 1. 什么是 “多阶段编程” (MSP)？

在传统的编译原理中，我们通常只有两个阶段：**编译时 (Compile-time)** 和 **运行时 (Run-time)**。

**多阶段编程 (MSP)** 是一种编程范式，它允许程序员明确地控制计算发生的“时间点”。它通过将程序分层，使得前一阶段的计算可以生成、优化或特化下一阶段的代码。

### 核心概念
*   **Staging (分阶)**: 区分“现在执行的代码”（Static/Host）和“未来执行的代码”（Dynamic/Target）。
*   **Code Generation (代码生成)**: 程序不仅仅处理数据，还处理“代码片段”。
*   **Type Safety (类型安全)**: 与简单的字符串拼接或宏（Macro）不同，MSP 强调在生成代码时就保证生成出的代码是类型安全的 (Well-typed)。

### Haskell 视角的类比
如果说普通编程是编写函数 $f: A \to B$ ，那么 MSP 就是编写函数 $f: A \to \text{Code}\langle B \rangle$。你不是直接计算结果，而是计算“计算结果的代码”。

---

## 2. 目前有哪些产品和实践？

工业界和学术界有许多成熟的 MSP 实现，它们主要分为两类：**同构 (Homogeneous)** 和 **异构 (Heterogeneous)**。

### A. MetaOCaml (最经典的 MSP 实现)
*   **类型**: 同构 (OCaml 生成 OCaml)。
*   **特点**: 引入了 `.< ... >.` (Brackets, 引用代码) 和 `.~( ... )` (Escape, 拼接代码) 操作符。
*   **实践**: 用于高性能计算（如 FFT 算法生成），通过消除运行时开销来获得极致性能。

### B. Template Haskell (Haskell 的元编程)
*   **类型**: 主要是编译期元编程。
*   **特点**: 允许在编译期间运行 Haskell 代码来生成 Haskell AST。
*   **实践**: `Yesod` 框架用于生成路由代码，`Lens` 库用于生成存取器。它更多关注“减少样板代码”而非“运行时特化”。

### C. Scala LMS (Lightweight Modular Staging)
*   **类型**: 嵌入式 DSL (Domain Specific Language)。
*   **特点**: 利用 Scala 的类型系统在运行时构建操作图，然后生成 C 或 Scala 代码。
*   **实践**: 用于大数据处理 (Spark 的 Catalyst 优化器采用了类似思想) 和 AI 编译器。

### D. Terra (Lua + C) / Halide (C++ DSL)
*   **类型**: 异构 (主要用于高性能图像处理)。
*   **实践**: **Halide** 是最成功的案例之一，它分离了“算法描述”和“调度策略”，通过多阶段编译生成高度优化的图像处理流水线。

---

## 3. MDTT (本项目) 与它们的区别和联系

MDTT 在现有的 MSP 基础上，引入了 **异构 (Heterogeneity)** 和 **依赖类型 (Dependent Types)** 的结合，这使它在理论高度和应用场景上有所不同。

### 区别一：显式的异构性 (Explicit Heterogeneity)
*   **现有产品 (如 MetaOCaml)**: 通常假设 Host 语言和 Target 语言是同一种（或者是宿主语言的子集）。
*   **MDTT**: 核心架构明确区分 $M$ (Host/Meta language) 和 $L$ (Target/Object language)。
    *   我们关注的是：**用高阶的宿主语言（如 Haskell/Agda）去生成底层的、受限的目标语言（如 CUDA, SQL, Assembly, WASM）。**
    *   MDTT 的符号 $X_{\text{Host}}^{\text{Target}}\langle \text{Type} \rangle$ 明确捕捉了这种跨语言的语境切换。

### 区别二：依赖类型 (Dependent Types) 的引入
*   **现有产品**: 大多使用简单类型系统 (Simple Type System) 或 系统 F。它们能保证“生成的代码不崩溃”，但不能保证“生成的代码逻辑正确”。
*   **MDTT**: 利用依赖类型，我们可以在生成阶段就证明目标代码的属性。
    *   *例子*: 编写一个生成矩阵乘法的生成器。
    *   *普通 MSP*: 生成的代码可能因为数组越界而运行时崩溃。
    *   *MDTT*: 类型系统强制要求输入矩阵维度匹配 ($N \times M$ 和 $M \times K$)，生成的代码在数学上保证了内存访问是安全的，**不需要在目标代码中插入边界检查**（Zero-overhead safety）。

### 区别三：AST 与 Code 的对偶性 (Duality)
*   **现有产品**: 往往模糊处理 AST（可分析的数据结构）和 Code（黑盒的可执行体）的界限。
*   **MDTT**: 严格区分了 **Open Code (AST)** 和 **Closed Code (Compiled Binary)**。
    *   在 MDTT 中，我们形式化了从 Source $\to$ AST $\to$ Typed AST $\to$ Executable 的完整 Pipeline。这不仅仅是编程模型，也是编译器架构的模型。

---

## 总结

如果把 **Template Haskell** 比作一把“瑞士军刀”（编译期宏，解决样板代码），把 **MetaOCaml** 比作“手术刀”（同构特化，解决性能），那么 **MDTT** 更像是一个 **“精密机床的设计图纸”**。

**MDTT 的愿景是：**
建立一套形式化理论，指导我们构建 **下一代编译器**。在这个编译器中，我们可以用极富表现力的宿主语言（Host），安全地、数学可证地生成运行在不同硬件上的高效目标代码（Target），同时彻底消灭仅仅因为“阶段错配”导致的 Bug。
