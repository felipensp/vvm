module vm

import ir

// jmpz implements jump if zero
@[inline]
fn (mut v VVM) jmpz(mut i ir.IR) {
	res := v.get_value(i.op1)
	match res {
		bool {
			if !res {
				v.pc = i.res.value as i64
				return
			}
		}
		else {}
	}
	v.pc += 1
}
