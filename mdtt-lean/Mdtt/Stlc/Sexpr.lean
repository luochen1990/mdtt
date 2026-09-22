import Mdtt.Model
/-!
# Mdtt.Stlc.Sexpr — S-表达式与解析器 (T2: STLC 的 Raw 层)

职责边界: 定义 `SExpr` (规范 𝒜^stlc 的载体) 与从源文本 (𝒮^stlc = String) 的解析器.
解析只做**结构性**转换 (文本 → 树), 不做任何作用域/类型检查 —— 那是 Elab 的职责.

解析器为**燃料驱动** (而非 partial): 括号递归下降消耗的 token 流来自递归调用的
返回值, 非结构递归不可证; 燃料化保证定义 kernel-可归约 —— 测试用 `rfl` 即可获得
内核级验证, 而非仅编译器级.
-/

namespace Mdtt.Stlc

/-- S-表达式: Raw AST (规范 §4.2) 的载体. -/
inductive SExpr where
  | atom : String → SExpr
  | list : List SExpr → SExpr
  deriving Repr

/-- 词法分析: 按空白/括号切分, `:` 单独成词 (服务于 `(x : Nat)` 注解语法). -/
def tokenize (s : String) : List String :=
  let push (cur : String) (acc : List String) : List String :=
    if cur.isEmpty then acc else cur :: acc
  let step (acc : List String) (cur : String) (c : Char) : List String × String :=
    if c.isWhitespace then (push cur acc, "")
    else if c = '(' || c = ')' then (toString c :: push cur acc, "")
    else if c = ':' then (":" :: push cur acc, "")
    else (acc, cur.push c)
  let (acc, cur) := s.toList.foldl (fun (acc, cur) c => step acc cur c) ([], "")
  (push cur acc).reverse

mutual

/-- 解析一个表达式 (燃料驱动). -/
def parseExpr : Nat → List String → ℰ (SExpr × List String)
  | 0, _ => .error "parse: out of fuel"
  | _ + 1, [] => .error "parse: unexpected end of input"
  | _ + 1, ")" :: _ => .error "parse: unexpected ')'"
  | fuel + 1, "(" :: rest =>
    match parseList fuel rest with
    | .error e => .error e
    | .ok (es, rest') => .ok (.list es, rest')
  | _ + 1, a :: rest => .ok (.atom a, rest)

/-- 解析至闭括号 `)` 为止的表达式序列. -/
def parseList : Nat → List String → ℰ (List SExpr × List String)
  | 0, _ => .error "parse: out of fuel"
  | _ + 1, [] => .error "parse: unclosed '('"
  | _ + 1, ")" :: rest => .ok ([], rest)
  | fuel + 1, rest =>
    match parseExpr fuel rest with
    | .error e => .error e
    | .ok (e, rest') =>
      match parseList fuel rest' with
      | .error er => .error er
      | .ok (es, rest'') => .ok (e :: es, rest'')

end

/-- parse^stlc : String → ℰ SExpr (模型 parse 字段的 stlc 分支).
燃料取 token 数的线性上界 (每个 token 至多消耗一级). -/
def parse (s : String) : ℰ SExpr :=
  let ts := tokenize s
  match parseExpr (ts.length + 1) ts with
  | .ok (e, []) => .ok e
  | .ok (_, r) => .error s!"parse: trailing input '{repr r.head?}'"
  | .error e => .error e

end Mdtt.Stlc
