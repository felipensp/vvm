module ir

import v.ast
import v.pref
import v.parser
import strings

pub enum Ins {
	import_ // import handling
	call_ // function call
	add_ // math: + operation
	sub_ // math: - operation
}

pub type OpValue = i64 | int | string

pub enum OpType {
	unused
	literal
	fetch_var
	fetch_const
	fetch_tmp
	jmp_addr
}

pub struct Operand {
pub:
	typ OpType
pub mut:
	value OpValue
}

@[minify]
pub struct IR {
pub:
	ins Ins
	op1 Operand = Operand{
		typ: .unused
		value: OpValue(i64(0))
	}
	op2 Operand = Operand{
		typ: .unused
		value: OpValue(i64(0))
	}
pub mut:
	res Operand = Operand{
		typ: .unused
		value: OpValue(i64(0))
	}
}

@[heap]
pub struct VVMIR {
pub mut:
	ir_list    []IR
	tmp_size   i64
	const_size i64
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
	i.ir_list << IR{
		ins: .call_
		op1: Operand{
			typ: .literal
			value: call.name
		}
		op2: i.get_op(call.args[0].expr)
	}
}

// get_ops generates the Operand from AST Expr
fn (mut i VVMIR) get_op(expr &ast.Expr) Operand {
	match expr {
		ast.StringLiteral {
			return Operand{
				typ: .literal
				value: expr.val.str()
			}
		}
		ast.IntegerLiteral {
			return Operand{
				typ: .literal
				value: expr.val.int()
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

fn (mut i VVMIR) gen_infixexpr(expr &ast.InfixExpr) Operand {
	match expr.op {
		.plus, .minus {
			i.ir_list << IR{
				ins: if expr.op == .plus { .add_ } else { .sub_ }
				op1: i.get_op(expr.left)
				op2: i.get_op(expr.right)
				res: Operand{
					typ: .fetch_tmp
					value: i.tmp_size
				}
			}
			i.tmp_size++
			return i.ir_list.last().res
		}
		else {
			eprintln('not implemented ${expr.op}')
		}
	}
	return Operand{
		typ: .fetch_tmp
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

fn (mut i VVMIR) gen_stmts(stmts []ast.Stmt) {
	for stmt in stmts {
		i.gen_stmt(&stmt)
	}
}

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
	if op.value is string {
		s += '$'
		s += op.value as string
	} else if op.value is int {
		s += '.'
		s += op.value.str()
	} else if op.value is i64 {
		s += '.'
		s += op.value.str()
	} else {
		s += '.'
		s += op.value.str()
	}
	return s
}

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
