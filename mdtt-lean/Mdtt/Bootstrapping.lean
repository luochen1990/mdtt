import Mdtt.Model
/-!
# Mdtt.Bootstrapping — 编译器自举 (规范 §7.4)

职责边界: 形式化 §7.4 的自举三阶段链 (以 rustc 为例) 与不动点性质.

T1 形式化的发现: 规范将 rustc₂ ≡ rustc₃ 归因于"确定性编译", 但形式化后可以看到
**确定性 (bootStep 是数学函数) 是自动成立的**; 不动点等式真正需要的是更强的
**自举稳定性假设** —— 用产物重新编译同一源码, 产物不变 (比特级稳定).
该假设在此作为显式前提 `stable` 传入.

-/

namespace Mdtt



variable {m : Model} (L : m.lang)

/-- 一个 "rustc": 运行在宿主上、把 L 编译到宿主的编译器产物.
即 𝒞^M⟨Compiler⟨L,M⟩⟩ (§7.4 Stage 0 的类型). -/
abbrev Rustc : Type := m.code m.host (Ty.compiler (m.lang_id L) (m.lang_id m.host))

/-- 自举源码: 用 L 编写的、已定型为 Compiler⟨L,M⟩ 的编译器源程序.
自举即 S = L 的特例 (规范 §7.4 场景中 L = S = Rust, T = M = 宿主). -/
abbrev RustcSrc : Type := m.tast L (Ty.compiler (m.lang_id L) (m.lang_id m.host))

/-- 自举单步: rustc_{n+1} = run(rustc_n, rustc_src) (§7.4). -/
def bootStep (c : Rustc L) (src : RustcSrc L) : ℰ (Rustc L) := do
  let f ← m.run c
  pure (m.unroll_compiler L m.host f (Ty.compiler (m.lang_id L) (m.lang_id m.host)) src)

/-- Stage 1 → Stage 2: 用旧编译器产物再编译一次. -/
def boot2 (c0 : Rustc L) (src : RustcSrc L) : ℰ (Rustc L) :=
  bootStep L c0 src >>= fun r1 => bootStep L r1 src

/-- Stage 2 → Stage 3: 用新编译器产物再编译一次. -/
def boot3 (c0 : Rustc L) (src : RustcSrc L) : ℰ (Rustc L) :=
  boot2 L c0 src >>= fun r2 => bootStep L r2 src

/-- §7.4 不动点: rustc₂ ≡ rustc₃ (比特等价), 前提是自举稳定性 (见文件头). -/
theorem boot_fixpoint (c0 r1 r2 : Rustc L) (src : RustcSrc L)
    (h1 : bootStep L c0 src = .ok r1)
    (h2 : bootStep L r1 src = .ok r2)
    (stable : bootStep L r2 src = .ok r2) :
    boot3 L c0 src = boot2 L c0 src := by
  have e2 : boot2 L c0 src = .ok r2 := by
    unfold boot2; rw [h1]; exact h2
  have e3 : boot3 L c0 src = .ok r2 := by
    unfold boot3; rw [e2]; exact stable
  rw [e3, e2]

end Mdtt