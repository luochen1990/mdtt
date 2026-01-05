# MDTT Specification v0.5

**Heterogeneous Multi-stage Dependent Type Theory**

## 1. 概述 (Overview)

MDTT 是一个用于形式化描述元编程、编译器架构及异构计算的类型理论框架。

**核心特征：**

- **异构性 (Heterogeneity)**: 显式区分宿主语言 ( $M$ ) 与目标语言 ( $L$ )。
- **二元性 (Duality)**: 严格分离 Code (黑盒/安全) 与 AST (白盒/可分析)。
- **完整链路 (Full Pipeline)**: 涵盖从 文本 ( $\mathcal{S}$ ) 到 AST ( $\mathcal{A}$ ) 再到 Code ( $\mathcal{C}$ ) 的全过程，并引入 错误上下文 ( $\mathcal{E}$ ) 处理副作用。

## 2. 基础定义 (Foundations)

- $\mathcal{L}$ (Languages): 语言标签的集合。
- $M \in \mathcal{L}$ : Host Language (Machine/Meta)，当前内存与执行环境的持有者。
- $L \in \mathcal{L}$ : Target Language (Object/Source)，被表示、编译或解释的语言。

**$\mathcal{U}$ (Universes):**

- $\mathcal{U}^M$ : 宿主语言的类型全集。
- $\mathcal{U}^L$ : 目标语言的类型全集。

**Base Types:** $\mathbb{N}, \mathbb{B}, \mathbb{S}$ (Nat, Bool, String).

## 3. 记法系统 (Notation System)

标准形式：

$$
X_{\mathrm{Host}}^{\mathrm{Target}}\langle \mathrm{Type} \rangle
$$

### 3.1 隐式与显式规则 (Implicit/Explicit Rules)

**Host 下标 (Subscript):**

- **默认省略**: 在单机/单宿主环境下，默认指代当前宿主 $M$ 。
- **显式书写**: 仅在涉及跨宿主操作（如分布式计算、交叉编译、代码传输）时使用。

**Target 上标 (Superscript):**

- **显式保留**: 推荐始终标注，以清晰区分源语言 ( $S$ )、目标语言 ( $T$ ) 和元语言 ( $M$ )。

**类型上下文继承 (Context Inheritance):**

- **外部**: 在构造器外部， $\tau$ 默认为 $\tau^{M}$ (Host Type)。
- **内部**: 在带有上标 $L$ 的构造器内部（即 $\langle \dots \rangle$ 中），类型上下文自动切换为 $L$ 。
- **示例**: $\mathcal{C}^L\langle \mathbb{N} \to \mathbb{N} \rangle$ 等价于 $\mathcal{C}^L\langle \mathbb{N}^L \to^L \mathbb{N}^L \rangle$ 。

## 4. 类型构造 (Type Constructors)

### 4.1 Source Text (Textual)

$$
\mathcal{S}^L
$$

- **定义**: 目标语言 $L$ 的源代码文本表示（如 String）。
- **性质**: 线性 (Flat)、无类型 (Untyped)、宿主无关 (Host-Independent)。

### 4.2 AST Type (Structural)

$$
\mathcal{A}^L \quad \text{or} \quad \mathcal{A}^L\langle \tau \rangle
$$

- **定义**: 宿主中的代数数据结构，表示 $L$ 的语法树。
- **变体**:
    - $\mathcal{A}^L$: Raw AST。仅描述语法结构，不保证类型安全。
    - $\mathcal{A}^L\langle \tau \rangle$: Typed AST (GADT)。内蕴类型信息的 AST。
- **性质**: 白盒 (White-box)、可遍历、可能包含语义错误。

### 4.3 Error Context (Effectual)

$$
\mathcal{E}\langle \tau \rangle
$$

- **定义**: 一个计算上下文，表示在宿主中产生类型 $\tau$ (Host Type) 的结果，或者失败。
- **用途**: 处理解析、类型检查失败或运行时异常。
- **等价物**: `Result<T, Error>` 或 `Either Error T`。

### 4.4 Code Type (Opaque)

$$
\mathcal{C}^L\langle \tau \rangle
$$

- **定义**: 宿主中的一个值，代表目标 $L$ 中类型为 $\tau$ (Target Type) 的一段代码。
- **性质**: 黑盒 (Black-box)、类型安全 (Well-typed)、卫生 (Hygienic)。
- **不变量**: 若存在 $c : \mathcal{C}^L\langle \tau \rangle$，则 $c$ 在 $L$ 中一定能求值为 $\tau$。

## 5. 核心算子与管线 (Operators & Pipeline)

### 5.1 解析 (Parsing)

$$
\text{parse} : \mathcal{S}^L \to \mathcal{E}\langle \mathcal{A}^L \rangle
$$

将文本转换为 AST。可能因语法错误而失败。

### 5.2 检查/细化 (Checking / Elaboration)

$$
\text{check} : \mathcal{A}^L \to \mathcal{E}\langle \mathcal{C}^L\langle \tau \rangle \rangle
$$

将 AST 转换为 Code。可能因类型错误而失败。  
注: 返回类型中的 $\tau$ 是存在量化 (Existential Quantification) 的，或者是 check 函数的一个参数。

### 5.3 提升 (Lifting)

$$
\uparrow^L : \tau^M \to \mathcal{C}^L\langle \tau \rangle
$$

将宿主值嵌入为目标代码字面量。  
注: 这里 $\tau$ (Target) 对应于输入的 $\tau^M$ (Host)。

### 5.4 运行/求值 (Evaluation)

$$
\llbracket \cdot \rrbracket^L : \mathcal{C}^L\langle \tau \rangle \to \mathcal{E}\langle \tau^M \rangle
$$

系统原语。执行目标代码。  
注: 结果包裹在 $\mathcal{E}$ 中，因为运行时可能发生错误。

### 5.5 物化 (Reification)

$$
\downarrow^L : \mathcal{C}^L\langle \tau \rangle \to \mathcal{A}^L\langle \tau \rangle
$$

将 Code 还原为 AST 以便分析。

### 5.6 特化 (Mix)

$$
\mathfrak{M}^L : \mathcal{C}^L\langle \alpha \to \beta \rangle \to \alpha^L \to \mathcal{C}^L\langle \beta \rangle
$$

部分求值。给定代码和静态参数（Host Value $\alpha^L$ ），生成残差代码。

## 6. 二村映象应用 (Futamura Projections)

设定: Source $S$ , Target $T$ , Host $M$ .

### 6.1 解释器 (Standard Interpreter)

$$
\text{Int} : \mathcal{A}^S \times \text{Input} \to \mathcal{E}\langle \text{Output} \rangle
$$

- **定义**: 用户编写的函数，递归遍历 AST 并计算结果。
- **性质**: 可能会失败。

### 6.2 编译器 (Compiler / Staged Interpreter)

$$
\text{Comp} : \mathcal{A}^S \to \mathcal{E}\langle \mathcal{C}^T\langle \text{Input} \to \text{Output} \rangle \rangle
$$

- **定义**: 用户编写的函数，遍历 AST 并生成目标代码。
- **性质**: 可能会在编译期失败。
- **第一二村映象**: $\mathrm{target\_code} = \mathfrak{M}^M(\mathrm{Int}, \mathrm{source\_ast})$

### 6.3 编译器生成器 (Cogen)

$$
\text{Cogen} : \text{Interpreter} \to \text{Compiler}
$$

- **类型展开**:

$$
(\mathcal{A}^S \times \mathrm{In} \to \mathcal{E}\langle \mathrm{Out} \rangle) \to (\mathcal{A}^S \to \mathcal{E}\langle \mathcal{C}^T\langle \mathrm{In} \to \mathrm{Out} \rangle \rangle)
$$

- **第二二村映象**: $\mathrm{Comp} = \mathfrak{M}^M(\mathfrak{M}, \mathrm{Int})$

## 7. 附录：类型推导规则 (Typing Rules)

### T-Lift

$$
\frac{\Gamma \vdash t : \tau^M}{\Gamma \vdash \uparrow^L t : \mathcal{C}^L\langle \tau \rangle}
$$

### T-Parse

$$
\frac{\Gamma \vdash s : \mathcal{S}^L}{\Gamma \vdash \text{parse}(s) : \mathcal{E}\langle \mathcal{A}^L \rangle}
$$

### T-Check

$$
\frac{\Gamma \vdash a : \mathcal{A}^L}{\Gamma \vdash \text{check}(a) : \mathcal{E}\langle \exists \tau. \mathcal{C}^L\langle \tau \rangle \rangle}
$$

### T-Run

$$
\frac{\Gamma \vdash c : \mathcal{C}^L\langle \tau \rangle \quad M \succeq L}{\Gamma \vdash \llbracket c \rrbracket^L : \mathcal{E}\langle \tau^M \rangle}
$$

### T-Mix

$$
\frac{\Gamma \vdash f : \mathcal{C}^L\langle \alpha \to \beta \rangle \quad \Gamma \vdash x : \alpha^L}{\Gamma \vdash \mathfrak{M}^L(f, x) : \mathcal{C}^L\langle \beta \rangle}
$$

<!--
Copyright © 2025 罗宸 (luochen1990@gmail.com, chen@luo.xyz, https://blog.coding.lc)
-->
