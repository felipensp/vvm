module ir

import v.token
import v.ast
import v.pref
import v.parser
import strings

// VM instructions
pub enum Ins {
	import_ // import handling
	oscope_ // begin scope
	escope_ // end scope
	decl_ // var declaration
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
	op1 Operand = Operand{ // first operand
		typ: .unused
		value: OpValue(i64(0))
	}
	op2 Operand = Operand{ // second operand
		typ: .unused
		value: OpValue(i64(0))
	}
pub mut:
	res Operand = Operand{ // result operand
		typ: .unused
		value: OpValue(i64(0))
	}
}

// IR container
@[heap]
pub struct VVMIR {
pub mut:
	ir_list     []IR = []IR{cap: 30} // IR list
	entry_point i64  // offset to start
	tmp_size    i64  // temporary counter
	fn_map      map[string]i64 // fn map / name => offset
}

struct Tree {
	table &ast.Table        = unsafe { nil }
	pref  &pref.Preferences = unsafe { nil }
mut:
	root Node // the root of tree
}

// tree node
pub type Node = C.cJSON

// create an object node
@[inline]
fn new_object() &Node {
	return C.cJSON_CreateObject()
}

fn (mut i VVMIR) gen_module(mod &ast.Module) {
}

// gen_fn_decl emits IR for fn declaration
fn (mut i VVMIR) gen_fn_decl(func &ast.FnDecl) {
	start_addr := i.get_jmp().value as i64
	i.emit(IR{ ins: .oscope_ })
	if func.is_main {
		i.entry_point = start_addr
		i.gen_stmts(func.stmts)
	} else {
		i.fn_map[func.name] = start_addr
		i.gen_stmts(func.stmts)
		i.emit(IR{ ins: .ret_ })
	}
	i.emit(IR{ ins: .escope_ })
}

// gen_call emits IR for fn calling
fn (mut i VVMIR) gen_call(call &ast.CallExpr) {
	i.emit(IR{
		ins: .call_
		op1: i.new_str('${call.mod}.${call.name}')
		op2: i.new_arr(call.args.map(i.get_op(it.expr)))
		res: i.new_tmp()
	})
}

// get_ops generates the Operand from AST Expr
fn (mut i VVMIR) get_op(expr &ast.Expr) Operand {
	match expr {
		ast.StringLiteral {
			return i.new_lit(expr.val.str())
		}
		ast.IntegerLiteral {
			return i.new_lit(expr.val.int())
		}
		ast.BoolLiteral {
			return i.new_lit(expr.val)
		}
		ast.InfixExpr {
			return i.gen_infixexpr(&expr)
		}
		ast.Ident {
			return i.new_var(expr.name)
		}
		else {
			return Operand{
				typ: .unused
			}
		}
	}
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

fn (mut i VVMIR) gen_infixexpr(expr &ast.InfixExpr) Operand {
	tmp := i.new_tmp()
	i.emit(IR{
		ins: i.get_ins(expr.op)
		op1: i.get_op(expr.left)
		op2: i.get_op(expr.right)
		res: tmp
	})
	return tmp
}

fn (mut i VVMIR) gen_if(expr &ast.IfExpr) {
	for branch in expr.branches {
		mut ir_ := i.emit(IR{
			ins: .jmpz_
			op1: i.get_op(branch.cond)
			res: Operand{
				typ: .jmp
			}
		})
		i.gen_stmts(branch.stmts)
		ir_.res = i.get_jmp()
	}
}

fn (mut i VVMIR) gen_expr(expr &ast.Expr) {
	match expr {
		ast.CallExpr { i.gen_call(&expr) }
		ast.IfExpr { i.gen_if(&expr) }
		else { dump(expr) }
	}
}

fn (mut i VVMIR) gen_return(stmt &ast.Return) {
	for expr in stmt.exprs {
		i.gen_expr(&expr)
	}
}

fn (mut i VVMIR) gen_assign(stmt &ast.AssignStmt) {
	i.emit(IR{ ins: .decl_, op1: i.get_op(&stmt.left[0]), op2: i.get_op(&stmt.right[0]) })
}

fn (mut i VVMIR) gen_stmt(stmt &ast.Stmt) {
	match stmt {
		ast.AssignStmt {
			i.gen_assign(&stmt)
		}
		ast.Module {
			i.gen_module(&stmt)
		}
		ast.FnDecl {
			i.gen_fn_decl(&stmt)
		}
		ast.Block {
			i.gen_stmts(stmt.stmts)
		}
		ast.Return {
			i.gen_return(&stmt)
		}
		ast.ExprStmt {
			i.gen_expr(&stmt.expr)
		}
		else {
			eprintln('unhandled at ${@FN}: ${stmt}')
		}
	}
}

@[inline]
fn (mut i VVMIR) gen_stmts(stmts []ast.Stmt) {
	for stmt in stmts {
		i.gen_stmt(&stmt)
	}
}

@[inline]
fn (mut i VVMIR) gen_file(file &ast.File) {
	i.gen_stmts(file.stmts)
}

pub fn (mut i VVMIR) parse_file(file string) {
	mut pref_ := &pref.Preferences{}
	pref_.fill_with_defaults()
	pref_.enable_globals = true
	//
	mut t := Tree{
		root: new_object()
		table: ast.new_table()
		pref: pref_
	}
	// parse file with comment
	ast_file := parser.parse_file(file, t.table, .parse_comments, t.pref)
	i.gen_file(ast_file)
}

pub fn (op Operand) str() string {
	mut s := ''
	s += op.typ.str()[0..3]
	match op.value {
		string {
			s += '$'
			s += op.value
		}
		int, i64, bool {
			s += '.'
			s += op.value.str()
		}
		[]Operand {
			s += '.[]args'
		}
	}
	return s
}

@[inline]
pub fn (o &OpValue) str() string {
	match o {
		string {
			return o as string
		}
		int, i64 {
			return o.str()
		}
		bool {
			return o.str()
		}
		[]Operand {
			return '[..]'
		}
	}
}

@[inline]
fn (i IR) str() string {
	return '${i.ins:10s} | ${i.op1:20s} | ${i.op2:20s} | ${i.res:10s}'
}

pub fn (i VVMIR) str() string {
	eprintln('Collected IR:')
	mut s := strings.new_builder(100)
	for k, item in i.ir_list {
		s.write_string('[${k:04d}] ')
		s.write_string(item.str())
		s.write_string('\n')
	}
	return s.str()
}
