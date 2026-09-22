import Mdtt.Stlc.Sexpr
import Mdtt.Stlc.Term
/-!
# Mdtt.Stlc.Elab — 定型器 (T2: 规范 §5.2 elaborate 的实现)

职责边界: 将 SExpr (Raw AST) 双向检查为 Στ. Term (Typed AST):
名字 → de Bruijn 转换, λ 需类型注解, 字面量/应用可合成; 自由变量报错.

实现采用显式 match (非 do/非 partial) 且对 SExpr 结构递归 —— 保证 kernel-可归约,
测试可用 `rfl` 获得内核级验证.
-/

namespace Mdtt.Stlc

/-- 类型语法: Nat | Bool | Str | (-> τ σ). -/
def parseTy : SExpr → ℰ Ty
  | .atom "Nat" => .ok .nat
  | .atom "Bool" => .ok .bool
  | .atom "Str" => .ok .str
  | .list [.atom "->", a, b] =>
    match parseTy a with
    | .error e => .error e
    | .ok ta => match parseTy b with
      | .error e => .error e
      | .ok tb => .ok (.arr ta tb)
  | s => .error s!"type: unrecognized {repr s}"

/-- 按名字查找 de Bruijn 索引 (从内层向外层). -/
def findVar : (Γ : List Ty) → (names : List String) → String → Option (Σ τ : Ty, HasTy Γ τ)
  | _, [], _ => none
  | σ :: Γ', n :: ns, x =>
    if n = x then some ⟨σ, .here⟩
    else (findVar Γ' ns x).map fun ⟨τ, i⟩ => ⟨τ, .there i⟩
  | [], _ :: _, _ => none

/-- 数字解析 (List Char 实现, kernel-可归约; `String.toNat?` 对内核不透明). -/
def strToNat? (s : String) : Option Nat :=
  let rec go : List Char → Nat → Option Nat
    | [], acc => some acc
    | c :: rest, acc => if c.isDigit then go rest (acc * 10 + (c.toNat - '0'.toNat)) else none
  if s.isEmpty then none else go s.toList 0

/-- 字符串字面量判定与剥壳 (首尾双引号). -/
def strLitBody : List Char → Option String
  | [] => none
  | c1 :: rest =>
    if c1 != '"' then none
    else match rest.reverse with
      | c2 :: inner => if c2 != '"' then none else some (String.ofList inner.reverse)
      | [] => none

/-- 原子字面量判别: 自然数 / 布尔 / 字符串字面量, 否则为变量. -/
def elabAtom : (Γ : List Ty) → (names : List String) → String → ℰ (Σ τ : Ty, Term Γ τ)
  | Γ, names, a =>
    match strToNat? a with
    | some n => .ok ⟨.nat, .lit n⟩
    | none =>
      if a = "#t" then .ok ⟨.bool, .bool true⟩
      else if a = "#f" then .ok ⟨.bool, .bool false⟩
      else match strLitBody a.toList with
      | some body => .ok ⟨.str, .str body⟩
      | none =>
        match findVar Γ names a with
        | some ⟨τ, i⟩ => .ok ⟨τ, .var i⟩
        | none => .error s!"elab: unbound variable '{a}'"

/-- 定型器主体 (规范 §5.2): 对 SExpr 结构递归. -/
def elabTerm : (Γ : List Ty) → (names : List String) → SExpr → ℰ (Σ τ : Ty, Term Γ τ)
  | Γ, names, .atom a => elabAtom Γ names a
  | Γ, names, .list (.atom "lambda" :: [.list [.atom x, .atom ":", τs], body]) =>
    match parseTy τs with
    | .error e => .error e
    | .ok τ₁ =>
      match elabTerm (τ₁ :: Γ) (x :: names) body with
      | .error e => .error e
      | .ok ⟨τ₂, b⟩ => .ok ⟨.arr τ₁ τ₂, .lam τ₁ b⟩
  | Γ, names, .list [.atom "+", a, b] =>
    match elabTerm Γ names a, elabTerm Γ names b with
    | .ok ⟨.nat, ta⟩, .ok ⟨.nat, tb⟩ => .ok ⟨.nat, .add ta tb⟩
    | .error e, _ => .error e
    | _, .error e => .error e
    | _, _ => .error "elab: + requires Nat operands"
  | Γ, names, .list [f, a] =>
    match elabTerm Γ names f, elabTerm Γ names a with
    | .ok ⟨.arr τ₁ τ₂, tf⟩, .ok ⟨τa, ta⟩ =>
      if h : τa = τ₁ then .ok ⟨τ₂, .app tf (h ▸ ta)⟩
      else .error s!"elab: type mismatch {repr τa} ≠ {repr τ₁}"
    | .error e, _ => .error e
    | _, .error e => .error e
    | _, _ => .error "elab: applying non-function"
  | _, _, s => .error s!"elab: unsupported form {repr s}"

/-- 顶层定型: 闭环上下文 (规范 §5.2 的入口签名 𝒜^L → ℰ⟨Στ. 𝒜^L⟨τ⟩⟩). -/
def elaborateStlc (s : SExpr) : ℰ (Σ τ : Ty, Term [] τ) := elabTerm [] [] s

end Mdtt.Stlc
