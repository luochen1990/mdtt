# MDTT Specification v0.1
**Heterogeneous Multi-stage Dependent Type Theory**

MDTT 是一个用于形式化描述元编程、编译器架构及异构计算的类型理论框架。

---

Language ($L$): Treated as an atomic label (e.g., $L \in {\text{Source}, \text{Machine}}$). Structural semantics (AST) are optional.
Code Representation: Default to Shallow Embedding (black-box types). Expand to Deep Embedding (AST) only when necessary.
Effects: Assume logical consistency and ignore halting/side-effects (Total Functions) unless an Effect System is explicitly introduced.

基础符号 (Primitives)
Universes: $\mathcal{U}$ (Type Universe), $\mathbb{L}$ (Set of Languages).
Base Types: $\mathbb{N}$ (Nat), $\mathbb{B}$ (Bool), $\mathbb{S}$ (String).
Judgments:

$\Gamma \vdash t : \tau$ (Term $t$ has type $\tau$ under context $\Gamma$)
$t \equiv u$ (Definitional Equality)
$t \rhd u$ (Reduction/Computation)

类型构造 (Type Constructors)
Dependent Function: $(x:\alpha) \to \beta(x)$ (Simple: $\alpha \to \beta$)
Product: $\alpha \times \beta$
Code Type:
$\mathcal{C}_L\langle \tau \rangle$

Definition: Represents a closed source code term in language $L$ that, when evaluated, yields a value of type $\tau$.

核心算子 (Core Operators) A. 求值 (Evaluation) $\llbracket \cdot \rrbracket_L : \mathcal{C}_L\langle \tau \rangle \to \tau$
Executes the code to produce a value.

B. 提升 (Lifting)
$\uparrow_L : (v : \mathbb{B}) \to \mathcal{C}_L\langle v \rangle$

Semantics: Captures the computed value of $v$ from the host language and embeds it as a literal constant in the target language code.

C. 特化 (Specialization / Mix)
$\mathfrak{M} : \mathcal{C}_L\langle \alpha \times \beta \to \gamma \rangle \to \alpha \to \mathcal{C}_L\langle \beta \to \gamma \rangle$

Semantics: Given code for a two-argument function and the static value of the first argument ($\alpha$), generates residual code for a specialized function taking only $\beta$.

D. 语法树 (Deep Embedding - Optional)
$\mathcal{A}_L : \mathcal{U}$
$\text{parse} : \mathcal{C}_L\langle \tau \rangle \to \mathcal{A}_L$
4. 二村映象 (Futamura Projections) Definitions
Common Types:

$\text{IntType} \equiv \mathcal{C}_S\langle \alpha \to \beta \rangle \times \alpha \to \beta$
$\text{CompType} \equiv \mathcal{C}_S\langle \alpha \to \beta \rangle \to \mathcal{C}_M\langle \alpha \to \beta \rangle$

The Projections:

Interpreter:
$\text{Int} : \mathcal{C}_M \langle \text{IntType} \rangle$

Compilation (1st Projection):
$\text{target} \equiv \llbracket \mathfrak{M} \rrbracket_M (\text{Int}, \text{src})$
$\vdash \text{target} : \mathcal{C}_M\langle \alpha \to \beta \rangle$

Compiler Generation (2nd Projection):
$\text{Comp} \equiv \llbracket \mathfrak{M} \rrbracket_M (\uparrow_M \mathfrak{M}, \uparrow_M \text{Int})$
$\vdash \text{Comp} : \mathcal{C}_M\langle \text{CompType} \rangle$

Compiler Generator Generation (3rd Projection):
$\text{Cogen} \equiv \llbracket \mathfrak{M} \rrbracket_M (\uparrow_M \mathfrak{M}, \uparrow_M \mathfrak{M})$
$\vdash \text{Cogen} : \mathcal{C}_M\langle \mathcal{C}_M\langle \text{IntType} \rangle \to \mathcal{C}_M\langle \text{CompType} \rangle \rangle$

-<!--
-Copyright © 2025 罗宸 (luochen1990@gmail.com, chen@luo.xyz, https://blog.coding.lc)
--->
