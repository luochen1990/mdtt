# MDTT Specification v0.7

**Heterogeneous Multi-stage Dependent Type Theory**

## 1. 概述 (Overview)

MDTT 是一个用于形式化描述元编程、编译器架构及异构计算的类型理论框架。

你可以用它来进行 **架构验证 (Architecture Verification)**: 利用依赖类型 (DT) 捕捉语言实现细节，静态排除环境泄露与阶段错配，确保复杂的多阶段编译器架构的数学正确性。

**核心特征：**

- **异构性 (Heterogeneity)**: 显式区分宿主语言 ($M$) 与目标语言 ($L$)。
- **二元性 (Duality)**: 严格分离 Code (黑盒/安全) 与 AST (白盒/可分析)。
- **强类型约束**: 利用依赖类型 (DT) 精确捕捉语言实现细节（如环境依赖、阶段约束、效应），将编译器架构问题转化为类型检查问题

## 2. 基础定义 (Foundations)

- $ℒ$ (Languages): 语言标签的集合。
- $M \in ℒ$: Host Language (Machine/Meta)，当前内存与执行环境的持有者。
- $L \in ℒ$: Target Language (Object/Source)，被表示、编译或解释的语言。

**执行环境形式化 (Formal Execution Environment):**
MDTT 将“平台”(Platform) 视为类型系统的一个核心索引。
- $𝒫$: 所有可能平台的集合 (如 `x86_64-linux`, `aarch64-none-elf`)。
- **三元组 (Triplets)**: 在编译过程中涉及的三个关键平台角色，均为 $𝒫$ 的元素：
    - **Build ($B \in 𝒫$)**: 初始执行环境，即当前编译器正在运行的物理机器。
    - **Host ($H \in 𝒫$)**: 目标执行环境，即生成的工具（编译器本身）未来将要运行的平台。
    - **Target ($T \in 𝒫$)**: 产出目标环境，即生成的工具所生成的代码将要运行的平台。

**类型约束 (Type Constraints):**

- $\text{Liftable}(\tau)$: 一个类型类 (Type Class) 约束。仅当 $\tau$ 满足此约束时（即支持序列化或跨平台引用），该类型的值才能在阶段间被提升 (Lift)。
    - Base Types ($\mathbb{N}, \mathbb{B}, \mathbb{S}$) 通常默认满足 $\text{Liftable}$。

## 3. 记法系统 (Notation System)

标准形式： $X_{\text{Host}}^{\text{Target}}\langle \text{Type} \rangle$

该记法本质上是泛型参数的**简化标记 (Syntactic Sugar)**，用于避免在尖括号 $\langle \dots \rangle$ 中罗列过多的泛型参数，从而提高公式的可读性。

### 3.1 参数含义与省略 (Parameters & Omission)

- **上标 (Superscript)**: 通常代表 **Target** (目标语言/平台)。
- **下标 (Subscript)**: 通常代表 **Host** (宿主语言/平台)。

**非强制性 (Flexibility)**:
这并非强制规范，也**不意味着**所有类型都必须拥有这两个参数。
- 若某对象仅与 Target 相关（如源码 $S^L$ ），则仅需标注上标。
- 若某对象仅与 Host 相关（如解释器 $I_M$ ），则仅需标注下标。

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
\mathrm{parse}^L : 𝒮^L \to ℰ\langle 𝒜^L \rangle
$$

将文本转换为原始结构。
- **参数**: 上标 $L$ 标示被解析的目标语言。

### 5.2 定型 (Elaboration)

$$
\mathrm{elaborate}^L : 𝒜^L \to ℰ\langle \Sigma \tau. 𝒜^L\langle \tau \rangle \rangle
$$

类型推导与检查。
- **参数**: 上标 $L$ 标示被分析的目标语言。
- **输入**: Raw AST。
- **输出**: 一个依赖对 (Dependent Pair)，包含推导出的类型 $\tau$ 和对应的 Typed AST。

### 5.3 代码生成 (Emission)

$$
\mathrm{emit}_S^T : 𝒜^S\langle \tau \rangle \to 𝒞^T\langle \tau \rangle
$$

将白盒的 Typed AST 下降 (Lowering) 为黑盒的 Target Code。
- **参数**:
    - 下标 $S$ (Source): 源语言（AST 表示的语言）。
    - 上标 $T$ (Target): 目标语言（生成代码的语言）。
- **注意**: 当 $S \neq T$ 时，此算子包含编译/翻译逻辑；当 $S = T$ 时，仅为序列化。

### 5.4 提升 (Lifting)

$$
\uparrow_M^L : \forall \tau : \text{Liftable}. \tau^M \to 𝒞^L\langle \tau \rangle
$$

将宿主值嵌入为目标代码。
- **语义**: Host $M$ 将本地值序列化并注入到 Target $L$ 的代码空间中。
- **约束**: 仅适用于满足 `Liftable` 的类型。

### 5.5 特化 (Mix)

$
𝔐_M^L : 𝒞^L\langle \alpha \to \beta \rangle \to 𝒜^L\langle \alpha \rangle \to 𝒞^L\langle \beta \rangle
$

编译期特化 (Partial Evaluation)。
- **语义**: 将类型为 $\alpha$ 的静态值 (在宿主中以 AST $𝒜^L\langle \alpha \rangle$ 的形式存在) “烧录”进函数代码中，生成残差代码。
- **区别**: 不同于运行时的函数调用，`Mix` 在 Code 生成阶段完成，通常不产生动态调用开销。

### 5.6 运行 (Run)

$$
\mathrm{run}_M : 𝒞^M\langle \tau \rangle \to ℰ\langle \tau \rangle
$$

同构执行。
- **语义**: Host $M$ 加载并执行针对自身的代码 $𝒞^M$。
- **约束**: 仅当代码的目标平台与当前宿主一致时 ($L=M$) 才能运行。异构执行 (如 CPU 调度 GPU) 需通过特定 FFI 函数包装为 $𝒞^M$ 后方可调用。

### 5.7 求值 (Eval)

$$
\mathrm{eval}_M^L : 𝒜^L\langle \tau \rangle \to ℰ\langle \tau^M \rangle
$$

解释求值。
- **语义**: Host $M$ 通过解释器逻辑直接计算 Target AST $𝒜^L$ 的值。
- **区别**: 与 `run` 不同，`eval` 是软件定义的语义映射，不依赖底层硬件。因此它天然支持异构 (即在 $M$ 上解释 $L$ 的代码)，常用于实现解释器或编译期的常量折叠。

## 6. 类型推导规则 (Typing Rules)

### T-Parse
$$
\frac{\Gamma \vdash s : 𝒮^L}{\Gamma \vdash \mathrm{parse}^L(s) : ℰ\langle 𝒜^L \rangle}
$$

### T-Elaborate
$$
\frac{\Gamma \vdash a : 𝒜^L}{\Gamma \vdash \mathrm{elaborate}^L(a) : ℰ\langle \Sigma \tau. 𝒜^L\langle \tau \rangle \rangle}
$$

### T-Emit
$$
\frac{\Gamma \vdash a : 𝒜^S\langle \tau \rangle}{\Gamma \vdash \mathrm{emit}_S^T(a) : 𝒞^T\langle \tau \rangle}
$$

### T-Lift
$$
\frac{\Gamma \vdash v : \tau^M \quad \tau \in \text{Liftable}}{\Gamma \vdash \uparrow_M^L v : 𝒞^L\langle \tau \rangle}
$$

### T-Mix
$$
\frac{\Gamma \vdash f : 𝒞^L\langle \alpha \to \beta \rangle \quad \Gamma \vdash x : 𝒜^L\langle \alpha \rangle}{\Gamma \vdash 𝔐_M^L(f, x) : 𝒞^L\langle \beta \rangle}
$$

### T-Run
$$
\frac{\Gamma \vdash c : 𝒞^M\langle \tau \rangle}{\Gamma \vdash \mathrm{run}_M(c) : ℰ\langle \tau \rangle}
$$

### T-Eval
$$
\frac{\Gamma \vdash a : 𝒜^L\langle \tau \rangle}{\Gamma \vdash \mathrm{eval}_M^L(a) : ℰ\langle \tau^M \rangle}
$$

## 7. 应用举例 (Application Examples)

MDTT 的类型系统并非仅为了数学美感，而是为了解决实际工程中极易出错的架构问题。本节展示如何用形式化语言描述复杂的编译器架构。

### 7.1 编译器与解释器 (Compilers and Interpreters)

我们可以用MDTT描述编译器与解释器的准确类型。

为了正确处理管线中的错误上下文 (Error Context, $ℰ$)，我们引入 **Kleisli 组合算子** $\ggg$ (Left-to-right Kleisli Composition，即 Haskell 中的 `>>>`)，定义为：
$$ (f \ggg g)(x) \equiv f(x) \textbf{ bind } g $$

**完整定义 (Full Definitions)**

通过组合核心算子，我们定义了从源码到目标的完整处理管线。

*   **fullCompiler (完整编译器)**:
    将源代码转化为目标代码。管线：`parse` $\to$ `elaborate` $\to$ `emit`。
    $$ \text{fullCompiler}_{M}^{T} = \mathrm{parse}^S \ggg \mathrm{elaborate}^S \ggg (\mathrm{pure} \circ \mathrm{emit}_S^T) $$
    $$ \text{fullCompiler}_{M}^{T} : 𝒮^S \to ℰ\langle 𝒞^T \rangle $$

*   **fullInterpreter (完整解释器)**:
    直接执行源代码语义。MDTT 引入基础算子 $\mathrm{eval}_M^S : 𝒜^S\langle \tau \rangle \times \text{Input} \to ℰ\langle \tau \rangle$ 来表示 AST 的求值。
    管线：`parse` $\to$ `elaborate` $\to$ `eval`。
    $$ \text{fullInterpreter}_{M} = \mathrm{parse}^S \ggg \mathrm{elaborate}^S \ggg \mathrm{eval}_M^S $$
    $$ \text{fullInterpreter}_{M} : 𝒮^S \times \text{Input} \to ℰ\langle \text{Output} \rangle $$


**核心定义 (Core Definitions)**

剥离了解析与定型阶段，聚焦于 `Typed AST` 之后的语义处理。

*   **coreCompiler (编译器核心)**:
    即管线中的 $\mathrm{emit}$ 阶段。
    $$ \text{coreCompiler}_{M}^{T} \equiv \mathrm{emit}_S^T : 𝒜^S\langle \tau \rangle \to 𝒞^T\langle \tau \rangle $$

*   **coreInterpreter (解释器核心)**:
    即管线中的 $\mathrm{eval}$ 阶段。
    $$ \text{coreInterpreter}_{M} \equiv \mathrm{eval}_M^S : 𝒜^S\langle \tau \rangle \times \text{Input} \to ℰ\langle \tau \rangle $$

**类型别名 (Type Aliases)**

为了简化符号，我们正式定义以下函数类型：

*   **Compiler Type**:
    $$ \text{Compiler}\langle S, T \rangle \equiv 𝒜^S \to 𝒞^T $$

*   **Interpreter Type**:
    $$ \text{Interpreter}\langle S \rangle \equiv 𝒜^S \to \text{Input} \to ℰ\langle \text{Output} \rangle $$

> **约定 (Convention)**: 为了简化符号，在后续章节 (7.2 - 7.4) 中，术语 **compiler** 和 **interpreter** 默认指代 **coreCompiler** 和 **coreInterpreter** (作为 Term)，而大写的 **Compiler** 和 **Interpreter** 指代其对应的函数类型。

### 7.2 加拿大交叉编译 (Canadian Cross Compilation)

交叉编译涉及三个核心机器角色：**构建平台 (Build)**、**宿主平台 (Host)** 和 **目标平台 (Target)**。这种场景在 MDTT 中被称为 *Canadian Cross*，因为它涉及三个互不相同的平台 ($B \neq H \neq T$)，极易混淆。

为了理清关系，我们需要区分 **"机器三元组"** (物理/环境视角) 和 **"编译器三属性"** (软件/功能视角)。

**1. 机器三元组 (Machine Triple: B, H, T)**
这是 GCC/Clang 等构建系统的标准术语，描述物理机器的角色：
*   **Build ($B$)**: **当前**正在执行编译命令的机器。
*   **Host ($H$)**: 产物（编译器）**未来**将要运行的机器。
*   **Target ($T$)**: 产物（编译器）**未来**生成的代码所运行的机器。

**2. MDTT 映射关系表**
我们将上述物理角色映射到 MDTT 的类型系统 $𝒞^{\text{Run}} \langle \text{Src} \to 𝒞^{\text{Dest}} \rangle$ 中。

| 机器角色 | 含义 | MDTT 类型位置 | 说明 |
| :--- | :--- | :--- | :--- |
| **Build ($B$)** | 执行环境 | **上下文 (Context)** | 所有的推导步骤 $\Gamma \vdash \dots$ 都隐含在 $B$ 环境中发生。 |
| **Host ($H$)** | 运行平台 | **外层容器 ($𝒞^H$)** | 最终产物 `artifact` 的类型外壳，表示它是一个运行在 $H$ 上的二进制。 |
| **Target ($T$)** | 目标平台 | **内层容器 ($𝒞^T$)** | 编译器函数返回值的类型外壳，表示它生成 $T$ 平台的代码。 |

**3. 构建过程推导 (The Derivation)**

我们的**最终目标**是获得一个运行在 $H$ 上的编译器，它能将语言 $S$ 编译到 $T$ 平台：
$$ \text{goal} : 𝒞^H\langle \text{Compiler}\langle S, T \rangle \rangle $$
*(注： $\text{Compiler}\langle S, T \rangle$ 是 7.1 节定义的类型别名，展开为 $𝒜^S \to 𝒞^T$)*

为了在 $B$ 机器上得到这个 $\text{goal}$，我们需要一个“构建工具 (Builder)”。这个构建工具本身运行在 $B$ 上，它读取编译器的源码 (Source)，并将其编译为能运行在 $H$ 上的机器码。

假设目标编译器的源码是用语言 $L$ 编写的：

> **符号辨析 ($S$ vs $L$)**:
> *   $S$ (Source Language): **目标编译器所处理的语言**（用户的源码）。
> *   $L$ (Implementation Language): **目标编译器本身的编写语言**（编译器的源码）。
> *   (若 $L=S$ 即为自举；若 $L \neq S$ 则为异构实现)

1.  **Source**: 目标编译器的源代码。
    $$ \text{source} : 𝒜^L \quad (\text{代码逻辑是 } S \to T) $$
2.  **Builder**: 一个运行在 $B$ 上的编译器（交叉编译器），它能把语言 $L$ 编译成 $H$ 平台的代码。
    $$ \text{builder} : 𝒞^B\langle \text{Compiler}\langle L, H \rangle \rangle $$
3.  **Process**: 在 $B$ 上执行构建。
    $$ \text{artifact} = \mathrm{run}_B ( \text{builder} ) \text{ source} $$
    *(注：此处忽略了 monadic bind 细节，意为运行 builder 得到函数后应用于 source)*

**类型检查 (Type Check)**:
MDTT 的类型系统能够自动推导 `run` 操作的结果类型：
$$ \mathrm{run}_B(\text{builder}) : ℰ\langle \underbrace{\text{Compiler}\langle L, H \rangle}_{\text{Builder 逻辑: } L \to H} \rangle $$
即 $ℰ\langle 𝒜^L \to 𝒞^H \rangle$ 。将其应用到 `source` ($𝒜^L$, 且其逻辑语义为 $S \to T$) 后：
$$ \therefore \text{artifact} : 𝒞^H\langle \text{Compiler}\langle S, T \rangle \rangle $$

这就清晰地解释了为什么我们在 $B$ 上操作，却得到了 $H$ 的类型——因为 `builder` 的**目标属性** ($H$) 决定了产物的**宿主属性** ($H$)。这就是所谓的 "Shift" (转换)。

**上下文嵌套危机 (Context Nesting Crisis)**:

在加拿大交叉编译中，极易出现 **环境泄露 (Environment Leakage)**。例如，源码中的宏展开阶段 (Macro Expansion) 可能错误地捕获了 Build 机器的路径或时间戳。
- **错误**: 在 $B$ 上求值宏，嵌入了 $B$ 的字符串。
- **MDTT 约束**: 类型系统强制区分 $\text{Stage}_B$ 和 $\text{Stage}_H$ 的数据。若要在 $H$ 的代码中嵌入静态数据，必须通过显式的 `lift` 操作，且该操作必须发生在正确的阶段。
- **结果**: 如果 $B$ 的环境信息试图流入 $𝒞^H$ 而未经过合法的 Cross-Stage Persistence 处理，类型检查器将报错，从而保证了构建的可复现性 (Reproducibility)。

### 7.3 二村映射 (Futamura Projections) 与 MDTT

二村映射通过部分求值 (Partial Evaluation) 连接了解释器与编译器。

**第一映射 (生成目标代码)**
目标：将解释器针对特定源码进行特化。

为此，我们引入 **特化算子 ($𝔐$)**。
这是元语言 $M$ 的核心原语（Primitive），负责执行“将静态数据烧录进代码”的动作。
- 签名: $𝒞^L\langle \alpha \to \beta \rangle \to 𝒜^L\langle \alpha \rangle \to 𝒞^L\langle \beta \rangle$

现在我们直接使用 $𝔐$ 对解释器进行特化：
- **函数**: $\text{interpreter}$ (视为接受源码 $𝒜$ 和输入 $D$ 的函数)
- **输入**: $\text{source}$ (具体的源码 AST)
$ \text{code}^T = 𝔐_M^T(\text{interpreter}, \text{source}) $
*结果*: 固定了源码的解释器 $\equiv$ 目标代码。

**第二映射 (生成编译器)**
目标：生成一个独立的编译器。

为了实现这一点，我们需要将部分求值算法本身实现为一个目标语言中的程序，即 **特化程序 ($\text{mix}$)**。
- **类型**: $𝒞^L\langle 𝒜^L \to \text{StaticInput} \to 𝒜^L \rangle$
- **假设**: 此处假设目标语言 $L$ 具备表示自身 AST 的能力 (如 Lisp 或具有反射能力的语言)，或者我们通过外部手段将宿主 AST 映射为目标数据结构。
- **说明**: 
    - 第一个参数 (类型 $𝒜^L$) 是待特化的源程序 AST。
    - 第二个参数 (类型 $\text{StaticInput}$) 是编译期已知的静态输入数据。
    - 返回值 (类型 $𝒜^L$) 是特化后的残差程序 AST。

在此阶段，我们将 **特化程序 ($\text{mix}$)** 作为被操作的对象。

$ \text{compiler}_M^T = 𝔐_M^M(\text{mix}, \text{interpreterSrc}) $

**深度解析：为什么 Mix 算子可以作用于 mix 项？**
观察 $𝔐$ 的签名与 $\text{mix}$ 的类型，我们可以发现它们完美的类型匹配：
1.  **算子要求**: $𝔐$ 需要一个函数代码 $𝒞\langle \alpha \to \beta \rangle$ 和一个参数值 $\alpha$。
2.  **程序提供**: $\text{mix}$ 本身就是一个代码项，其类型为 $𝒞\langle 𝒜^L \to (\text{StaticInput} \to 𝒜^L) \rangle$。
    - 这里泛型 $\alpha$ 被实例化为 $𝒜^L$ (AST)。
3.  **输入匹配**: 我们提供的 $\text{interpreterSrc}$ 恰好是一个 AST 值。
4.  **结论**: $𝔐(\text{mix}, \text{interpreterSrc})$ 合法，返回值的类型为 $𝒞\langle \text{StaticInput} \to 𝒜^L \rangle$。
    - 这个返回值的物理含义是：一个接受“静态输入”（即源代码）并输出“残差程序 AST”的函数。
    - 这在 MDTT 架构中对应于**编译器的前端与优化器** (从源码到特化 AST)。
    - 若要得到产出二进制目标代码的完整编译器，需将运行该生成器得到的结果接入 `emit` 阶段： $\lambda s. \mathrm{emit}_S^T(\mathrm{run}_M(\text{compiler}) s)$。（注：此处忽略了 Monad 包装）。

**第三映射 (生成编译器生成器 / Cogen)**
目标：生成一个能自动将解释器转换为编译器的工具。
$ \text{cogen}_M = 𝔐_M^M(\text{mix}, \text{mixSrc}) $
*含义*:
- **Function**: $\text{mix}$ (运行中的部分求值器代码)。
- **Input**: $\text{mixSrc}$ (作为数据的部分求值器源码 AST)。
*结果*: 返回一个新的函数。这个函数接受一个“静态输入”（这里即“解释器源码”），输出“残差程序”（即该解释器对应的编译器）。
这是一个编译器生成器：$\text{interpreterSrc} \to \text{compiler}$。


### 7.4 编译器自举 (Compiler Bootstrapping)

自举是指用语言 $L$ 编写的编译器来编译其自身。我们将以 **Rust (rustc)** 的自举过程为例。

**场景设定**:
*   **语言**: Rust。
*   **目标**: 产出最新版的 `rustc` (Stage 2)。
*   **Source**: `rustc_src` ($𝒜^S$)。这是用 Rust 写的最新版编译器源码。

**自举三阶段 (The Three Stages)**:

1.  **Stage 0 (Snapshot / Bootstrap Compiler)**:
    我们需要一个起点。通常是上一版本的二进制文件，已存在于 $M$ 上。
    $$ \text{rustc}_{0} : 𝒞^M\langle \text{Compiler}\langle S, M \rangle \rangle $$

2.  **Stage 1 (Intermediate Compiler)**:
    用旧编译器 $\text{rustc}_0$ 编译新源码 `rustc_src`。
    $$ \text{rustc}_{1} = \mathrm{run}_M( \text{rustc}_{0}, \text{rustc\_src} ) $$
    *状态分析*: $\text{rustc}_{1}$ 是一个运行在 $M$ 上的新编译器。它实现了新语言特性 (源自 `rustc_src`)，但它的机器码是由旧编译器生成的 (可能未优化)。

3.  **Stage 2 (Final Compiler)**:
    用新编译器 $\text{rustc}_1$ 再次编译新源码 `rustc_src`。
    $$ \text{rustc}_{2} = \mathrm{run}_M( \text{rustc}_{1}, \text{rustc\_src} ) $$
    *状态分析*: $\text{rustc}_{2}$ 实现了新特性，且是由支持新特性的编译器生成的。它是一个完全自我托管 (Self-hosted) 的产物。

**MDTT 视角下的不动点**:
理论上，如果我们继续生成 Stage 3：
$$ \text{rustc}_{3} = \mathrm{run}_M( \text{rustc}_{2}, \text{rustc\_src} ) $$
在确定性编译的前提下，必须满足：
$$ \text{rustc}_{2} \equiv \text{rustc}_{3} \quad (\text{Bitwise Equivalence}) $$
MDTT 的类型系统在此过程中保证了每一阶段输入输出的类型一致性 ($\text{Compiler}\langle S, M \rangle$)，确保了自举链条没有发生阶段错配（例如错误地使用了 Stage 0 的库来链接 Stage 2 的二进制）。

<!--
Copyright © 2026 罗宸 (luochen1990@gmail.com, chen@luo.xyz, https://blog.coding.lc)
-->
