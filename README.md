# MDTT Specification v0.7

**Heterogeneous Multi-stage Dependent Type Theory**

## 1. 概述 (Overview)

MDTT 是一个用于形式化描述元编程、编译器架构及异构计算的类型理论框架。

**核心特征：**

- **异构性 (Heterogeneity)**: 显式区分宿主语言 ( $M$ ) 与目标语言 ( $L$ )。
- **二元性 (Duality)**: 严格分离 Code (黑盒/安全) 与 AST (白盒/可分析)。
- **显式管线 (Explicit Pipeline)**: 将解析、定型、代码生成与执行严格分阶，消除中间态的类型模糊性。

## 2. 基础定义 (Foundations)

- $ℒ$ (Languages): 语言标签的集合。
- $M \in ℒ$: Host Language (Machine/Meta)，当前内存与执行环境的持有者。
- $L \in ℒ$: Target Language (Object/Source)，被表示、编译或解释的语言。

**类型约束 (Type Constraints):**

- $\text{Liftable}(\tau)$: 一个类型类 (Type Class) 约束。仅当 $\tau$ 满足此约束时（即支持序列化或跨平台引用），该类型的值才能在阶段间被提升 (Lift)。
    - Base Types ($\mathbb{N}, \mathbb{B}, \mathbb{S}$) 通常默认满足 $\text{Liftable}$。

## 3. 记法系统 (Notation System)

标准形式： $X_{\mathrm{Host}}^{\mathrm{Target}}\langle \mathrm{Type} \rangle$

### 3.1 隐式与显式规则 (Implicit/Explicit Rules)

**Host 下标 (Subscript):**

- **类型构造**: 默认省略。在单机/单宿主环境下，默认指代当前宿主 $M$ 。
- **跨层算子**: **必须显式书写**。对于 `run` (执行) 和 `lift` (提升) 等跨越 $M/L$ 边界的操作，必须标注下标以明确**操作的发起者** (Driver)。

**Target 上标 (Superscript):**

- **显式保留**: 推荐始终标注，以清晰区分源语言 ( $S$ )、目标语言 ( $T$ ) 和元语言 ( $M$ )。

**类型上下文继承 (Context Inheritance):**

- **外部**: 在构造器外部， $\tau$ 默认为 $\tau^{M}$ (Host Type)。
- **内部**: 在带有上标 $L$ 的构造器内部（即 $\langle \dots \rangle$ 中），类型上下文自动切换为 $L$ 。

## 4. 类型构造 (Type Constructors)

### 4.1 Source Text (Textual)

$$
𝒮^L
$$

- **定义**: 目标语言 $L$ 的源代码文本表示。
- **性质**: 线性 (Flat)、无类型 (Untyped)。

### 4.2 Raw AST (Structural)

$$
𝒜^L
$$

- **定义**: 未经类型检查的语法树 (Untyped AST)。
- **记法**: 当 $𝒜$ 不带类型参数 $\langle \tau \rangle$ 时，特指 Raw AST。
- **性质**: 宿主数据结构，可能包含类型错误。

### 4.3 Typed AST (Validated)

$$
𝒜^L\langle \tau \rangle
$$

- **定义**: 经过定型（Elaboration）的语法树，内蕴类型信息 $\tau$。
- **性质**: 白盒 (White-box)，类型安全，是分析与优化的主要对象。

### 4.4 Code Type (Opaque)

$$
𝒞^L\langle \tau \rangle
$$

- **定义**: 宿主中的一个值，代表目标 $L$ 中类型为 $\tau$ 的一段可执行代码。
- **性质**: 黑盒 (Black-box)，不可分析，仅能组合或运行。

### 4.5 Error Context (Effectual)

$$
ℰ\langle \tau \rangle
$$

- **定义**: 表示计算可能失败的上下文 (如 `Result` 或 `Either`)。

## 5. 核心算子与管线 (Operators & Pipeline)

### 5.1 解析 (Parsing)

$$
\mathrm{parse} : 𝒮^L \to ℰ\langle 𝒜^L \rangle
$$

将文本转换为原始结构。

### 5.2 定型 (Elaboration)

$$
\mathrm{elaborate} : 𝒜^L \to ℰ\langle \Sigma \tau. 𝒜^L\langle \tau \rangle \rangle
$$

类型推导与检查。
- **输入**: Raw AST。
- **输出**: 一个依赖对 (Dependent Pair)，包含推导出的类型 $\tau$ 和对应的 Typed AST。

### 5.3 代码生成 (Emission)

$$
\mathrm{emit} : 𝒜^L\langle \tau \rangle \to 𝒞^L\langle \tau \rangle
$$

将白盒的 Typed AST 下降 (Lowering) 为黑盒的 Target Code。

### 5.4 提升 (Lifting)

$$
\uparrow_M^L : \forall \tau : \text{Liftable}. \tau^M \to 𝒞^L\langle \tau \rangle
$$

将宿主值嵌入为目标代码。
- **语义**: Host $M$ 将本地值序列化并注入到 Target $L$ 的代码空间中。
- **约束**: 仅适用于满足 `Liftable` 的类型。

### 5.5 特化 (Mix)

$$
\mathfrak{M}_M^L : 𝒞^L\langle \alpha \to \beta \rangle \to \alpha^L \to 𝒞^L\langle \beta \rangle
$$

编译期特化 (Partial Evaluation)。
- **语义**: 将静态值 $\alpha^L$ “烧录”进函数代码中，生成残差代码。
- **区别**: 不同于运行时的函数调用，`Mix` 在 Code 生成阶段完成，通常不产生动态调用开销。

### 5.6 运行 (Run)

$$
\mathrm{run}_M^L : 𝒞^L\langle \tau \rangle \to ℰ\langle \tau^M \rangle
$$

异构执行。
- **语义**: Host $M$ 发起对 Target $L$ 代码的执行请求，并等待结果返回 $M$。
- **副作用**: 当 $M \neq L$ 时，此操作包含 **Marshalling** (数据编组), **Offloading** (任务卸载), **Remote Execution** (远程执行) 以及 **Result Retrieval** (结果回传) 等复杂过程。

## 6. 类型推导规则 (Typing Rules)

### T-Parse
$$
\frac{\Gamma \vdash s : 𝒮^L}{\Gamma \vdash \mathrm{parse}(s) : ℰ\langle 𝒜^L \rangle}
$$

### T-Elaborate
$$
\frac{\Gamma \vdash a : 𝒜^L}{\Gamma \vdash \mathrm{elaborate}(a) : ℰ\langle \Sigma \tau. 𝒜^L\langle \tau \rangle \rangle}
$$

### T-Emit
$$
\frac{\Gamma \vdash a : 𝒜^L\langle \tau \rangle}{\Gamma \vdash \mathrm{emit}(a) : 𝒞^L\langle \tau \rangle}
$$

### T-Lift
$$
\frac{\Gamma \vdash v : \tau^M \quad \tau \in \text{Liftable}}{\Gamma \vdash \uparrow_M^L v : 𝒞^L\langle \tau \rangle}
$$

### T-Mix
$$
\frac{\Gamma \vdash f : 𝒞^L\langle \alpha \to \beta \rangle \quad \Gamma \vdash x : \alpha^L}{\Gamma \vdash \mathfrak{M}_M^L(f, x) : 𝒞^L\langle \beta \rangle}
$$

### T-Run
$$
\frac{\Gamma \vdash c : 𝒞^L\langle \tau \rangle \quad M \succeq L}{\Gamma \vdash \mathrm{run}_M^L(c) : ℰ\langle \tau^M \rangle}
$$

## 7. 应用举例 (Application Examples)

MDTT 的类型系统并非仅为了数学美感，而是为了解决实际工程中极易出错的架构问题。本节展示如何用形式化语言描述复杂的编译器架构。

### 7.1 什么是编译器与解释器 (What are Compilers and Interpreters)

为了正确处理管线中的错误上下文 (Error Context, $ℰ$)，我们引入 **Kleisli 组合算子** $\ggg$ (Left-to-right Kleisli Composition，即 Haskell 中的 `>>>`)，定义为：
$$ (f \ggg g)(x) \equiv f(x) \textbf{ bind } g $$

**1. 完整定义 (Full Definitions)**
通过组合核心算子，我们定义了从源码到目标的完整处理管线。

*   **Full Compiler (完整编译器)**:
    将源代码转化为目标代码。管线：`parse` $\to$ `elaborate` $\to$ `emit`。
    $$ \text{FullCompiler}_{M}^{T} = \mathrm{parse} \ggg \mathrm{elaborate} \ggg (\mathrm{pure} \circ \mathrm{emit}) $$
    $$ \text{FullCompiler}_{M}^{T} : 𝒮^S \to ℰ\langle 𝒞^T \rangle $$

*   **Full Interpreter (完整解释器)**:
    直接执行源代码语义。MDTT 引入基础算子 $\mathrm{eval} : 𝒜^S\langle \tau \rangle \times \text{Input} \to ℰ\langle \tau \rangle$ 来表示 AST 的求值。
    管线：`parse` $\to$ `elaborate` $\to$ `eval`。
    $$ \text{FullInterpreter}_{M} = \mathrm{parse} \ggg \mathrm{elaborate} \ggg \mathrm{eval} $$
    $$ \text{FullInterpreter}_{M} : 𝒮^S \times \text{Input} \to ℰ\langle \text{Output} \rangle $$

**2. 核心定义 (Core Definitions)**
剥离了解析与定型阶段，聚焦于 `Typed AST` 之后的语义处理。

*   **Core Compiler (编译器核心)**:
    即管线中的 $\mathrm{emit}$ 阶段。
    $$ \text{CoreCompiler}_{M}^{T} \equiv \mathrm{emit} : 𝒜^S\langle \tau \rangle \to 𝒞^T\langle \tau \rangle $$

*   **Core Interpreter (解释器核心)**:
    即管线中的 $\mathrm{eval}$ 阶段。
    $$ \text{CoreInterpreter}_{M} \equiv \mathrm{eval} : 𝒜^S\langle \tau \rangle \times \text{Input} \to ℰ\langle \tau \rangle $$

> **约定 (Convention)**: 为了简化符号，在后续章节 (7.2 - 7.4) 中，术语 **Compiler** 和 **Interpreter** 默认指代 **Core Compiler** 和 **Core Interpreter**。

### 7.2 加拿大交叉编译 (Canadian Cross Compilation)

交叉编译涉及三个平台：$B$ (Build), $H$ (Host), $T$ (Target)。
我们的目标是构建一个 **Cross Compiler**，它运行在 $H$ 上，为 $T$ 生成代码。

$$ \text{Goal} : 𝒞^H\langle \text{Compiler}_{H}^{T} \rangle $$

**构建过程的形式化**:
1.  **Toolchain**: $B$ 上的交叉编译器 $\text{Compiler}_{B}^{H}$。
2.  **Source**: 目标编译器的源码 $𝒜^{\text{Compiler}}$。
3.  **Build**:
    $$ \text{Artifact} = \mathrm{run}_B^B \left( \text{Toolchain}, \text{Source} \right) $$

**类型系统的防御力**:
MDTT 推导出 $\text{Artifact}$ 的类型为 $𝒞^H$。
$$ \mathrm{run}_B^? (\text{Artifact}) \quad \xrightarrow{\text{Type Error}} \quad \text{Expected } 𝒞^B, \text{ but got } 𝒞^H $$
这在数学上杜绝了“在构建机误运行产出物”的错误。

### 7.3 二村映象 (Futamura Projections) 与 MDTT

二村映象通过部分求值 (Partial Evaluation) 连接了解释器与编译器。

**Staged Interpreter (分阶段解释器)**
传统的解释器交织了“语义分析”与“实际执行”。如果我们重构解释器，将其明确拆分为两个阶段：
1.  **Static Stage**: 处理语法树遍历、环境查找等静态工作。
2.  **Dynamic Stage**: 生成执行这些语义的目标代码。

这种被重构的解释器被称为 **Staged Interpreter**。它的输入依然是 AST，但输出变成了“计算结果的代码”而非结果本身。
$$ \text{StagedInterpreter}_M^T : 𝒜^S\langle \tau \rangle \to 𝒞^T\langle \text{Input} \to \tau \rangle $$

对比 7.1 中 **Compiler** 的定义，我们发现两者在类型上是等价的：
$$ \text{StagedInterpreter}_M^T \equiv \text{Compiler}_M^T $$
这揭示了物理本质：**编译器就是被特化（Staged）后的解释器。**

**三层映象推导**:
我们使用特化算子 $\mathfrak{M}$ (Mix) 来自动化这一过程。在以下公式中，我们显式标注函数参数类型以确保严谨。
(注：为支持部分求值，我们将 Interpreter 视为柯里化函数 $𝒜 \to (\text{Input} \to ℰ\langle \text{Output} \rangle)$)

1.  **第一映象 (Target Code)**:
    将解释器针对特定源码进行特化。
    $$ \text{Code}^T = \mathfrak{M}_M^T(\text{Interpreter} : 𝒜 \to (\text{In} \to ℰ\langle \text{Out} \rangle), \text{src} : 𝒜) $$
    *结果*: 获得等效于编译出的目标代码。

2.  **第二映象 (Compiler)**:
    将特化算子针对解释器进行特化。
    $$ \text{Compiler}_M^T = \mathfrak{M}_M^M(\text{Mix} : \text{Code} \to \text{Code}, \text{Interpreter} : 𝒜 \to (\text{In} \to ℰ\langle \text{Out} \rangle)) $$
    *结果*: 获得一个能将任意源码转化为目标代码的编译器。

3.  **第三映象 (Compiler Generator / Cogen)**:
    将特化算子针对其自身进行特化。
    $$ \text{Cogen}_M = \mathfrak{M}_M^M(\text{Mix} : \text{Code} \to \text{Code}, \text{Mix} : \text{Code} \to \text{Code}) $$
    *结果*: 获得一个编译器生成器 (Compiler Generator)。

### 7.4 编译器自举 (Compiler Bootstrapping)

自举是指用语言 $L$ 编写的编译器来编译其自身。我们将以 **Rust (rustc)** 的自举过程为例。

**场景设定**:
*   **语言**: Rust。
*   **目标**: 产出最新版的 `rustc` (Stage 2)。
*   **Source**: `rustc_src` ($𝒜^{\text{Compiler}}$)。这是用 Rust 写的最新版编译器源码。

**自举三阶段 (The Three Stages)**:

1.  **Stage 0 (Snapshot / Bootstrap Compiler)**:
    我们需要一个起点。通常是上一版本的二进制文件，已存在于 $M$ 上。
    $$ \text{rustc}_{0} : \text{Compiler}_M^M $$

2.  **Stage 1 (Intermediate Compiler)**:
    用旧编译器 $\text{rustc}_0$ 编译新源码 `rustc_src`。
    $$ \text{rustc}_{1} = \mathrm{run}_M^M( \text{rustc}_{0}, \text{rustc\_src} ) $$
    *状态分析*: $\text{rustc}_{1}$ 是一个运行在 $M$ 上的新编译器。它实现了新语言特性 (源自 `rustc_src`)，但它的机器码是由旧编译器生成的 (可能未优化)。

3.  **Stage 2 (Final Compiler)**:
    用新编译器 $\text{rustc}_1$ 再次编译新源码 `rustc_src`。
    $$ \text{rustc}_{2} = \mathrm{run}_M^M( \text{rustc}_{1}, \text{rustc\_src} ) $$
    *状态分析*: $\text{rustc}_{2}$ 实现了新特性，且是由支持新特性的编译器生成的。它是一个完全自我托管 (Self-hosted) 的产物。

**MDTT 视角下的不动点**:
理论上，如果我们继续生成 Stage 3：
$$ \text{rustc}_{3} = \mathrm{run}_M^M( \text{rustc}_{2}, \text{rustc\_src} ) $$
在确定性编译的前提下，必须满足：
$$ \text{rustc}_{2} \equiv \text{rustc}_{3} \quad (\text{Bitwise Equivalence}) $$
MDTT 的类型系统在此过程中保证了每一阶段输入输出的类型一致性 ($\text{Compiler}_M^M$)，确保了自举链条没有发生阶段错配（例如错误地使用了 Stage 0 的库来链接 Stage 2 的二进制）。

<!--
Copyright © 2025 罗宸 (luochen1990@gmail.com, chen@luo.xyz, https://blog.coding.lc)
-->
