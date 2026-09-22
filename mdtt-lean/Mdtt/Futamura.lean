import Mdtt.Model
/-!
# Mdtt.Futamura — 二村映射 (规范 §7.3)

职责边界: 形式化 §7.3 的三个二村映射, 静态值以引式 (quoted) 表示进入特化.

T1 形式化的两个发现 (已反馈到规范 v0.8):
1. 第一映射的静态参数需要 `quote` 原语: 被烧录的源程序必须以 `𝒜^L⟨ast L τ⟩`
   (即"计算一个 AST 的程序") 的身份进入 mix 的静态槽位;
2. 第三映射 (cogen) 在签名层面与第二映射同形 —— 完整类型的 cogen
   (interpreterSrc → Compiler) 需要更精细的依赖签名, 属未来工作.

-/

namespace Mdtt



variable {m : Model}

/-- 第一映射 (生成目标代码): code = 𝔐(interpreter, quote(source)).

interpreter : 𝒞^L⟨𝒜^L⟨τ⟩ → τ⟩ (把"程序作为数据"解释为其值);
烧录 quote(source) 后的残差 : 𝒞^L⟨τ⟩ —— 固定了源码的解释器 ≡ 目标代码.
-/
def futamura1 (L : m.lang) {τ : Ty}
    (interpreter : m.code L (.arr (Ty.ast (m.lang_id L) τ) τ))
    (source : m.tast L τ) : m.code L τ :=
  m.mix L interpreter (m.quote L source)

/-- 第二映射 (生成编译器): compiler = 𝔐(mixPgm, interpreterSrc).

mixPgm : 𝒞^L⟨𝒜^L → Static → 𝒜^L⟩ (部分求值器自身作为 L-代码, 反射假设 §7.3);
interpreterSrc 以 Raw AST 字面量嵌入 (embed_raw) 进入静态槽位;
残差 : 𝒞^L⟨Static → 𝒜^L⟩ —— 接受静态输入 (用户源码), 产出残差程序 AST, 即编译器.
-/
def futamura2 (L : m.lang)
    (mixPgm : m.code L (.arr (Ty.raw (m.lang_id L)) (.arr Ty.static (Ty.raw (m.lang_id L)))))
    (interpreterSrc : m.raw L) : m.code L (.arr Ty.static (Ty.raw (m.lang_id L))) :=
  m.mix L mixPgm (m.embed_raw L interpreterSrc)

/-- 第三映射 (生成编译器生成器 / cogen): cogen = 𝔐(mixPgm, mixSrc).

被烧录的换成了 mix 自身的源码 (自反特化). 注意: 其签名层面的残差类型与第二映射相同
(𝒞^L⟨Static → 𝒜^L⟩), 语义区别在于被特化的对象. 规范中"cogen : interpreterSrc → compiler"
的完整类型需要更精细的依赖签名, 在 T1 层不展开 (见文件头说明).
-/
def futamura3 (L : m.lang)
    (mixPgm : m.code L (.arr (Ty.raw (m.lang_id L)) (.arr Ty.static (Ty.raw (m.lang_id L)))))
    (mixSrc : m.raw L) : m.code L (.arr Ty.static (Ty.raw (m.lang_id L))) :=
  m.mix L mixPgm (m.embed_raw L mixSrc)

end Mdtt