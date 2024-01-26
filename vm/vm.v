module vm

import ir

type VmScope = map[string]ir.OpValue

@[heap]
pub struct VVM {
	vir   &ir.VVMIR
	debug bool
mut:
	pc            i64   // program counter
	ret_stack     []i64 = []i64{} // return address stack
	tmp_storage   [][]ir.Operand = [][]ir.Operand{} // storage for temporary values like binary operation, returns, etc
	scope_stack   []VmScope      = []VmScope{} // scope stack
	scope         &VmScope       = unsafe { nil } // current scope
	fn_args_stack [][]ir.OpValue = [][]ir.OpValue{}
	ret_res_stack []&ir.OpValue
}

// get_value retrieves the pointer to operand value
@[inline]
fn (mut v VVM) get_value(op &ir.Operand) &ir.OpValue {
	match op.typ {
		.tmp {
			return &v.tmp_storage.last()[op.value as i64].value
		}
		.var {
			if v.scope == unsafe { nil } {
				v.error('no scope found')
			}
			if v.scope.len == 0 {
				v.error('scope is empty')
			}
			return unsafe { &v.scope[op.value as string] }
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

fn (mut v VVM) error(msg string) {
	eprintln('vm error: ${msg} [pc=${v.pc:04d}]')
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

@[inline]
fn (mut v VVM) pass(mut i ir.IR) {
	arg_values := i.op1.value as []ir.Operand
	fn_args := v.fn_args_stack.pop()
	for k, arg in arg_values {
		key := arg.value as string
		unsafe {
			v.scope[key] = fn_args[k]
		}
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
				v.ret_stack << v.pc
				v.ret_res_stack << v.get_value(i.res)
				v.pc = fn_addr - 1

				// load args
				args := i.op2.value as []ir.Operand
				mut fn_args := []ir.OpValue{}
				for arg in args {
					fn_args << *v.get_value(arg)
				}
				v.fn_args_stack << fn_args
			}
		}
	}
}

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

// ret implements return statement
@[inline]
fn (mut v VVM) ret(mut i ir.IR) {
	vals := i.op1.value as []ir.Operand
	if vals.len > 0 {
		res := v.ret_res_stack.pop()
		unsafe {
			*res = v.get_value(vals[0])
		}
	}
	v.pc = i.op2.value as i64
}

@[inline]
fn (mut v VVM) open_scope(mut i ir.IR) {
	v.scope_stack << map[string]ir.OpValue{}
	v.scope = &v.scope_stack[v.scope_stack.len - 1]

	v.tmp_storage << []ir.Operand{len: int(i.op1.value as i64)}
}

@[inline]
fn (mut v VVM) end_scope() {
	if v.scope_stack.len == 0 {
		v.error('no scope to pop')
		return
	}
	v.scope_stack.pop()
	v.tmp_storage.pop()
	if v.scope_stack.len != 0 {
		v.scope = &v.scope_stack[v.scope_stack.len - 1]
		if v.ret_stack.len > 0 {
			v.pc = v.ret_stack.pop()
		}
	} else {
		v.scope = unsafe { nil }
	}
}

@[inline]
fn (mut v VVM) decl(mut i ir.IR) {
	var_name := i.op1.value as string
	unsafe {
		v.scope[var_name] = *v.get_value(i.op2)
	}
}

// run executes the intermediate representation
pub fn (mut v VVM) run(mut ir_ ir.VVMIR) {
	if v.debug {
		eprintln('Running (entry point=${ir_.entry_point:04d}):')
	}

	// entry point
	v.pc = ir_.entry_point
	// last instruction
	last_pc := ir_.ir_list.len - 1

	for {
		mut i := ir_.ir_list[v.pc]
		match i.ins {
			.oscope_ { // scope open
				v.open_scope(mut i)
			}
			.escope_ { // scope end
				v.end_scope()
			}
			.pass_ { // pass arg
				v.pass(mut i)
			}
			.call_ { // fn call operation
				v.call(mut i)
			}
			.add_, .sub_, .mul_, .div_ { // math operations
				v.math_op(mut i)
			}
			.le_, .lt_, .ge_, .gt_, .ne_, .eq_ { // logic operations
				v.logic_op(mut i)
			}
			.jmpz_ { // jmp operations
				v.jmpz(mut i)
				if v.pc > last_pc {
					break
				}
				continue
			}
			.ret_ { // return
				v.ret(mut i)
				continue
			}
			.decl_ { // var decl
				v.decl(mut i)
			}
			else {}
		}
		if v.pc == last_pc {
			break
		}
		v.pc += 1
	}
}
