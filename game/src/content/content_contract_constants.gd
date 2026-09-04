class_name ContentContractConstants
extends RefCounted

# 内容合同冻结数值的唯一权威来源（单一事实来源）。
# 主线章节数与各内容域的期望条目数只在本文件定义一次；校验器、注册表与
# 规则层一律通过 preload 常量再导出引用，禁止在本文件之外重复手写这些
# 冻结数值。修改任何数值都等同于变更内容合同本身，必须同步评审内容
# 清单与全部消费方，而不是局部调整。

const MAXIMUM_MAINLINE_CHAPTER: int = 9
const EXPECTED_MAINLINE_PROGRESSION_COUNT: int = 9
const EXPECTED_OPTIONAL_PROGRESSION_COUNT: int = 4
const EXPECTED_PERMANENT_GROWTH_REWARD_COUNT: int = 30
const EXPECTED_REPRESENTATIVE_ROUTE_CONTRACT_COUNT: int = 5
const EXPECTED_ENEMY_FAMILY_COUNT: int = 12
const EXPECTED_ENEMY_PROFILE_COUNT: int = 24
