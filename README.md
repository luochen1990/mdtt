# MDTT Specification v0.2
**Heterogeneous Multi-stage Dependent Type Theory**

1. 概述 (Overview)
MDTT 是一个用于形式化描述元编程、异构计算及编译器架构的类型理论框架。其核心特征在于显式区分了 宿主语言 (Host/Meta) 与 目标语言 (Target/Object)，并严格分离了 代码句柄 (Code) 与 语法树 (AST) 的表示。
2. 基础定义 (Foundations)

$\mathbb{L}$ (Languages): 语言标签的集合。

$M \in \mathbb{L}$: Host Language (Machine/Meta)，当前执行环境。
$L \in \mathbb{L}$: Target Language (Object)，被表示或生成的语言。


$\mathcal{U}$ (Universes): 类型的集合。

$\mathcal{U}_M$: 宿主语言的类型全集。
$\mathcal{U}_L$: 目标语言的类型全集。


Base Types: $\mathbb{N}, \mathbb{B}, \mathbb{S}$ (Nat, Bool, String).

3. 记法系统 (Notation System)
对于任意构造 $X$，采用如下标准记法：
$X_{\text{Host}}^{\text{Target}}\langle \text{Constraint} \rangle$
3.1 隐式规则 (Implicit Rules)
为了简洁，我们采用上下文敏感的默认规则。


Top-Level Context (宿主环境):

默认语言为当前宿主 $M$。
$\tau$ 默认为 $\tau_M$。
$\mathcal{C}\langle \dots \rangle$ 默认为 $\mathcal{C}_M^M\langle \dots \rangle$ (同构多阶段)。



Inner Context (构造器内部):

在 $\mathcal{C}^L\langle \dots \rangle$ 或 $\mathcal{A}^L\langle \dots \rangle$ 的尖括号内部，上下文切换为目标语言 $L$。
$\mathbb{N}$ 默认为 $\mathbb{N}_L$。
$\alpha \to \beta$ 默认为 $\alpha_L \to_L \beta_L$。



显式标记 (Explicit Override):

当需要消除歧义或跨层引用时，必须使用上下标。
例: $\mathbb{N}_M$ (宿主的整数), $\to^L$ (目标的函数箭头)。



4. 类型构造 (Type Constructors)
4.1 Code Type (Opaque)
$\mathcal{C}_M^L\langle \tau \rangle$

定义: 宿主 $M$ 中的一个值，代表目标 $L$ 中类型为 $\tau$ 的一段代码。
性质:

Black-box: 不可模式匹配，不可查看内部结构。
Typed: 构造规则保证代码在 $L$ 中是类型安全的。
Hygienic: 自动处理变量绑定和重命名。



4.2 AST Type (Transparent)
$\mathcal{A}_M^L\langle \tau \rangle \quad \text{or} \quad \mathcal{A}_M^L$

定义: 宿主 $M$ 中的一个代数数据结构，表示 $L$ 的语法树。
变体:

$\mathcal{A}_M^L$: Raw AST (Unityped)。仅描述语法结构，不保证类型安全。
$\mathcal{A}_M^L\langle \tau \rangle$: Typed AST (GADT)。内蕴类型信息的 AST。


性质: White-box，支持遍历、模式匹配和修改。

5. 核心算子 (Core Operators)
5.1 提升 (Lifting)
$\uparrow_M^L : \tau_M \to \mathcal{C}_M^L\langle \tau_L \rangle$

语义: 将宿主的值（Value）嵌入为目标代码中的字面量（Literal）。
例: $\uparrow(5) \Rightarrow \langle 5 \rangle$

5.2 求值 (Evaluation)
$\llbracket \cdot \rrbracket_M^L : \mathcal{C}_M^L\langle \tau \rangle \to \tau_M$

语义: 在宿主 $M$ 上运行目标代码，并获取结果。
前提: $M$ 必须拥有执行 $L$ 的能力（如 $M=L$ 或 $M$ 包含 $L$ 的虚拟机）。

5.3 物化/下降 (Reification / Lowering)
$\downarrow_M^L : \mathcal{C}_M^L\langle \tau \rangle \to \mathcal{A}_M^L\langle \tau \rangle$

语义: 将不透明的代码句柄解析为可分析的 AST 数据结构。
用途: 开启编译器优化、静态分析。

5.4 特化 (Mix / Specialization)
$\mathfrak{M}_M^L : \mathcal{C}_M^L\langle \alpha \times \beta \to \gamma \rangle \to \alpha_L \to \mathcal{C}_M^L\langle \beta \to \gamma \rangle$

语义: 部分求值算子。给定代码和部分静态参数（Static Argument），生成残差代码（Residual Code）。
注意: 输入的静态参数 $\alpha_L$ 通常由 $\uparrow$ 提升而来，或者是已知的代码片段。

6. 二村映象应用 (Futamura Projections)
基于 MDTT v2.0 的编译器架构形式化。
设定: Source $S$, Target $T$, Host $M$.
6.1 解释器 (Interpreter)
$\text{Int} : \mathcal{C}_M^S\langle \text{Input} \rangle \to \mathcal{C}_M^T\langle \text{Output} \rangle$
(注：为了适配 Mix，这里假设解释器是一个将 S 代码映射为 T 代码（或直接计算结果）的函数。最纯粹的形式是 $\mathcal{A}_M^S \to \text{Val}_M$)
6.2 编译器 (Compiler - 1st Projection)
$\text{target\_code} = \mathfrak{M}_M^M(\text{Int}, \text{source\_code})$

$\text{source\_code} : \mathcal{C}_M^S\langle \dots \rangle$
$\text{target\_code} : \mathcal{C}_M^T\langle \dots \rangle$

6.3 编译器生成器 (CompGen - 2nd Projection)
$\text{Comp} = \mathfrak{M}_M^M(\mathfrak{M}, \text{Int})$

$\text{Comp} : \mathcal{C}_M^S \to \mathcal{C}_M^T$ (这是一个编译好的编译器程序)

6.4 编译器生成器的生成器 (Cogen - 3rd Projection)
$\text{Cogen} = \mathfrak{M}_M^M(\mathfrak{M}, \mathfrak{M})$

$\text{Cogen} : \text{Interpreter} \to \text{Compiler}$


7. 附录：类型推导规则示例 (Typing Rules)
T-Lift:
$\frac{\Gamma \vdash t : \tau_M}{\Gamma \vdash \uparrow_M^L t : \mathcal{C}_M^L\langle \tau_L \rangle}$
T-Run:
$\frac{\Gamma \vdash c : \mathcal{C}_M^L\langle \tau \rangle \quad M \succeq L}{\Gamma \vdash \llbracket c \rrbracket_M^L : \tau_M}$
T-Reify:
$\frac{\Gamma \vdash c : \mathcal{C}_M^L\langle \tau \rangle}{\Gamma \vdash \downarrow_M^L c : \mathcal{A}_M^L\langle \tau \rangle}$

-<!--
-Copyright © 2025 罗宸 (luochen1990@gmail.com, chen@luo.xyz, https://blog.coding.lc)
--->
