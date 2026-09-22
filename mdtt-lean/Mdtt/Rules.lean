import Mdtt.Model
/-!
# Mdtt.Rules — 定型规则 (规范 §6) 的逐条转录

职责边界: 将规范 §6 的七条定型规则 T-Parse … T-Eval 各自转录为一个 theorem.
它们是 Model 字段的直接重述 —— 目的不是证明, 而是让**类型检查器逐条核对**规范规则与
Lean 签名的一致性 (T1 层的价值所在: 规则若与签名冲突, 这里无法通过编译).

-/

namespace Mdtt


open Mdtt

variable (m : Model)

/-- T-Parse (§6): Γ ⊢ s : 𝒮^L ⊢ parse^L(s) : ℰ⟨𝒜^L⟩ -/
def tParse (L : m.lang) (s : m.src L) : ℰ (m.raw L) := m.parse L s

/-- T-Elaborate (§6): Γ ⊢ a : 𝒜^L ⊢ elaborate^L(a) : ℰ⟨Στ. 𝒜^L⟨τ⟩⟩ -/
def tElaborate (L : m.lang) (a : m.raw L) : ℰ (Σ τ : Ty, m.tast L τ) := m.elaborate L a

/-- T-Emit (§6): Γ ⊢ a : 𝒜^S⟨τ⟩ ⊢ emit_S^T(a) : 𝒞^T⟨τ⟩ -/
def tEmit (S T : m.lang) {τ : Ty} (a : m.tast S τ) : m.code T τ := m.emit S T a

/-- T-Lift (§6): Γ ⊢ v : τ^M ∧ τ ∈ Liftable ⊢ ↑_M^L v : 𝒞^L⟨τ⟩ -/
def tLift (L : m.lang) {τ : Ty} (h : m.liftable τ) (v : m.sem m.host τ) : m.code L τ :=
  m.lift L h v

/-- T-Mix (§6, v0.8 柯里化): Γ ⊢ f : 𝒞^L⟨α→β⟩ ⊢ x : 𝒜^L⟨α⟩ ⊢ 𝔐_M^L f x : 𝒞^L⟨β⟩ -/
def tMix (L : m.lang) {α β : Ty} (f : m.code L (.arr α β)) (x : m.tast L α) :
    m.code L β := m.mix L f x

/-- T-Run (§6): Γ ⊢ c : 𝒞^M⟨τ⟩ ⊢ run_M(c) : ℰ⟨τ⟩ (τ 即 τ^M, 宿主同构执行) -/
def tRun {τ : Ty} (c : m.code m.host τ) : ℰ (m.sem m.host τ) := m.run c

/-- T-Eval (§6): Γ ⊢ a : 𝒜^L⟨τ⟩ ⊢ eval_M^L(a) : ℰ⟨τ^M⟩ -/
def tEval (L : m.lang) {τ : Ty} (a : m.tast L τ) : ℰ (m.sem m.host τ) := m.eval L a

end Mdtt