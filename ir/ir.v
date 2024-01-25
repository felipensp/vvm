module ir

import v.token
import v.ast
import v.pref
import v.parser
import strings

// VM instructions
pub enum Ins {
	import_ // import handling
	call_ // function call
	add_ // math: + operation
	sub_ // math: - operation
	div_ // math: / operation
	mul_ // math: * operation
	unknown_
}

// VM Operand value type
pub type OpValue = bool | i64 | int | string

// VM Operand type
pub enum OpType {
	unused
	literal
	var
	tmp
	jmp
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
	ir_list  []IR
	tmp_size i64 // temporary counter
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

fn (mut i VVMIR) gen_fn_decl(func &ast.FnDecl) {
	i.gen_stmts(func.stmts)
}

fn (mut i VVMIR) gen_call(call &ast.CallExpr) {
	i.emit(IR{
		ins: .call_
		op1: i.new_str(call.name)
		op2: i.get_op(call.args[0].expr)
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
			{
				return i.new_lit(expr.val)
			}
		}
		ast.InfixExpr {
			return i.gen_infixexpr(&expr)
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
		.plus { .add_ }
		.minus { .sub_ }
		.mul { .mul_ }
		.div { .div_ }
		else { .unknown_ }
	}
}

@[inline]
fn (mut i VVMIR) new_str(val string) Operand {
	return Operand{
		typ: .literal
		value: val
	}
}

@[inline]
fn (mut i VVMIR) new_lit(val OpValue) Operand {
	return Operand{
		typ: .literal
		value: val
	}
}

@[inline]
fn (mut i VVMIR) new_tmp() Operand {
	res := Operand{
		typ: .tmp
		value: i.tmp_size
	}
	i.tmp_size++
	return res
}

@[inline]
fn (mut i VVMIR) emit(ir_ IR) {
	i.ir_list << ir_
}

fn (mut i VVMIR) gen_infixexpr(expr &ast.InfixExpr) Operand {
	match expr.op {
		.plus, .minus, .mul, .div {
			tmp := i.new_tmp()
			i.emit(IR{
				ins: i.get_ins(expr.op)
				op1: i.get_op(expr.left)
				op2: i.get_op(expr.right)
				res: tmp
			})
			return tmp
		}
		else {
			eprintln('not implemented ${expr.op}')
		}
	}
	return Operand{
		typ: .tmp
	}
}

fn (mut i VVMIR) gen_expr(expr &ast.Expr) {
	match expr {
		ast.CallExpr { i.gen_call(&expr) }
		else { dump(expr) }
	}
}

fn (mut i VVMIR) gen_return(stmt &ast.Return) {
	for expr in stmt.exprs {
		i.gen_expr(&expr)
	}
}

fn (mut i VVMIR) gen_stmt(stmt &ast.Stmt) {
	match stmt {
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
			dump(stmt)
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

fn (op Operand) str() string {
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
	}
	return s
}

@[inline]
fn (ii IR) str() string {
	return '${ii.ins:10s} | ${ii.op1:15s} | ${ii.op2:15s} | ${ii.res:10s}'
}

pub fn (i VVMIR) str() string {
	eprintln('Collected IR:')
	mut s := strings.new_builder(100)
	for item in i.ir_list {
		s.write_string(item.str())
		s.write_string('\n')
	}
	return s.str()
}
