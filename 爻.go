package 盘古

// 爻，天地之间最小的信息单位。一爻或阴或阳，别无他态。
//
// 阳 ⚊ 应乎一，阴 ⚋ 应乎零。八进制并非对二进制的模拟，
// 而是每三爻一组的记法：八卦即三位，六十四卦即六位，本自同源。
type 爻 bool

// 阴与阳，两仪。
const (
	阴 爻 = false
	阳 爻 = true
)

// 作爻 依真伪造爻：真者为阳，伪者为阴。
func 作爻(v bool) 爻 { return 爻(v) }

// 由数 依数造爻：零为阴，非零为阳。
func 由数(v int) 爻 { return 爻(v != 0) }

// 反 阳者化阴，阴者化阳。
func (y 爻) 反() 爻 { return 爻(!bool(y)) }

// 与 二者皆阳方为阳。
func (y 爻) 与(彼 爻) 爻 { return 爻(bool(y) && bool(彼)) }

// 或 有一为阳即为阳。
func (y 爻) 或(彼 爻) 爻 { return 爻(bool(y) || bool(彼)) }

// 异或 二者不同则为阳，相同则为阴。
func (y 爻) 异或(彼 爻) 爻 { return 爻(bool(y) != bool(彼)) }

// 与非 与门之后取反。此乃万能之门，一切门皆可仅由它派生。
func (y 爻) 与非(彼 爻) 爻 { return 爻(!(bool(y) && bool(彼))) }

// 或非 或门之后取反。
func (y 爻) 或非(彼 爻) 爻 { return 爻(!(bool(y) || bool(彼))) }

// 同或 异或之后取反，二者相同则为阳。
func (y 爻) 同或(彼 爻) 爻 { return 爻(bool(y) == bool(彼)) }

// 数 爻之数值：阳为一，阴为零。
func (y 爻) 数() int {
	if bool(y) {
		return 1
	}
	return 0
}

// 符 爻之象：阳作 ⚊（U+268A），阴作 ⚋（U+268B）。
func (y 爻) 符() string {
	if bool(y) {
		return "⚊"
	}
	return "⚋"
}

// String 使爻可直接印出。
func (y 爻) String() string { return y.符() }
