import Mdtt.Stlc.Model
import Mdtt.Pipeline
import Mdtt.Futamura
/-!
# Mdtt.Stlc.Tests — T2 验证集

职责边界: 验证 stlcModel 的正确性. 两类手段:
- `rfl` 示例: **内核级**归约 (无 sorry/axiom, 类型检查即证明);
- `#guard_msgs` + `#eval`: **编译期执行**的确定性冒烟测试 —— 用于全管线
  (tokenize→parse→elaborate→nbe) 场景, 因内核对 String 操作的归约代价过高,
  管线级断言走编译器执行 (输出由 #guard_msgs 精确锁定, 仍是 CI 门禁).

覆盖: 字面量/高阶函数/字符串/错误路径; emit 往返; eval 全定义性; mix 残差;
反射构造子; 二村映射第一投影.
-/

namespace Mdtt.Stlc

open Mdtt

/-! ## 求值管线 (fullInterpreter, 规范 §7.1) — 编译期执行 -/

/-- 全管线求值到 Nat 的投影 (错误与类型不符显式呈现). -/
def interpNat (s : String) : String :=
  match fullInterpreter stlcModel .stlc s with
  | .error e => s!"ERR {e}"
  | .ok ⟨.nat, v⟩ => toString (@id Nat v)
  | .ok ⟨τ, _⟩ => s!"NOTNAT {repr τ}"

example : interpNat "((lambda (x : Nat) x) 42)" = "42" := by native_decide

example : interpNat "((lambda (x : Nat) (+ x 1)) 41)" = "42" := by native_decide

example :
    interpNat "((lambda (f : (-> Nat Nat)) (f 3)) (lambda (x : Nat) (+ x 1)))" = "4" := by
  native_decide

example : interpNat "((lambda (s : Str) ((lambda (x : Nat) s) 7)) \"hi\")" = "NOTNAT Mdtt.Ty.str" := by
  native_decide

example : interpNat "#t" = "NOTNAT Mdtt.Ty.bool" := by native_decide

example : interpNat "(unbound 1)" = "ERR elab: unbound variable 'unbound'" := by native_decide

example : interpNat "((lambda (x : Nat) x) #t)" = "ERR elab: type mismatch Mdtt.Ty.bool ≠ Mdtt.Ty.nat" := by
  native_decide

/-! ## 编译管线 (fullCompiler, 规范 §7.1): 序列化不归一 (β-可归约形式保留) -/

def compileStlc (s : String) : String :=
  match fullCompiler stlcModel .stlc .stlc s with
  | .error e => s!"ERR {e}"
  | .ok ⟨_, c⟩ => c

example : compileStlc "((lambda (x : Nat) x) 42)" = "((lambda (v0 : Nat) v0) 42)" := by native_decide

/-! ## emit 往返 (roundtrip): elaborate (toSExpr t) 恢复原项 (de Bruijn 下即语法等价) — 内核级 -/

def tId : Term [] (.arr .nat .nat) := .lam .nat (.var .here)

def tAdd : Term [] (.arr .nat (.arr .nat .nat)) :=
  .lam .nat (.lam .nat (.add (.var (.there .here)) (.var .here)))

def tHO : Term [] .nat :=
  .app (.lam (.arr .nat .nat) (.app (.var .here) (.lit 3))) (.lam .nat (.add (.var .here) (.lit 1)))

example : elaborateStlc (toSExprAux 0 tId) = .ok ⟨_, tId⟩ := rfl

example : elaborateStlc (toSExprAux 0 tAdd) = .ok ⟨_, tAdd⟩ := rfl

example : elaborateStlc (toSExprAux 0 tHO) = .ok ⟨_, tHO⟩ := rfl

/-! ## eval 全定义性: 闭环 Typed AST 求值恒成功 (zero-overhead safety) — 内核级 -/

example (τ : Ty) (t : Term [] τ) : stlcModel.eval .stlc t = .ok (nbe .nil t) := rfl

/-! ## mix 残差 (规范 §5.5): β-可归约形式 — 内核级 -/

/-- mix 的函数代码入参 (独立 def 以显式钉住 α = β = Nat). -/
def mixF : stlcModel.code .stlc (Ty.arr .nat .nat) := "(lambda (x : Nat) (+ x 1))"

example : stlcModel.mix .stlc mixF (.lit 41) = "((lambda (x : Nat) (+ x 1)) 41)" := rfl

/-! ## 反射构造子 (规范 §7.3 反射假设的实现载体) — 内核级 -/

/-- quote 的求值: 宿主读到的 Typed AST 即被引式的程序本身. -/
example : stlcModel.eval .stlc (Term.quoted tId) = .ok tId := rfl

/-- embed_raw 的求值: 宿主读到的 Raw AST 即字面量本身. -/
def raw42 : stlcModel.raw .stlc := .atom "42"

example : stlcModel.eval .stlc (stlcModel.embed_raw .stlc raw42) = .ok (.atom "42") := rfl

/-! ## 二村映射第一投影 (规范 §7.3): 特化管线 — 内核级 -/

/-- 第一映射的解释器代码入参 (τ := Nat 实例化); 烧录 quote(source) 得到 β-可归约残差. -/
def interpF : stlcModel.code .stlc (Ty.arr (Ty.ast "stlc" .nat) .nat) := "INTERP"

example : futamura1 (m := stlcModel) .stlc interpF (.lit 41) = "(INTERP (quote 41))" := rfl

end Mdtt.Stlc
