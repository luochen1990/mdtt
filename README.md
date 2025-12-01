# MDTT Specification v0.3
**Heterogeneous Multi-stage Dependent Type Theory**

1. 概述 (Overview)
MDTT 是一个用于形式化描述元编程、编译器架构及异构计算的类型理论框架。
核心哲学：

异构性 (Heterogeneity): 显式区分宿主语言 ($M$) 与目标语言 ($L$)。
二元性 (Duality): 严格分离 Code (黑盒/安全) 与 AST (白盒/可分析)。
完整链路 (Full Pipeline): 涵盖从 文本 ($\mathcal{S}$) 到 AST ($\mathcal{A}$) 再到 Code ($\mathcal{C}$) 的全过程。

2. 基础定义 (Foundations)

$\mathbb{L}$ (Languages):

$M \in \mathbb{L}$: Host Language (Machine/Meta)，当前内存与执行环境的持有者。
$L \in \mathbb{L}$: Target Language (Object)，被表示、被编译或被解释的语言。


$\mathcal{U}$ (Universes):

$\mathcal{U}_M$: 宿主类型的集合。
$\mathcal{U}_L$: 目标类型的集合。



3. 记法系统 (Notation System)
$X_{\text{Host}}^{\text{Target}}\langle \text{Constraint} \rangle$

隐式规则 (Implicit Rules):

Top-Level: 默认指代 Host ($M$)。
Inner-Context (在 $\langle \dots \rangle$ 内部): 默认指代 Target ($L$)。


显式规则: 当需要消除歧义时，显式书写上下标。

4. 类型构造 (Type Constructors)
4.1 Source Text (Textual)
$\mathcal{S}^L$

定义: 目标语言 $L$ 的源代码文本表示（如 String）。
性质: 线性 (Flat)、无类型 (Untyped)、宿主无关 (Host-Independent)。

4.2 AST Type (Structural)
$\mathcal{A}_M^L$

定义: 宿主 $M$ 中的代数数据结构，表示 $L$ 的语法树。
性质: 白盒 (White-box)、可遍历、可能包含语义错误。

4.3 Error Context (Effectual)
$\mathcal{E}_M\langle \tau \rangle$

定义: 一个计算上下文，表示在宿主 $M$ 中产生类型 $\tau$ 的结果，或者失败（抛出错误）。
用途: 用于处理解析失败、类型检查失败或运行时异常。
等价物: Result<T, Error> 或 Either Error T。

4.4 Code Type (Opaque)
$\mathcal{C}_M^L\langle \tau \rangle$

定义: 宿主 $M$ 中的一个值，代表目标 $L$ 中类型为 $\tau$ 的一段代码。
性质: 黑盒 (Black-box)、类型安全 (Well-typed)、卫生 (Hygienic)。
不变量: 若存在 $c : \mathcal{C}_M^L\langle \tau \rangle$，则 $c$ 在 $L$ 中一定能求值为 $\tau$。

5. 核心算子与管线 (Operators & Pipeline)
5.1 解析 (Parsing)
$\text{parse} : \mathcal{S}^L \to \mathcal{E}_M\langle \mathcal{A}_M^L \rangle$

将文本转换为 AST。可能因语法错误而失败。

5.2 检查/细化 (Checking / Elaboration)
$\text{check} : \mathcal{A}_M^L \to \mathcal{E}_M\langle \mathcal{C}_M^L\langle \tau \rangle \rangle$

将 AST 转换为 Code。可能因类型错误而失败。
注: 这是从 Untyped 世界进入 Typed 世界的唯一安全入口。

5.3 提升 (Lifting)
$\uparrow_M^L : \tau_M \to \mathcal{C}_M^L\langle \tau_L \rangle$

将宿主值嵌入为目标代码字面量。总是成功。

5.4 运行/求值 (Evaluation)
$\llbracket \cdot \rrbracket_M^L : \mathcal{C}_M^L\langle \tau \rangle \to \tau_M$

系统原语。执行目标代码。
注: 对于 Total Language，这总是成功。对于允许副作用的语言，结果可能包含在 $\mathcal{E}_M$ 中。

5.5 物化 (Reification)
$\downarrow_M^L : \mathcal{C}_M^L\langle \tau \rangle \to \mathcal{A}_M^L$

将 Code 还原为 AST 以便分析。

5.6 特化 (Mix)
$\mathfrak{M}_M^L : \mathcal{C}_M^L\langle \alpha \to \beta \rangle \to \alpha_L \to \mathcal{C}_M^L\langle \beta \rangle$

部分求值。

6. 修正后的二村映象 (Revised Futamura Projections)
设定: Source $S$, Target $T$, Host $M$.
6.1 解释器 (Standard Interpreter)
$\text{Int} : \mathcal{A}_M^S \times \text{Input} \to \mathcal{E}_M\langle \text{Output} \rangle$

定义: 用户编写的函数，递归遍历 AST 并计算结果。
性质: 可能会失败（如除以零，或 AST 语义错误）。

6.2 编译器 (Compiler / Staged Interpreter)
$\text{Comp} : \mathcal{A}_M^S \to \mathcal{E}_M\langle \mathcal{C}_M^T\langle \text{Input} \to \text{Output} \rangle \rangle$

定义: 用户编写的函数，遍历 AST 并生成目标代码。
性质: 可能会在编译期失败（如发现死代码或类型不匹配）。
第一二村映象: $\text{Comp} \approx \mathfrak{M}(\text{Int}, \dots)$

6.3 编译器生成器 (Cogen)
$\text{Cogen} : \text{Interpreter} \to \text{Compiler}$

类型展开:
$(\mathcal{A}^S \times \text{In} \to \mathcal{E}\langle \text{Out} \rangle) \to (\mathcal{A}^S \to \mathcal{E}\langle \mathcal{C}^T\langle \text{In} \to \text{Out} \rangle \rangle)$


7. 附录：典型工作流 (Typical Workflow)
一个完整的元编程或编译任务在 MDTT 中描述如下：

Read: 从文件读取源码 $s : \mathcal{S}^S$。
Parse: $a \leftarrow \text{parse}(s)$。得到 AST $a : \mathcal{A}_M^S$。
Compile: $c \leftarrow \text{compile}(a)$。得到目标代码 $c : \mathcal{C}_M^T\langle \text{In} \to \text{Out} \rangle$。

注: compile 函数内部可能使用了 $\uparrow$ (Lift) 和 $\mathfrak{M}$ (Mix)。


Run: $r = \llbracket c \rrbracket_M^T(\text{input})$。执行代码得到结果。


<!--
-Copyright © 2025 罗宸 (luochen1990@gmail.com, chen@luo.xyz, https://blog.coding.lc)
--->
