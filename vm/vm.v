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

fn (mut v VVM) error(msg string) {
	eprintln('vm error: ${msg} [pc=${v.pc:04d}]')
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
