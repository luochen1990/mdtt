import Mdtt.Stlc.Term
/-!
# Mdtt.Stlc.Sem — 宿主语义与 NbE 求值器 (T2: stlcModel 的 Sem/eval 层)

职责边界: 定义 hostSem (共享宇宙 ⟦τ⟧ 的 stlc 模型解释, 单一自包含结构递归)
以及基于函数空间的 NbE 求值器.

关键性质: **闭环 Typed AST 的求值恒成功** (强规范化由构造保证),
对应规范宣称的 zero-overhead safety.

设计说明 (compiler 死分支): `∀τ` 量词下对 `hostSem τ` 的引用是非结构递归,
hostSem 无法如此自指; Lean 4 亦不支持归纳-递归 (mutual inductive+def),
故 `.compiler` 在 hostSem 中为死分支 (Unit), 模型层经 `unroll_compiler`
字段以见证令牌 + emit 重构的方式满足 Model 的编译器接口 (见 Stlc/Model.lean);
忠实载体建模 (unroll∘roll 双射) 列为未来工作.
-/

namespace Mdtt.Stlc

/-- ⟦τ⟧^stlcModel: 共享宇宙在 (Lean=host, stlc) 两语言世界中的统一解释.

- `code "stlc" τ` = String (stlc 代码 = 序列化文本, 黑盒);
- `code "host" τ` = ℰ ⟦τ⟧ (宿主代码 = 活的宿主计算, `run` 的实现基础);
- `ast "stlc" τ` = Term [] τ (闭环 Typed AST); `ast "host" τ` = 宿主程序即宿主值;
- `compiler S T` = Unit **死分支** (hostSem 单独使用时不可达; 模型层经
  `unroll_compiler` 字段以见证令牌 + emit 重构方式旁路满足, 见 Stlc/Model.lean).
-/
def hostSem : Ty → Type
  | .nat => Nat
  | .bool => Bool
  | .str => String
  | .arr a b => hostSem a → hostSem b
  | .code L τ => match L with
    | "stlc" => String
    | _ => ℰ (hostSem τ)
  | .ast L τ => match L with
    | "stlc" => Term [] τ
    | _ => hostSem τ
  | .raw L => match L with
    | "stlc" => SExpr
    | _ => String
  | .static => String
  | .compiler _ _ => Unit

/-- NbE 环境: 按 de Bruijn 上下文存放宿主语义值. -/
inductive Env : List Ty → Type where
  | nil : Env []
  | cons : hostSem τ → Env Γ → Env (τ :: Γ)

/-- 环境查找. -/
def Env.lookup : Env Γ → HasTy Γ τ → hostSem τ
  | cons v _, .here => v
  | cons _ e, .there i => e.lookup i

/-- NbE 求值: 把 Typed AST 解释为宿主语义值 (规范 §5.7 eval 的实现).
反射构造子的求值即"返回数据本身" —— 宿主读到 AST/静态数据原样. -/
def nbe (env : Env Γ) : Term Γ τ → hostSem τ
  | .var i => env.lookup i
  | .lit n => n
  | .bool b => b
  | .str s => s
  | .add a b => Nat.add (nbe env a) (nbe env b)
  | .lam _ body => fun x => nbe (env.cons x) body
  | .app f a => nbe env f (nbe env a)
  | .quoted t => t
  | .rawAst s => s
  | .staticLit s => s

/-- 闭环 Typed AST 的求值是全函数 (恒成功) —— 由构造保证, 无需运行时检查. -/
def evalClosed (t : Term [] τ) : ℰ (hostSem τ) := .ok (nbe .nil t)

end Mdtt.Stlc
