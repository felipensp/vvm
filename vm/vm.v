module vm

import ir

@[heap]
pub struct VVM {
	vir &ir.VVMIR
mut:
	pc          i64 // program counter
	ret_addr    i64 // return address
	tmp_storage []ir.Operand // storage for temporary values like binary operation, returns, etc
}

// get_value retrieves the pointer to operand value
@[inline]
fn (mut v VVM) get_value(op &ir.Operand) &ir.OpValue {
	match op.typ {
		.tmp {
			return &v.tmp_storage[op.value as i64].value
		}
		else {
			return &op.value
		}
	}
}

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
					else {
						v.error('${@FN} - not implemented - op: ${op1_val}')
					}
				}
			}
		}
		.ne_ {
			unsafe {
				*res = ir.OpValue(op1_val != op2_val)
			}
		}
		else {}
	}
}

fn (mut v VVM) error(msg string) {
	eprintln('vm error: ${msg}')
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

// call implements function calling
@[inline]
fn (mut v VVM) call(mut i ir.IR) {
	fn_name := i.op1.value as string
	match fn_name {
		'main.print' {
			val := v.get_value(i.op2)
			if val is []ir.Operand {
				print(*v.get_value(val[0]))
			}
		}
		'main.println' {
			val := v.get_value(i.op2)
			if val is []ir.Operand {
				println(*v.get_value(val[0]))
			}
		}
		else {
			if fn_addr := v.vir.fn_map[fn_name] {
				v.ret_addr = v.pc
				v.pc = fn_addr - 1
			}
		}
	}
}

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

@[inline]
fn (mut v VVM) ret(mut i ir.IR) {
	v.pc = v.ret_addr
}

// run executes the intermediate representation
pub fn (mut v VVM) run(mut ir_ ir.VVMIR) {
	v.tmp_storage = []ir.Operand{len: int(ir_.tmp_size)}

	eprintln('Running (entry point=${ir_.entry_point.hex()}):')
	v.pc = ir_.entry_point
	last_pc := ir_.ir_list.len - 1
	for {
		mut i := ir_.ir_list[v.pc]
		match i.ins {
			// fn call operation
			.call_ {
				v.call(mut i)
			}
			// math operations
			.add_, .sub_, .mul_, .div_ {
				v.math_op(mut i)
			}
			// logic operations
			.le_, .lt_, .ge_, .gt_, .ne_, .eq_ {
				v.logic_op(mut i)
			}
			// jmp operations
			.jmpz_ {
				v.jmpz(mut i)
				if v.pc > last_pc {
					break
				}
				continue
			}
			.ret_ {
				v.ret(mut i)
			}
			else {}
		}
		if v.pc == last_pc {
			break
		}
		v.pc += 1
	}
}
