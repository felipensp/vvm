module vm

import ir

@[heap]
pub struct VVM {
mut:
	tmp_storage   []ir.Operand
	const_storage []ir.Operand
}

pub fn (mut v VVM) get_value(op &ir.Operand) &ir.OpValue {
	match op.typ {
		.fetch_tmp {
			return &v.tmp_storage[op.value as i64].value
		}
		.fetch_const {
			return &v.const_storage[op.value as i64].value
		}
		else {
			return &op.value
		}
	}
}

pub fn (mut v VVM) run(mut ir_ ir.VVMIR) {
	v.tmp_storage = []ir.Operand{len: int(ir_.tmp_size)}
	v.const_storage = []ir.Operand{len: int(ir_.const_size)}

	eprintln('Running:')
	for mut i in ir_.ir_list {
		match i.ins {
			.call_ {
				fnc := i.op1.value as string
				match fnc {
					'println' {
						val := v.get_value(i.op2)
						match val {
							string, i64, int {
								println(val)
							}
						}
					}
					else {}
				}
			}
			// math operations
			.add_, .sub_ {
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
					else {}
				}
			}
			else {}
		}
	}
}
