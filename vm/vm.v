module vm

import ir

@[heap]
pub struct VVM {
mut:
	tmp_storage []ir.Operand // storage for temporary values like binary operation, returns, etc
}

// get_value retrieves the pointer to operand value
@[inline]
pub fn (mut v VVM) get_value(op &ir.Operand) &ir.OpValue {
	match op.typ {
		.tmp {
			return &v.tmp_storage[op.value as i64].value
		}
		else {
			return &op.value
		}
	}
}

// math_op implements basic math operation
@[inline]
pub fn (mut v VVM) math_op(mut i ir.IR) {
	op1_val := v.get_value(i.op1)
	op2_val := v.get_value(i.op2)

	op1_ival := if op1_val is int { op1_val } else { int(op1_val) }
	op2_ival := if op2_val is int { op2_val } else { int(op2_val) }

	res := v.get_value(i.res)
	match i.ins {
		.add_ {
			unsafe {
				*res = ir.OpValue(op1_ival + op2_ival)
			}
		}
		.sub_ {
			unsafe {
				*res = ir.OpValue(op1_ival - op2_ival)
			}
		}
		.div_ {
			unsafe {
				*res = ir.OpValue(op1_ival / op2_ival)
			}
		}
		.mul_ {
			unsafe {
				*res = ir.OpValue(op1_ival * op2_ival)
			}
		}
		else {}
	}
}

// call implements function calling
@[inline]
pub fn (mut v VVM) call(mut i ir.IR) {
	fnc := i.op1.value as string
	match fnc {
		'println' {
			val := v.get_value(i.op2)
			match val {
				string, i64, int, bool {
					println(val)
				}
			}
		}
		else {}
	}
}

// run executes the intermediate representation
pub fn (mut v VVM) run(mut ir_ ir.VVMIR) {
	v.tmp_storage = []ir.Operand{len: int(ir_.tmp_size)}

	eprintln('Running:')
	for mut i in ir_.ir_list {
		match i.ins {
			// fn call operation
			.call_ {
				v.call(mut i)
			}
			// math operations
			.add_, .sub_, .mul_, .div_ {
				v.math_op(mut i)
			}
			else {}
		}
	}
}
