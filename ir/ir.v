module ir

import v.token

// VM instructions
pub enum Ins {
	import_ // import handling
	oscope_ // begin scope
	escope_ // end scope
	decl_ // var declaration
	pass_ // pass args
	call_ // function call
	add_ // math: + operation
	sub_ // math: - operation
	div_ // math: / operation
	mul_ // math: * operation
	mod_ // math: % operation
	eq_ // logic: = operation
	ne_ // logic: != operation
	gt_ // logic: > operation
	ge_ // logic: >= operation
	le_ // logic: < operation
	lt_ // logic: <= operation
	jmpz_ // jmp if zero
	ret_ // return
	unknown_
}

// VM Operand value type
pub type OpValue = []Operand | bool | i64 | int | string

// VM Operand type
pub enum OpType {
	unused // operand is unused
	literal // operand is literal value
	var // operand is a var
	tmp // operand is a temporary storage
	jmp // operand is a jmp address
	arr // operand is array of operands
}

// VM Operand
pub struct Operand {
pub:
	typ OpType
pub mut:
	value OpValue // temporary are mutables
}

// Intermediate representation
@[minify]
pub struct IR {
pub:
	ins Ins // VM instruction
pub mut:
	op1 Operand = Operand{ // first operand
		typ: .unused
		value: OpValue(i64(0))
	}
	op2 Operand = Operand{ // second operand
		typ: .unused
		value: OpValue(i64(0))
	}
	res Operand = Operand{ // result operand
		typ: .unused
		value: OpValue(i64(0))
	}
}

// IR container
@[heap]
pub struct VVMIR {
pub mut:
	ir_list     []IR = []IR{cap: 50} // IR list
	entry_point i64  // offset to start
	tmp_size    i64  // temporary counter
	fn_map      map[string]i64 // fn map / name => offset
}

// get_ins decodes AST token to IR instruction
@[inline]
fn (mut i VVMIR) get_ins(op token.Kind) Ins {
	return match op {
		.plus { .add_ } // +
		.minus { .sub_ } // -
		.mul { .mul_ } // *
		.div { .div_ } // /
		.mod { .mod_ } // %
		.gt { .gt_ } // >
		.ge { .ge_ } // >=
		.lt { .lt_ } // <
		.le { .le_ } // <=		
		.ne { .ne_ } // !=
		.eq { .eq_ } // ==
		else { .unknown_ }
	}
}

// new_str creates a literal str operand
@[inline]
fn (mut i VVMIR) new_str(val string) Operand {
	return Operand{
		typ: .literal
		value: val
	}
}

// new_lit creates a literal operand
@[inline]
fn (mut i VVMIR) new_lit(val OpValue) Operand {
	return Operand{
		typ: .literal
		value: val
	}
}

// new_var creates a var operand
@[inline]
fn (mut i VVMIR) new_var(val OpValue) Operand {
	return Operand{
		typ: .var
		value: val
	}
}

// new_arr creates a arr of operand as operand
@[inline]
fn (mut i VVMIR) new_arr(val []Operand) Operand {
	return Operand{
		typ: .arr
		value: val
	}
}

// get_jmp creates a jmp addr operand
@[inline]
fn (mut i VVMIR) get_jmp() Operand {
	res := Operand{
		typ: .jmp
		value: i64(i.ir_list.len)
	}
	return res
}

// new_tmp creates a temporary storage operand
@[inline]
fn (mut i VVMIR) new_tmp() Operand {
	res := Operand{
		typ: .tmp
		value: i.tmp_size
	}
	i.tmp_size++
	return res
}

// emit adds a new item to IR list
@[inline]
fn (mut i VVMIR) emit(ir_ IR) &IR {
	i.ir_list << ir_
	return &i.ir_list[i.ir_list.len - 1]
}
