# mdtt-lean — MDTT 的 Lean 4 形式化

> 读者范围 (scope): 想核对 MDTT 规范 (v0.8) 类型签名一致性的读者; 想在 Lean 中以
> "可执行 DSL" 方式使用 MDTT 概念的开发者; T2 实例 (Mdtt/Stlc.*) 的维护者.
> 实现细节与设计决策见本目录 [AGENTS.md](AGENTS.md) (维护者向).

本项目把 MDTT 规范 (v0.8) 形式化为**两层**:

- **T1 (Mdtt/Model.lean + Rules/Pipeline/CanadianCross/Futamura/Bootstrapping)**:
  规范 §4/§5 的签名级形式化. `Model` 记录打包一个"多阶段世界"的全部签名与语义锚点;
  §6 七条定型规则与 §7 四个架构案例全部转录为**对任意 Model 成立**的定义与定理 ——
  若规范内部不一致, 这里无法通过编译 (它已经抓到并推动修正了 v0.7 的 5 处问题).
- **T2 (Mdtt/Stlc/*)**: 构造 `stlcModel : Model` 的具体实例 (STLC + 反射构造子),
  parse/elaborate/eval(NbE)/emit/lift/mix 均为真实实现, 语义锚点以 `rfl` 兑现,
  证明 T1 的全部签名可被真实满足.

## 快速上手

```sh
just check        # lake build: 类型检查全部形式化 + 跑全部测试 (CI 即此命令)
nix develop       # 开发 shell (elan + just; Lean 版本由 lean-toolchain 固定)
```

体验 MDTT 管线 (在 Lean 文件 / REPL 中):

```lean
import Mdtt
open Mdtt Mdtt.Stlc

-- 完整解释器管线 (§7.1) 的类型: 𝒮^S → ℰ⟨Στ. τ^M⟩ (应用后)
#check (fullInterpreter stlcModel .stlc "((lambda (x : Nat) (+ x 1)) 41)")
  -- ℰ (Σ τ : Ty, stlcModel.sem stlcModel.host τ)

-- 值级求值: 借助 Tests.lean 的 Nat 投影辅助 (结果 42)
example : interpNat "((lambda (x : Nat) (+ x 1)) 41)" = "42" := by native_decide

-- 类型保持编译器别名 (§7.1): 其定义展开即 ∀τ. 𝒜^S⟨τ⟩ → 𝒞^T⟨τ⟩
#check (Compiler stlcModel .stlc .stlc)
  -- Compiler stlcModel MLang.stlc MLang.stlc : Type  (定义见 Pipeline.lean)
```

(注: `Σ` 依赖对无 `Repr` 实例, 全管线 `#eval` 需如上投影辅助; 内核级与
编译期执行两级测试策略见下文"测试策略"。)

## 符号映射表 (规范 → Lean)

| 规范 (v0.8) | Lean (Model 字段/定义) | 章节 |
| :--- | :--- | :--- |
| $𝒮^L$ (Source Text) | `m.src L` | §4.1 |
| $𝒜^L$ (Raw AST) | `m.raw L` | §4.2 |
| $𝒜^L⟨τ⟩$ (Typed AST) | `m.tast L τ` | §4.3 |
| $𝒞^L⟨τ⟩$ (Code) | `m.code L τ` | §4.4 |
| $ℰ⟨τ⟩$ (Error Context) | `ℰ τ` (`Except String`) | §4.5 |
| 共享类型宇宙 τ | `Ty` | §4.6 |
| $⟦τ⟧^L$ / $τ^M$ (解释函数) | `m.sem L τ` / `m.sem m.host τ` | §4.6 |
| $\text{Liftable}(\tau)$ | `m.liftable τ` | §2 |
| $\mathrm{parse}^L$ | `m.parse L` | §5.1 |
| $\mathrm{elaborate}^L$ | `m.elaborate L` | §5.2 |
| $\mathrm{emit}_S^T$ | `m.emit S T` | §5.3 |
| $\uparrow_M^L$ (lift) | `m.lift L` | §5.4 |
| $𝔐_M^L$ (mix) | `m.mix L` | §5.5 |
| $\mathrm{run}_M$ | `m.run` | §5.6 |
| $\mathrm{eval}_M^L$ | `m.eval L` | §5.7 |
| $\ggg$ (Kleisli) | `≫` (`Mdtt.kleisli`) | §7.1 |
| $\text{Compiler}⟨S,T⟩$ / $\text{Interpreter}⟨S⟩$ | `Compiler m S T` / `Interpreter m S` | §7.1 |
| $\text{goal}: 𝒞^H⟨\text{Compiler}⟨S,T⟩⟩$ (加拿大交叉) | `Goal m S H T` / `buildArtifact` | §7.2 |
| quote (反射原语) | `m.quote L` | §7.3 |
| 反射假设 (Raw AST 嵌入) | `m.embed_raw L` | §7.3 |
| 自举不动点 | `boot_fixpoint` | §7.4 |

## 测试策略

- **内核级** (`rfl`): 定型规则、emit 往返、eval 全定义性、mix/quote/embed_raw/二村映射
  —— 类型检查通过即等于内核验证的证明;
- **编译期执行** (`native_decide`): 全管线 (tokenize→parse→elaborate→NbE)
  —— 因内核对 String 操作归约代价过高, 走编译器执行, 断言仍纳入 `just check` 门禁。

实现细节、逻辑契约与已知简化见 [AGENTS.md](AGENTS.md)。
