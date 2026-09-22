# mdtt-lean 实现指南 (AGENTS.md)

> 受众: **维护者**。实现决策、逻辑契约、行为准则。使用者接口见本目录 [README.md](README.md)。

## 术语表

| 术语 | 含义 |
| :--- | :--- |
| T1 / T2 | 签名级形式化 (任意 Model 的定理) / 实例级形式化 (stlcModel 具体实现) |
| Model | 打包一个"多阶段世界"全部签名的记录 (语言宇宙 + 算子 + 语义锚点) |
| 共享宇宙 `Ty` | 规范 §4.6: 所有语言共用的类型语法, 语言以 String 标签指称 |
| 语义锚点 | Model 的 `sem_arr/sem_code/sem_ast/sem_raw` 等式字段 (stlcModel 中以 rfl 兑现) |
| 编译器载体 | `.compiler` 锚点类型的读值 (stlcModel 中为见证令牌, 见"已知简化") |
| kernel-可归约 | 定义可在 Lean 内核中 whnf 展开 (`rfl` 可用), 区别于仅编译器可执行 |
| 反射构造子 | `Term.quoted/rawAst/staticLit`: 规范 §7.3 反射假设的实现载体 |

## 技术选型

- **Lean 4.30.0** (`lean-toolchain` 权威固定, elan 解析; devShell 只提供 elan+just)。
- **Model-Record 架构** (而非散装 axiom / opaque): T2 可构造 `stlcModel : Model` 完整实例,
  Lean 无"事后实例化 opaque"的困境被彻底规避。
- **零依赖 lake 项目** (无 mathlib): 保证构建快速、可复现。
- **kernel-可归约优先**: 测试分两级 —— `rfl` (内核级, 类型检查即证明) 与
  `native_decide` (编译期执行, 用于全管线; 因内核 String 归约代价过高)。

## 核心抽象与模块职责边界

```
Mdtt/Model.lean          共享宇宙 Ty + ℰ + Model 记录 (全部签名的 SSOT)
Mdtt/Rules.lean          §6 七条定型规则的逐条转录 (def, 规则即类型)
Mdtt/Pipeline.lean       §7.1 Compiler/Interpreter 别名 + fullCompiler/fullInterpreter
Mdtt/CanadianCross.lean  §7.2 buildArtifact + Builder/Goal
Mdtt/Futamura.lean       §7.3 三个二村映射
Mdtt/Bootstrapping.lean  §7.4 自举三阶段 + 不动点定理
Mdtt/Stlc/Sexpr.lean     SExpr + tokenize + 燃料驱动括号解析器
Mdtt/Stlc/Term.lean      de Bruijn 良作用域 Term (构造即定型)
Mdtt/Stlc/Sem.lean       hostSem (共享宇宙解释) + Env + NbE 求值器
Mdtt/Stlc/Elab.lean      定型器 (名字→de Bruijn, 双向检查)
Mdtt/Stlc/Emit.lean      toSExpr/tySExpr 序列化 + liftStlc + mixStlc
Mdtt/Stlc/Model.lean     stlcModel : Model 的组装 (锚点以 rfl 兑现)
Mdtt/Stlc/Tests.lean     验证集 (rfl 内核级 + native_decide 管线级)
```

依赖方向: Model → {Sexpr → Term → Sem → Elab → Emit → Model(stlc) → Tests},
T1 五个案例文件仅依赖 Model.lean。禁止反向依赖。

## 逻辑契约 (为何代码长这样)

1. **Ty 只存 String 标签**: 保持 `Ty : Type` 无 universe 逃生舱; Model 以 `lang_id`
   把自己的语言宇宙映射到标签 (规范 §4.6 的"共享宇宙 + 各语言解释"决策)。
2. **kernel-可归约三条铁律** (违反则 `rfl` 测试静默失效):
   - 递归勿经 `List.map`/`foldl` 等高阶函数 (编译成 WF-递归, 内核不可归约;
     `sexprStr` 的 `where goSpaces` 即为此改造);
   - 勿用 `String.toNat?` / `String.drop` 等对内核不透明的核心函数
     (用 `List Char` 自实现, 如 `strToNat?`/`strLitBody`);
   - 求值器对 SExpr/Term **结构递归**, 解析器用**燃料** (token 流消耗非结构可证);
   - `hostSem τ` 等非 reducible def 之上的类型类综合 (OfNat/ToString/HAdd) 会失败,
     须以 `@id Nat x` 之类强制 defeq 归约 (见 `liftStlc` 的注释)。
3. **TAST 即索引归纳族**: `Term : List Ty → Ty → Type`, de Bruijn 良作用域,
   类型安全由构造保证 (eval 全定义性 `rfl` 即得, zero-overhead safety)。
4. **quote 仅限闭环项** (`quoted : Term [] τ → Term Γ (ast τ)`):
   开项反射需要更深的 staging 理论 (规范 §7.3 注)。

## 已知简化与未来工作 (PoC 级诚实声明)

| 项 | 现状 | 未来 |
| :--- | :--- | :--- |
| 编译器载体 | 见证令牌 (Unit) + unroll 以 emit 逻辑重构; 因 ∀τ 量词下 hostSem 自指是非结构递归且 Lean 4 无归纳-递归 | 忠实载体建模 (如外置 CompilerCarrier 双射, 需重构 Model 的 unroll/roll 字位) |
| mix (§5.5) | 文本拼接残差 `(f x)` (β-可归约形式) | 真部分求值归约 |
| roundtrip | 语料级 rfl (tId/tAdd/tHO) | 一般定理 (按深度命名不变量归纳) |
| §7.2 stlcModel 演示 | 依赖编译器载体忠实建模, 暂缺 | 随载体建模补齐 |
| eval 的 IO 交互 | 纯 eval (规范 v0.8 注记) | IO 组合层 |
| 字符串字面量词法 | 不支持内嵌空格/括号/冒号 (按词法切分), 空串与普通串可用 | 转义词法 |

## 行为准则

- **零 sorry、零自定义 axiom** (Model 字段即"公理载体"这一设计除外);
  stlcModel 仅依赖 Lean 标准三公理 (propext/Classical.choice/Quot.sound, 来自 deriving)。
- 修改规范 (README.md) 时**必须**同步 Model.lean 的签名与符号映射表 (README.md),
  反之亦然 —— 规范与代码互为 SSOT。
- 提交前 `just check` 全绿零警告; 新增算子行为必须有 Tests.lean 对应断言。
- `native_decide` example 由编译器执行背书 (生成 per-declaration axiom),
  **不属内核保证**; 能 `rfl` 的优先 `rfl`。
- 命名: 类型 PascalCase, 项 snake_case (Lean 惯例); 文件头部注明职责边界与对应规范章节。
