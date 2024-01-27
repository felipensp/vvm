module ir

import strings

pub fn (op Operand) str() string {
	if op.typ == .unused {
		return op.typ.str()
	}

	mut s := ''
	if op.typ != .arr {
		s += op.typ.str()[0..3]
	}
	match op.value {
		string {
			s += '$'
			s += op.value
		}
		int, i64, bool {
			s += '.'
			s += op.value.str()
		}
		[]Operand {
			s += '['
			for item in op.value {
				s += item.str()[0..3]
				s += ','
			}
			s = s.trim_right(',')
			s += ']#${op.value.len}'
		}
	}
	return s
}

@[inline]
pub fn (o &OpValue) str() string {
	match o {
		string {
			return o as string
		}
		int, i64 {
			return o.str()
		}
		bool {
			return o.str()
		}
		[]Operand {
			return '[..]'
		}
	}
}

@[inline]
fn (i IR) str() string {
	return '${i.ins:10s} | ${i.op1:20s} | ${i.op2:20s} | ${i.res:10s}'
}

pub fn (i VVMIR) str() string {
	eprintln('Collected IR:')
	mut s := strings.new_builder(100)
	for k, item in i.ir_list {
		s.write_string('[${k:04d}] ')
		s.write_string(item.str())
		s.write_string('\n')
	}
	return s.str()
}
