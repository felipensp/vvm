module vm

import ir

@[inline]
fn (mut v VVM) logic_op(mut i ir.IR) {
	op1_val := v.get_value(i.op1)
	op2_val := v.get_value(i.op2)
	res := v.get_value(i.res)
	match i.ins {
		.le_ {
			unsafe {
				match op1_val {
					int {
						*res = ir.OpValue(op1_val <= (op2_val as int))
					}
					i64 {
						*res = ir.OpValue(op1_val <= (op2_val as i64))
					}
					else {
						v.error('${@FN} - not implemented - op: ${op1_val}')
					}
				}
			}
		}
		.lt_ {
			unsafe {
				match op1_val {
					int {
						*res = ir.OpValue(op1_val < (op2_val as int))
					}
					i64 {
						*res = ir.OpValue(op1_val < (op2_val as i64))
					}
					else {
						v.error('${@FN} - not implemented - op: ${op1_val}')
					}
				}
			}
		}
		.ge_ {
			unsafe {
				match op1_val {
					int {
						*res = ir.OpValue(op1_val >= (op2_val as int))
					}
					i64 {
						*res = ir.OpValue(op1_val >= (op2_val as i64))
					}
					else {
						v.error('${@FN} - not implemented - op: ${op1_val}')
					}
				}
			}
		}
		.gt_ {
			unsafe {
				match op1_val {
					int {
						*res = ir.OpValue(op1_val > (op2_val as int))
					}
					i64 {
						*res = ir.OpValue(op1_val > (op2_val as i64))
					}
					else {
						v.error('${@FN} - not implemented - op: ${op1_val}')
					}
				}
			}
		}
		.eq_ {
			unsafe {
				match op1_val {
					int {
						*res = ir.OpValue(op1_val == (op2_val as int))
					}
					i64 {
						*res = ir.OpValue(op1_val == (op2_val as i64))
					}
					bool {
						*res = ir.OpValue(op1_val != (op2_val as bool))
					}
					string {
						*res = ir.OpValue(op1_val != (op2_val as string))
					}
					else {
						v.error('${@FN} - not implemented - op: ${op1_val}')
					}
				}
			}
		}
		.ne_ {
			unsafe {
				match op1_val {
					int {
						*res = ir.OpValue(op1_val != (op2_val as int))
					}
					i64 {
						*res = ir.OpValue(op1_val != (op2_val as i64))
					}
					bool {
						*res = ir.OpValue(op1_val != (op2_val as bool))
					}
					string {
						*res = ir.OpValue(op1_val != (op2_val as string))
					}
					else {
						v.error('${@FN} - not implemented - op: ${op1_val}')
					}
				}
			}
		}
		else {}
	}
}

// math_op implements basic math operation
@[inline]
fn (mut v VVM) math_op(mut i ir.IR) {
	op1_val := v.get_value(i.op1)
	op2_val := v.get_value(i.op2)
	res := v.get_value(i.res)
	match i.ins {
		.add_ {
			unsafe {
				match op1_val {
					int {
						*res = ir.OpValue(op1_val + (op2_val as int))
					}
					i64 {
						*res = ir.OpValue(op1_val + (op2_val as i64))
					}
					else {
						v.error('${@FN} - not implemented - op: ${op1_val}')
					}
				}
			}
		}
		.sub_ {
			unsafe {
				match op1_val {
					int {
						*res = ir.OpValue(op1_val - (op2_val as int))
					}
					i64 {
						*res = ir.OpValue(op1_val - (op2_val as i64))
					}
					else {
						v.error('${@FN} - not implemented - op: ${op1_val}')
					}
				}
			}
		}
		.div_ {
			unsafe {
				match op1_val {
					int {
						*res = ir.OpValue(op1_val / (op2_val as int))
					}
					i64 {
						*res = ir.OpValue(op1_val / (op2_val as i64))
					}
					else {
						v.error('${@FN} - not implemented - op: ${op1_val}')
					}
				}
			}
		}
		.mul_ {
			unsafe {
				match op1_val {
					int {
						*res = ir.OpValue(op1_val * (op2_val as int))
					}
					i64 {
						*res = ir.OpValue(op1_val * (op2_val as i64))
					}
					else {
						v.error('${@FN} - not implemented - op: ${op1_val}')
					}
				}
			}
		}
		.mod_ {
			unsafe {
				match op1_val {
					int {
						*res = ir.OpValue(op1_val % (op2_val as int))
					}
					i64 {
						*res = ir.OpValue(op1_val % (op2_val as i64))
					}
					else {
						v.error('${@FN} - not implemented - op: ${op1_val}')
					}
				}
			}
		}
		else {}
	}
}
