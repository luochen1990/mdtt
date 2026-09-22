import Mdtt.Stlc.Sem
import Mdtt.Stlc.Elab
/-!
# Mdtt.Stlc.Emit — 序列化与各语言发射 (T2: 规范 §5.3 emit / §5.4 lift / §5.5 mix 的实现)

职责边界: Typed AST → S-表达式 → 文本 (S = T 的序列化发射);
宿主值 → 字面量代码 (lift); 代码 × 静态 AST → 文本残差 (mix).

设计说明:
- mix 的残差为 **β-可归约形式** (`(f x)`) —— 即部分求值归约前的残差程序,
  完整的部分求值归约 (消除静态调用) 属未来工作;
- 宿主函数值无法反射为 stlc 文本, lift 到非基础类型时降级为 `(foreign)` 占位 ——
  这恰好体现规范 §4.4 的 Code 黑盒性.
-/

namespace Mdtt.Stlc

/-- 共享宇宙的类型打印 (STLC 相关子集精确打印, 锚点类型打印为尖括号占位). -/
def tyStr : Ty → String
  | .nat => "Nat"
  | .bool => "Bool"
  | .str => "Str"
  | .arr a b => s!"(-> {tyStr a} {tyStr b})"
  | _ => "<ty>"

/-- 类型的结构化 SExpr (可被 parseTy 重新解析; 与 tyStr 的文本形式保持一致). -/
def tySExpr : Ty → SExpr
  | .nat => .atom "Nat"
  | .bool => .atom "Bool"
  | .str => .atom "Str"
  | .arr a b => .list [.atom "->", tySExpr a, tySExpr b]
  | τ => .atom (tyStr τ)

/-- de Bruijn 索引的自然数编码. -/
def hasTyIdx : HasTy Γ τ → Nat
  | .here => 0
  | .there i => hasTyIdx i + 1

/-- Term → SExpr (结构序列化).
绑定名按**深度**生成 (v0, v1, ...): 深度 d 处引入的绑定名为 v{d},
深度 d' 处索引为 i 的变量回指绑定 v{d' - i - 1} —— 同一作用域路径内永不重名
(兄弟分支可同名, 查找按分支独立, 不引入歧义), 保证 parse∘elaborate 往返唯一解析. -/
def toSExprAux : (d : Nat) → Term Γ τ → SExpr
  | d, .var i => .atom s!"v{d - hasTyIdx i - 1}"
  | _, .lit n => .atom (toString n)
  | _, .bool b => .atom (if b then "#t" else "#f")
  | _, .str s => .atom s!"\"{s}\""
  | d, .add a b => .list [.atom "+", toSExprAux d a, toSExprAux d b]
  | d, .lam τ₁ body =>
    .list [.atom "lambda", .list [.atom s!"v{d}", .atom ":", tySExpr τ₁],
      toSExprAux (d + 1) body]
  | d, .app f a => .list [toSExprAux d f, toSExprAux d a]
  | _, .quoted t => .list [.atom "quote", toSExprAux 0 t]
  | _, .rawAst s => .list [.atom "raw-ast", s]
  | _, .staticLit s => .list [.atom "static", .atom s]

/-- S-表达式 → 文本 (结构递归: 经 List.map 的递归会被编译为 WF-递归, 对内核不透明). -/
def sexprStr : SExpr → String
  | .atom a => a
  | .list l => "(" ++ goSpaces l ++ ")"
where goSpaces : List SExpr → String
  | [] => ""
  | [e] => sexprStr e
  | e :: rest => sexprStr e ++ " " ++ goSpaces rest

/-- emit^stlc_stlc (S = T 序列化, 规范 §5.3). -/
def emitStlc (t : Term [] τ) : String := sexprStr (toSExprAux 0 t)

/-- 宿主值 → stlc 代码字面量 (规范 §5.4 lift 的 stlc 分支).
非基础类型降级为 `(foreign)` 占位 (黑盒性, 见文件头).
注: `@id Nat n` 是强制 defeq 归约的 trick —— `hostSem τ` 非 reducible def,
ToString 实例综合不展开它, 须先归约到具体类型. -/
def liftStlc : (τ : Ty) → hostSem τ → String
  | .nat, n => toString (@id Nat n)
  | .bool, b => if @id Bool b then "#t" else "#f"
  | .str, s => "\"" ++ @id String s ++ "\""
  | _, _ => "(foreign)"

/-- mix^stlc (规范 §5.5): 代码 f 与静态 AST x 的文本残差 `(f x)` (β-可归约形式). -/
def mixStlc {α : Ty} (f : String) (x : Term [] α) : String :=
  s!"({f} {emitStlc x})"

end Mdtt.Stlc
