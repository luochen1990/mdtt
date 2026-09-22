# mdtt-lean — MDTT 的 Lean 4 形式化

> 读者范围 (scope): 想核对 MDTT 规范 (v0.8) 类型签名一致性的读者; 想在 Lean 中以
> "可执行 DSL" 方式使用 MDTT 概念的开发者; T2 实例 (Mdtt/Stlc.*) 的维护者.
> 实现细节与设计决策见本目录 [AGENTS.md](AGENTS.md) (维护者向).

本项目分两层:

- **T1 (Mdtt/Model.lean 等)**: 规范 §4/§5 的签名级形式化. `Model` 记录打包一个
  "多阶段世界" 的全部签名与语义锚点; §6 七条定型规则与 §7 四个架构案例
  (管线 / 加拿大交叉编译 / 二村映射 / 自举) 全部 transcription 为对任意 Model 成立的定义与定理.
- **T2 (Mdtt/Sttc/*.lean)**: 构造 `stlcModel : Model` 的具体实例 (STLC 目标语言,
  真实 parse/elaborate/eval/emit), 证明签名可被真实满足.

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
| $\ggg$ (Kleisli) | `≫` (`Model.kleisli`) | §7.1 |
| $\text{Compiler}⟨S,T⟩$ / $\text{Interpreter}⟨S⟩$ | `Compiler m S T` / `Interpreter m S` | §7.1 |
| quote (反射原语) | `m.quote L` | §7.3 |
| 反射假设 (Raw AST 嵌入) | `m.embed_raw L` | §7.3 |

## 使用

```sh
just check        # lake build, 类型检查全部形式化
nix develop       # 进入开发 shell (elan + just)
```

Toolchain Notes: Lean 版本由 `lean-toolchain` (v4.30.0) 权威固定, 由 elan 解析;
系统无全局默认工具链也不影响 (lake 会按 lean-toolchain 自动拉取).
