#!/bin/zsh
# 变异测试之具：故意把 译.go 改错，看诸验能否杀之。
# 一变异而诸验皆绿，则说明有处**验不到**——那才是真病。
#
# 用法（在仓库根，或在别处亦可——路是自算的）：
#     zsh 具/变异译.sh
#
# ⚠ 一、须以 zsh 呼之。shebang 只在「直接执行」时生效，交给解释器时它不作数；
#      以 bash 呼之则此具会**静默地谎报「尽杀」**，详见下。
# ⚠ 二、**跑之前先提交**。此具自愈之陷阱已设（EXIT/INT/TERM/HUP/PIPE 皆设），
#      然 git 是最后一道退路（`git checkout -- 译.go`）。
#      无退路而自愈失手，则下一趟以「带变异之版」为原样，诸果皆废。
#
# ─────────────────────────────────────────────────────────────
# 此具自身亦须可信。
#
# 作者尝以 bash 跑此 zsh 之具，而 bash 不纳多字节变量名：
# 果=、何=、由= 皆成「命令未找到」，${由} 又 bad substitution 而中断函数体，
# 致「还原」一行从未执行——诸变异**累积相加**于 译.go 之上，
# 而每一次皆因 果 为空被误报「已杀」。
#
# 一具坏而言「尽杀」，其害甚于无具：它教人信了不该信的。
# 故立三检：
#   一、注入之检：变异前后校验和须变。不变则报「未注入」，
#                 不以「已杀」饰之——未注入之变异本就杀不着。
#   二、还原之检：每试之前先还原，收工之后校校验和，与原样不符则止。
#                 还原置于试**前**而非试后，纵中途断亦不致累积。
#   三、首尾之检：开跑之前、收工之后各跑一遍全验，须皆绿。
#
# 又：变量名一律用 ASCII。非为媚 bash，而是**此具曾因此坏过**。
# ─────────────────────────────────────────────────────────────
set -u

# 路自算：本具在 具/ 之下，仓库根是其上一级。
ROOT=${0:A:h:h}
cd "$ROOT" || exit 1

SRC=译.go
BAK=${TMPDIR:-/tmp}/mut-yi-$$.go
PAT='Test译卦|Test分行|Test译数|Test往返|Test手编|Test伪令|Test糖与正体|Test标签|Test译过|Test反汇'

run() { ./跑.sh test -count=1 -run "$PAT" ./... 2>&1; }
restore() { cp "$BAK" "$SRC"; }
sum() { cksum < "$SRC"; }

# 无论如何都要自愈： EXIT / INT / TERM / HUP / PIPE 皆置一陷阱。
#
# 为何连 PIPE 也要：作者尝以 `zsh 具/变异译.sh | head -8` 观其首数行，
# head 读够即闭其管，脚本遂**死于 SIGPIPE**，死时 译.go 正带着一个变异；
# 而备份早已在下一趟中被覆盖，那趟便以「带变异之版本」为原样，诸果皆废。
#
# 教训两层：一、脚本须能自愈；二、**跑变异之前先提交**——
# 有 git 作底，纵自愈亦失手，还有 `git checkout` 这条退路。
cleanup() {
	if [[ -f "$BAK" ]]; then
		cp "$BAK" "$SRC"
		rm -f "$BAK"
	fi
}
trap cleanup EXIT INT TERM HUP PIPE

cp "$SRC" "$BAK" || exit 1
SUM0=$(sum)

# ---- 〇、起手之检：原样须干净 ----
#
# 此具以「当下之 译.go」为原样。若当下这份**本就是上一次跑坏而未还原的**，
# 则此后诸检皆拿它当尺——首尾之检会绿、还原之检会符，而所量者全是错的。
#
# 此病作者犯过：一次即席之自检，在脚本 `rm` 掉备份**之后**才调 restore，
# 遂把「package 盘古 // 自检」留在了 译.go 里；下一趟开跑，
# 备份的便是这份带污染的原样。故立此检，教此事**看得见**。
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	if ! git diff --quiet -- "$SRC" 2>/dev/null; then
		print -r -- "【起手之检】⚠ $SRC 有未提交之改动，此具将**以它为原样**。"
		print -r -- "            若它是上一趟跑坏而未还原的，则下列诸果皆不可信。"
		git diff --stat -- "$SRC" | sed 's/^/            /'
		print -r -- ""
	fi
fi

# ---- 三、首之检 ----
out=$(run)
if ! print -r -- "$out" | grep -q '^ok'; then
	print -r -- "【首之检】不过：干净之 译.go 竟不绿。止。"
	print -r -- "$out" | grep -E 'FAIL|译_test\.go:[0-9]+' | head -20
	exit 1
fi
print -r -- "【首之检】干净之 译.go 全绿 ✓"
print -r -- ""

# ---- 试一变异 ----
# 用法：try_mut <名> <perl 式> [更多 perl 式…]
try_mut() {
	local name="$1"; shift
	local expr before after out who
	restore                      # 二、还原之检（置前）：起点必干净
	before=$(sum)
	for expr in "$@"; do
		perl -0pi -e "$expr" "$SRC"
	done
	after=$(sum)

	printf '%-32s' "$name"
	if [[ "$before" == "$after" ]]; then
		print -r -- "变异未注入 ✗（式已不合，须改式，勿以「已杀」饰之）"
		return
	fi

	out=$(run)
	if print -r -- "$out" | grep -q '^ok'; then
		print -r -- "存活 ✗（有处验不到，须查明）"
	else
		who=$(print -r -- "$out" | grep -oE -- '--- FAIL: [^ ]+' | head -1 | sed 's/--- FAIL: //')
		if [[ -z "$who" ]]; then
			print -r -- "已杀 ✓  （编译不过或崩，非案杀之，须察）"
		else
			print -r -- "已杀 ✓  ${who}"
		fi
	fi
}

# 一、令之译 甲型之偏不符号扩
try_mut "一：甲型之偏不符号扩" \
	's/符号扩\(取偏\(令\), 偏位\)/取偏(令)/'

# 二、令之译 乙型之数不符号扩
try_mut "二：乙型之数不符号扩" \
	's/\t\t数 = 符号扩\(数, 数位\)\n//'

# 三、令之译 甲型之 rd 与 rs1 互换
try_mut "三：甲型 rd 与 rs1 互换" \
	's/卦名\(取rd\(令\)\), 卦名\(取rs1\(令\)\), 卦名\(取rs2\(令\)\), 符号扩/卦名(取rs1(令)), 卦名(取rd(令)), 卦名(取rs2(令)), 符号扩/'

# 四、注释之符改
try_mut "四：注释符改 #" \
	"s/注之符 = '；'/注之符 = '#'/"

# 五、相对之偏忘加一
try_mut "五：相对之偏忘加一" \
	's/标-\(址\+1\)/标-址/'

# 六、丙型之址不校界
try_mut "六：丙型之址不校界" \
	's/\tv, 众 = 校界\(l, false, 址位, "地址", v, 众\)\n//'

# 七、有符号之界放宽一倍（此变异曾存活，故立 界之缝 诸案）
try_mut "七：有符号之界放宽一倍" \
	's/\t\t低 = -\(1 << uint\(位-1\)\)\n\t\t高 = \(1 << uint\(位-1\)\) - 1/\t\t低 = -(1 << uint(位))\n\t\t高 = (1 << uint(位)) - 1/'

# 八、析括 之基与偏互换
try_mut "八：析括 之基与偏互换" \
	's/\t\treturn 号, v, nil/\t\treturn v, 号, nil/'

# 九、别卦符不归化（径以符之差为先天值）
try_mut "九：别卦符不归化" \
	's/return 文王先天\(int\(r-别卦基\) \+ 1\), true/return int(r - 别卦基), true/'

# 十、载高 省 rs1 之时，rs1 误取 rd
try_mut "十：载高 之 rs1 误取 rd" \
	's/\t\treturn 编乙\(码, rd, 0, 数\), 众/\t\treturn 编乙(码, rd, rd, 数), 众/'

# 十一、反汇 用 令之辞 而非 令之译（此变异曾存活，故立 Test反汇）
try_mut "十一：反汇 误用 令之辞" \
	's/\t\t诸\[i\] = 令之译\(令\)/\t\t诸[i] = 令之辞(令)/'

# 十二、甲型之偏不认标签
try_mut "十二：甲型之偏不认标签" \
	's/\tif 标, 有 := 标签\[文\]; 有 \{\n\t\treturn 校界\(l, true, 偏位, "偏移", 标-\(址\+1\), 众\)\n\t\}\n//'

# 十三、器号表 之序倒
try_mut "十三：器号表 之序倒" \
	's/\t\t表\[卦名\(v\)\] = v/\t\t表[卦名(7-v)] = v/'

# 十四、译数 之标签查在剥号之前（旧病复发）
try_mut "十四：标签查在剥号之前" \
	's/\tif v, 有 := 标签\[s\]; 有 \{\n\t\treturn 号 \* v, nil\n\t\}\n//' \
	's/\tif 文 == "" \{\n\t\treturn 0, fmt\.Errorf\("数之文为空"\)\n\t\}/\tif 文 == "" {\n\t\treturn 0, fmt.Errorf("数之文为空")\n\t}\n\tif v, 有 := 标签[文]; 有 {\n\t\treturn v, nil\n\t}/'

# 十五、反汇之文 自起一循环（不复 反汇）—— 防旧病复发
try_mut "十五：反汇之文 另起炉灶" \
	's/\t诸 := 反汇\(诸令\)\n\tif len\(诸\) == 0 \{\n\t\treturn ""\n\t\}\n\treturn strings\.Join\(诸, "\\n"\) \+ "\\n"/\tvar b strings.Builder\n\tfor _, 令 := range 诸令 {\n\t\tb.WriteString(令之辞(令))\n\t\tb.WriteString("\\n")\n\t}\n\treturn b.String()/'

# 十六、丙型之址为零者不书（旧病复发）
#
# 停机 之址无义，书「停机 0」或「停机」，回译皆得同一字——
# 故**往返之验对它瞎**，Test往返穷举 跑七百万字也杀不着它。
# 此变异专为 Test规范式之全 而立：往返验不到的，须另立一验。
try_mut "十六：丙型之址为零者不书" \
	's/\tcase 丙型:\n\t\treturn fmt\.Sprintf\("%s %d", 名, 取址\(令\)\)/\tcase 丙型:\n\t\tif 址 := 取址(令); 址 != 0 || (码 != 停机 && 码 != 叩) {\n\t\t\treturn fmt.Sprintf("%s %d", 名, 址)\n\t\t}\n\t\treturn 名/'

print -r -- ""

# ---- 二、还原之检（收工） ----
restore
SUM1=$(sum)
if [[ "$SUM0" != "$SUM1" ]]; then
	print -r -- "【还原之检】不过：收工之 译.go 与原样不符，止。切勿再信上列诸果。"
	exit 1
fi
print -r -- "【还原之检】译.go 已复原样，校验和相符 ✓"

# ---- 三、尾之检 ----
out=$(run)
if print -r -- "$out" | grep -q '^ok'; then
	print -r -- "【尾之检】还原之后全绿 ✓"
else
	print -r -- "【尾之检】不过：还原之后竟不绿。止。"
	print -r -- "$out" | grep -E 'FAIL|译_test\.go:[0-9]+' | head -20
	restore
	rm -f "$BAK"
	exit 1
fi

# ---- 四、自检：此具**会**报「存活」否？ ----
#
# 上面三检防的是「假绿」（器坏了，却说尽杀）。此检防的是另一种：
# 一个**只会说「已杀」**的器——它的沉默什么也不说明。
# 故末了注入一个无害变异（改一句注释）：诸验当仍全绿，而此具当报「存活」。
# 若它报「已杀」，则说明它压根没在验它以为自己在验的东西。
print -r -- ""
before=$(sum)
perl -0pi -e 's/^package 盘古/package 盘古 \/\/ 自检/' "$SRC"
after=$(sum)
if [[ "$before" == "$after" ]]; then
	print -r -- "【自检】不过：无害变异未注入，式已不合。止。"
	restore
	rm -f "$BAK"
	exit 1
fi
out=$(run)
if print -r -- "$out" | grep -q '^ok'; then
	print -r -- "【自检】无害变异（改一句注释）→ 报「存活」✓"
	print -r -- "        此具分得出不正常——故上列「已杀」诸条，是可信的"
else
	print -r -- "【自检】不过：无害变异竟被杀，此具或验错了对象。止。"
	restore
	rm -f "$BAK"
	exit 1
fi
restore
rm -f "$BAK"
