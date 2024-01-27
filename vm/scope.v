module vm

import ir

@[inline]
fn (mut v VVM) open_scope(mut i ir.IR) {
	// set new scope
	v.scope_stack << map[string]ir.OpValue{}
	v.scope = &v.scope_stack[v.scope_stack.len - 1]

	// set new temporary storage
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
