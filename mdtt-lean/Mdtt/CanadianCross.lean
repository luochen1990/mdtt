import Mdtt.Model
/-!
# Mdtt.CanadianCross — 加拿大交叉编译 (规范 §7.2)

职责边界: 形式化 §7.2 的构建推导, 并给出类型检查层面的 "Shift" 现象解释.

要点 (v0.8 精确化, 由 T1 形式化发现):
- 推导语境中 B ≡ M (Build 即当前宿主, §3.1), 故 run_B 就是 Model.run (T-Run 的同构约束);
- 编译器源码必须**定型于锚点类型 Compiler⟨S,T⟩**: source : 𝒜^L⟨Compiler⟨S,T⟩⟩,
  这样 run builder 的函数结果才能在 τ := Compiler⟨S,T⟩ 处实例化并作用于 source;
- 环境泄露 (Environment Leakage) 在类型层面被静态排除: 未经过 lift (T-Lift, Liftable 约束)
  的宿主数据无法进入 𝒞^H —— 违规项在此签名下不可构造.

-/


open Mdtt

variable {m : Model}

/-- Builder 的类型 (§7.2): 𝒞^B⟨Compiler⟨L,H⟩⟩, 其中 B ≡ M = m.host. -/
def Builder (L H : m.lang) : Type := m.code m.host (Ty.compiler (m.lang_id L) (m.lang_id H))

/-- 目标产物类型 (§7.2): 𝒞^H⟨Compiler⟨S,T⟩⟩. -/
def Goal (S H T : m.lang) : Type := m.code H (Ty.compiler (m.lang_id S) (m.lang_id T))

/-- §7.2 构建过程: artifact = run_B(builder) source.

run builder : ℰ⟨Compiler⟨L,H⟩⟩ = ℰ⟨∀τ. 𝒜^L⟨τ⟩ → 𝒞^H⟨τ⟩⟩,
在 τ := Compiler⟨S,T⟩ 处实例化后作用于已定型的编译器源码, 得到 𝒞^H⟨Compiler⟨S,T⟩⟩.
"builder 的目标属性 (H) 决定产物的宿主属性 (H)" —— 这就是 Shift.
-/
def buildArtifact {S L H T : m.lang}
    (source : m.tast L (Ty.compiler (m.lang_id S) (m.lang_id T)))
    (builder : Builder L H) : ℰ (Goal S H T) := do
  let f ← m.run builder
  pure (m.unrollCompiler L H f (Ty.compiler (m.lang_id S) (m.lang_id T)) source)
