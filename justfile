default := "check"

# 一键验证: 类型检查全部 Lean 形式化 (规范 §5-§7 的签名级核对)
check:
	@cd mdtt-lean && lake build

test: check

clean:
	@cd mdtt-lean && lake clean

# 进入开发环境
shell:
	@nix develop
