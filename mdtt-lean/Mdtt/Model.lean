/-!
# Mdtt.Model — MDTT 的签名级核心 (T1)

职责边界: 定义 MDTT 规范 v0.8 §4 的全部类型构造器与 §5 的全部算子签名.

核心设计 (**Model-Record 架构**, 见 mdtt-lean/README.md):
- `Ty` 是 MDTT 理论自身的**共享类型宇宙** (规范 §4.6), 全局唯一定义, 语言以 `String` 标签指称;
- `Model` 记录把"一个具体的多阶段世界"打包: 语言宇宙、宿主、类型构造器、算子与语义锚点等式;
- T1 层的全部定理 (Rules/Pipeline/CanadianCross/Futamura/Bootstrapping) 对**任意** Model 成立;
- T2 层的工作 (Mdtt/Stlc.*) 是构造 `stlcModel : Model` 的一个具体实例.

符号映射 (规范 → Lean): 𝒮^L → `m.src L` | 𝒜^L → `m.raw L` | 𝒜^L⟨τ⟩ → `m.tast L τ`
| 𝒞^L⟨τ⟩ → `m.code L τ` | ⟦τ⟧^L → `m.sem L τ` | τ^M → `m.sem m.host τ`
| ℰ⟨α⟩ → `ℰ α` | Liftable(τ) → `m.liftable τ` | ≫ → `≫` (Kleisli).
-/

namespace Mdtt

/-- ℰ: 错误上下文 (规范 §4.5). T1 层以 `String` 承载错误信息. -/
abbrev ℰ (α : Type) := Except String α

/-- 共享类型宇宙 (规范 §4.6): 所有语言共用的类型语法.

构造子中只出现 `String` 语言标签与递归的 `Ty`, 保证 `Ty : Type` (无 universe 逃生舱).
- `code L τ` / `ast L τ` / `raw L`: 代码与 AST 是一等类型 (含 Raw-AST 锚点, 服务 §7.3 反射假设);
- `static`: 静态数据锚点 (原规范记 StaticInput);
- `compiler S T`: 宿主的"编译器接口"锚点 (服务 §7.2 的 𝒞^H⟨Compiler⟨S,T⟩⟩). -/
inductive Ty where
  | nat
  | bool
  | str
  | arr (a b : Ty)
  | code (L : String) (τ : Ty)
  | ast (L : String) (τ : Ty)
  | raw (L : String)
  | static
  | compiler (S T : String)
  deriving Repr

/-- 一个 MDTT 模型: 语言宇宙 + 宿主 + 类型构造器 + 算子 + 语义锚点 (规范 §4/§5 的签名级转录).

字段与规范对照:
- `lang`/`host`/`lang_id`: ℒ 与 M (§2); `lang_id` 把模型的语言映射到共享宇宙 `Ty` 的标签;
- `src`/`raw`/`tast`/`code`/`sem`: §4.1-4.4 类型构造器 与 §4.6 解释函数 ⟦τ⟧^L;
- `liftable*`: §2 类型约束 Liftable, 基础类型默认满足;
- `parse`/`elaborate`/`emit`/`lift`/`mix`/`run`/`eval`: §5.1-5.7 核心算子 (签名照抄, 语义由模型给出);
- `quote`/`embed_raw`: §7.3 所需的反射原语 (静态值的引式表示; Raw AST 字面量嵌入);
- `sem_*`: 语义锚点等式 (§4.6 解释函数应满足的契约), T2 实例化时需逐一兑现. -/
structure Model where
  /-- ℒ: 语言 (及其平台) 的宇宙. -/
  lang : Type
  /-- M: 当前宿主语言 (持有执行环境). -/
  host : lang
  /-- 语言 → 共享宇宙标签. -/
  lang_id : lang → String
  src : lang → Type
  raw : lang → Type
  tast : lang → Ty → Type
  code : lang → Ty → Type
  /-- ⟦τ⟧^L: 各语言对共享类型宇宙的解释. -/
  sem : lang → Ty → Type
  /-- Liftable(τ) 约束 (§2). -/
  liftable : Ty → Prop
  liftable_nat : liftable .nat
  liftable_bool : liftable .bool
  liftable_str : liftable .str
  /-- §5.1 parse^L : 𝒮^L → ℰ⟨𝒜^L⟩ -/
  parse : (L : lang) → src L → ℰ (raw L)
  /-- §5.2 elaborate^L : 𝒜^L → ℰ⟨Στ. 𝒜^L⟨τ⟩⟩ -/
  elaborate : (L : lang) → raw L → ℰ (Σ τ : Ty, tast L τ)
  /-- §5.3 emit_S^T : 𝒜^S⟨τ⟩ → 𝒞^T⟨τ⟩ (S = T 时为序列化, S ≠ T 时含翻译) -/
  emit : (S T : lang) → {τ : Ty} → tast S τ → code T τ
  /-- §5.4 ↑_M^L : ∀τ:Liftable. τ^M → 𝒞^L⟨τ⟩ (输入是宿主解释 τ^M) -/
  lift : (L : lang) → {τ : Ty} → liftable τ → sem host τ → code L τ
  /-- §5.5 𝔐_M^L : 𝒞^L⟨α→β⟩ → 𝒜^L⟨α⟩ → 𝒞^L⟨β⟩ (柯里化) -/
  mix : (L : lang) → {α β : Ty} → code L (.arr α β) → tast L α → code L β
  /-- §5.6 run_M : 𝒞^M⟨τ⟩ → ℰ⟨τ⟩ (仅宿主同构执行) -/
  run : {τ : Ty} → code host τ → ℰ (sem host τ)
  /-- §5.7 eval_M^L : 𝒜^L⟨τ⟩ → ℰ⟨τ^M⟩ (输出是宿主解释 τ^M) -/
  eval : (L : lang) → {τ : Ty} → tast L τ → ℰ (sem host τ)
  /-- §7.3 反射原语: 静态值的引式表示, `.<e>.` 的 AST 层面对应物. -/
  quote : (L : lang) → {τ : Ty} → tast L τ → tast L (.ast (lang_id L) τ)
  /-- §7.3 反射原语: Raw AST 作为对象语言的字面量嵌入 (反射假设的实现载体). -/
  embed_raw : (L : lang) → raw L → tast L (.raw (lang_id L))
  /-- 语义锚点: ⟦α→β⟧^L = ⟦α⟧^L → ⟦β⟧^L -/
  sem_arr : ∀ (L : lang) (a b : Ty), sem L (.arr a b) = (sem L a → sem L b)
  /-- 语义锚点: 宿主读到 L-代码值 -/
  sem_code : ∀ (L : lang) (τ : Ty), sem host (.code (lang_id L) τ) = code L τ
  /-- 语义锚点: 宿主读到 L-Typed-AST 值 -/
  sem_ast : ∀ (L : lang) (τ : Ty), sem host (.ast (lang_id L) τ) = tast L τ
  /-- 语义锚点: 宿主读到 L-Raw-AST 值 -/
  sem_raw : ∀ (L : lang), sem host (.raw (lang_id L)) = raw L
  /-- 语义锚点: 编译器接口类型的宿主解释 (§7.1 类型别名) -/
  sem_compiler : ∀ (S T : lang),
    sem host (.compiler (lang_id S) (lang_id T)) = (∀ τ : Ty, tast S τ → code T τ)

namespace Model

/-- 在函数语义锚点上应用: ⟦α→β⟧^L 的值作用于 ⟦α⟧^L 的值. -/
def applyArr (m : Model) {L : m.lang} {a b : Ty}
    (f : m.sem L (.arr a b)) (x : m.sem L a) : m.sem L b :=
  cast (m.sem_arr L a b) f x

/-- 展开 𝒞^M⟨Compiler⟨S,T⟩⟩ 运行结果的函数性 (§7.2 类型检查的关键一步). -/
def unrollCompiler (m : Model) (S T : m.lang) :
    m.sem m.host (.compiler (m.lang_id S) (m.lang_id T)) → (∀ τ : Ty, m.tast S τ → m.code T τ) :=
  cast (m.sem_compiler S T)

end Model

/-- Kleisli 组合 (§7.1): (f ≫ g)(x) ≡ f(x) bind g. -/
def kleisli {α β γ : Type} (f : α → ℰ β) (g : β → ℰ γ) : α → ℰ γ := fun a => (f a).bind g

scoped infixl:55 " ≫ " => kleisli

end Mdtt
