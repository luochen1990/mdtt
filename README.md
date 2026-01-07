# MDTT Specification v0.6

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
𝒜_{\text{raw}}^L
$$

- **定义**: 未经类型检查的语法树。
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
\mathrm{parse} : 𝒮^L \to ℰ\langle 𝒜_{\text{raw}}^L \rangle
$$

将文本转换为原始结构。

### 5.2 定型 (Elaboration)

$$
\mathrm{elaborate} : 𝒜_{\text{raw}}^L \to ℰ\langle \Sigma \tau. 𝒜^L\langle \tau \rangle \rangle
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

## 6. 二村映象 (Futamura Projections)

设定: Source $S$ , Target $T$ , Host $M$ .

### 6.1 解释器 (Standard Interpreter)

$$
\mathrm{Int} : 𝒜^S \times \mathrm{Input} \to ℰ\langle \mathrm{Output} \rangle
$$

注：解释器通常操作在 Typed AST 或 Raw AST 上。

### 6.2 编译器 / 分阶段解释器 (Staged Interpreter)

$$
\mathrm{Comp} : 𝒜^S \to ℰ\langle 𝒞^T\langle \mathrm{Input} \to \mathrm{Output} \rangle \rangle
$$

- **本质**: 编译器是**分阶段的解释器 (Staged Interpreter)**。
- **机制**: 通过将标准解释器中的计算阶段分离，把“即时求值”替换为“代码生成 (`emit`)”，从而将 $S$ 的 AST 转换为 $T$ 的代码。

### 6.3 编译器生成器 (Cogen)

$$
\mathrm{Cogen} : \mathrm{Interpreter} \to \mathrm{Compiler}
$$

类型展开严格遵循二村映象定义。

## 7. 附录：类型推导规则 (Typing Rules)

### T-Parse
$$
\frac{\Gamma \vdash s : 𝒮^L}{\Gamma \vdash \mathrm{parse}(s) : ℰ\langle 𝒜_{\text{raw}}^L \rangle}
$$

### T-Elaborate
$$
\frac{\Gamma \vdash a : 𝒜_{\text{raw}}^L}{\Gamma \vdash \mathrm{elaborate}(a) : ℰ\langle \Sigma \tau. 𝒜^L\langle \tau \rangle \rangle}
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

<!--
Copyright © 2025 罗宸 (luochen1990@gmail.com, chen@luo.xyz, https://blog.coding.lc)
-->
