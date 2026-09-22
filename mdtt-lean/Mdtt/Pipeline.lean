import Mdtt.Model
/-!
# Mdtt.Pipeline — 编译器与解释器管线 (规范 §7.1)

职责边界: 定义 §7.1 的类型别名 (Compiler/Interpreter, v0.8 的 ∀τ 类型保持形式)
与完整管线 (fullCompiler/fullInterpreter, 诚实携带 Στ 的输出类型),
以及核心定义 (coreCompiler/coreInterpreter).

-/

namespace Mdtt



variable (m : Model)

/-- §7.1 类型别名: Compiler⟨S,T⟩ ≡ ∀τ. 𝒜^S⟨τ⟩ → 𝒞^T⟨τ⟩ (类型保持编译作为类型命题). -/
def Compiler (S T : m.lang) : Type := ∀ τ : Ty, m.tast S τ → m.code T τ

/-- §7.1 类型别名: Interpreter⟨S⟩ ≡ ∀τ. 𝒜^S⟨τ⟩ → ℰ⟨τ^M⟩. -/
def Interpreter (S : m.lang) : Type := ∀ τ : Ty, m.tast S τ → ℰ (m.sem m.host τ)

/-- §7.1 完整编译器: parse ≫ elaborate ≫ (pure ∘ emit).
输出 ℰ⟨Στ. 𝒞^T⟨τ⟩⟩ —— 类型参数由定型结果给出 (v0.8 修正). -/
def fullCompiler (S T : m.lang) : m.src S → ℰ (Σ τ : Ty, m.code T τ) :=
  m.parse S ≫ m.elaborate S ≫ fun ⟨τ, a⟩ => pure ⟨τ, m.emit S T a⟩

/-- §7.1 完整解释器: parse ≫ elaborate ≫ eval. 输出 ℰ⟨Στ. τ^M⟩. -/
def fullInterpreter (S : m.lang) : m.src S → ℰ (Σ τ : Ty, m.sem m.host τ) :=
  m.parse S ≫ m.elaborate S ≫ fun ta => (m.eval S ta.2).map fun v => ⟨ta.1, v⟩

/-- §7.1 核心定义: coreCompiler ≡ emit. -/
def coreCompiler (S T : m.lang) {τ : Ty} : m.tast S τ → m.code T τ := m.emit S T

/-- §7.1 核心定义: coreInterpreter ≡ eval. -/
def coreInterpreter (S : m.lang) {τ : Ty} : m.tast S τ → ℰ (m.sem m.host τ) := m.eval S

end Mdtt