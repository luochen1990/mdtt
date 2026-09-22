import Mdtt.Stlc.Emit
/-!
# Mdtt.Stlc.Model — stlcModel: MDTT Model 的具体实例 (T2 交付主体)

职责边界: 构造 `stlcModel : Mdtt.Model` —— 证明 T1 的全部签名可被真实满足:
- 语言宇宙 MLang = {host (Lean 自身), stlc};
- 所有算子 (parse/elaborate/emit/lift/mix/run/eval/quote/embed_raw) 均为真实实现;
- 语义锚点等式以 rfl (逐语言分情况) 兑现.

**PoC 级简化 (诚实声明)**: 编译器接口 (`.compiler` 锚点类型) 采用
**见证令牌载体 + unroll 重构**: `sem host (compiler S T)` 的宿主读值为 Unit 令牌,
`unroll_compiler` 忽略令牌、直接以 emit 逻辑重构编译功能.
原因: ∀τ 量词下的 hostSem 自指是非结构递归, 而 Lean 4 不支持归纳-递归,
忠实的载体建模 (载体 ≡ 编译函数的双射) 无法在此架构下定义 —— 这是 T2 的
一项正式发现, 忠实建模列为未来工作 (见 mdtt-lean/AGENTS.md).

模型语义约定 (同样记录于 mdtt-lean/AGENTS.md):
- stlc 代码 = 序列化文本 (黑盒), 宿主代码 = 活的宿主计算 (run := id);
- stlc→host 的 emit 即"现在就解释运行" (evalClosed), host→stlc 的 lift 遵循黑盒降级;
- 各语言对共享宇宙的语义解释统一为 hostSem (本模型两语言值域同构).
-/

namespace Mdtt

open Stlc

/-- stlc 模型的语言宇宙. -/
inductive MLang where
  | host
  | stlc
  deriving Repr

/-- 语言 → 共享宇宙标签 (Ty 构造子中的 String). -/
def MLang.tag : MLang → String
  | .host => "host"
  | .stlc => "stlc"

/-- 两语言的 Tast 载体: stlc 用 Typed AST, host 即宿主值 (宿主程序即宿主值). -/
def mlTast (L : MLang) : Ty → Type :=
  match L with
  | .stlc => fun τ => Term [] τ
  | .host => hostSem

/-- 两语言的 Code 载体: stlc 代码为序列化文本 (黑盒), host 代码为活的宿主计算. -/
def mlCode (L : MLang) : Ty → Type :=
  match L with
  | .stlc => fun _ => String
  | .host => fun τ => ℰ (hostSem τ)

/-- 统一发射分派 (2×2 语言矩阵), 是模型语义约定的结构化身:
lift/eval/unroll_compiler 均为 mlEmit 在特定语言参数处的实例 (定义性相等) ——
"stlc→host 的 emit 即现在就解释运行" 由构造保证 eval = emit(·, host). -/
def mlEmit : (S T : MLang) → (τ : Ty) → mlTast S τ → mlCode T τ
  | .stlc, .stlc, _, t => emitStlc t
  | .stlc, .host, _, t => evalClosed t
  | .host, .stlc, τ, v => liftStlc τ v
  | .host, .host, _, v => pure v

/-- T2 主交付: MDTT 模型的 STLC 实例. -/
def stlcModel : Model where
  lang := MLang
  host := .host
  lang_id := MLang.tag
  src := fun _ => String
  raw := fun
    | .stlc => SExpr
    | .host => String
  tast := mlTast
  code := mlCode
  sem := fun _ τ => hostSem τ
  liftable := fun
    | .nat | .bool | .str => True
    | _ => False
  liftable_nat := True.intro
  liftable_bool := True.intro
  liftable_str := True.intro
  parse := fun
    | .stlc, s => Stlc.parse s
    | .host, _ => .error "parse: host source unsupported in stlcModel"
  elaborate := fun
    | .stlc, r => elaborateStlc r
    | .host, _ => .error "elaborate: host raw unsupported in stlcModel"
  emit := fun S T {_} t => mlEmit S T _ t
  /- lift = emit(host→L), eval = emit(L→host): 由 mlEmit 的矩阵分派定义性给出. -/
  lift := fun L {_τ} _h v => mlEmit .host L _ v
  eval := fun L {_} t => mlEmit L .host _ t
  mix := fun L {_ _} f x =>
    match L with
    | .stlc => mixStlc f x
    | .host => f <*> pure x
  run := fun c => c
  quote := fun L {_} t =>
    match L with
    | .stlc => Term.quoted t
    | .host => t
  embed_raw := fun L r =>
    match L with
    | .stlc => Term.rawAst r
    | .host => r
  sem_arr := fun _ _ _ => rfl
  sem_code := fun
    | .stlc, _ => rfl
    | .host, _ => rfl
  sem_ast := fun
    | .stlc, _ => rfl
    | .host, _ => rfl
  sem_raw := fun
    | .stlc => rfl
    | .host => rfl
  unroll_compiler := fun _ _ _ τ t => mlEmit _ _ τ t
  roll_compiler := fun _ _ _ => ()

end Mdtt
