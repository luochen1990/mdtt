import Mdtt.Stlc.Sexpr
/-!
# Mdtt.Stlc.Term — 良作用域的 Typed AST (T2: STLC 的 Tast 层)

职责边界: 定义 de Bruijn 良作用域的 `Term` (规范 𝒜^stlc⟨τ⟩ 的载体) 与上下索引 `HasTy`.

除标准 STLC 构造子外, 还包含**反射构造子** (quoted / rawAst / staticLit):
这是规范 §7.3 反射假设的实现载体 —— 对象语言必须能谈论"自身的 AST 作为数据",
否则 quote / embed_raw 两个 Model 原语无处安放. 反射构造子只面向宿主消费
(求值时直接返回数据本身), 不参与 parse/elaborate 的源语法.
-/

namespace Mdtt.Stlc

/-- 上下文索引: Γ ∋ τ (de Bruijn). -/
inductive HasTy : List Ty → Ty → Type where
  | here {Γ τ} : HasTy (τ :: Γ) τ
  | there {Γ τ σ} (i : HasTy Γ τ) : HasTy (σ :: Γ) τ

/-- Typed AST (de Bruijn, 良作用域): 索引即其类型 —— 构造即定型 (zero-overhead safety). -/
inductive Term : List Ty → Ty → Type where
  | var {Γ τ} (i : HasTy Γ τ) : Term Γ τ
  | lit (n : Nat) : Term Γ .nat
  | bool (b : Bool) : Term Γ .bool
  | str (s : String) : Term Γ .str
  | add {Γ} (a b : Term Γ .nat) : Term Γ .nat
  | lam {Γ} (τ₁ : Ty) {τ₂} (body : Term (τ₁ :: Γ) τ₂) : Term Γ (.arr τ₁ τ₂)
  | app {Γ} {τ₁ τ₂} (f : Term Γ (.arr τ₁ τ₂)) (a : Term Γ τ₁) : Term Γ τ₂
  /-- 反射构造子: quote —— "计算出一个 Typed AST" 的程序 (规范 §7.3).
  仅允许引式化**闭环**程序 (开项的反射需依赖更深的 staging 理论, 见规范 §7.3 注). -/
  | quoted {Γ τ} (t : Term [] τ) : Term Γ (.ast "stlc" τ)
  /-- 反射构造子: Raw AST 字面量 (embed_raw 的落点). -/
  | rawAst {Γ} (s : SExpr) : Term Γ (.raw "stlc")
  /-- 反射构造子: 静态数据字面量. -/
  | staticLit {Γ} (s : String) : Term Γ .static

end Mdtt.Stlc
