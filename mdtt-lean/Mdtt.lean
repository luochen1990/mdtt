-- 职责: MDTT Lean 形式化的根模块, 汇集并重导出全部子模块.
-- 对应规范: README.md "MDTT Specification v0.8".
-- T1: Model/Rules/Pipeline/CanadianCross/Futamura/Bootstrapping (签名级, 任意模型)
-- T2: Stlc/* (stlcModel 具体实例: 真实 parse/elaborate/eval/emit + kernel 级测试)
import Mdtt.Model
import Mdtt.Rules
import Mdtt.Pipeline
import Mdtt.CanadianCross
import Mdtt.Futamura
import Mdtt.Bootstrapping
import Mdtt.Stlc.Sexpr
import Mdtt.Stlc.Term
import Mdtt.Stlc.Sem
import Mdtt.Stlc.Elab
import Mdtt.Stlc.Emit
import Mdtt.Stlc.Model
import Mdtt.Stlc.Tests
