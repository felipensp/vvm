module vm

import ir

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

// ret implements return statement
@[inline]
fn (mut v VVM) ret(mut i ir.IR) {
	vals := i.op1.value as []ir.Operand
	if vals.len > 0 {
		res := v.ret_res_stack.pop()
		unsafe {
			// sets the fn result value
			*res = v.get_value(vals[0])
		}
	}
	// go to end scope instruction
	v.pc = i.op2.value as i64
}
