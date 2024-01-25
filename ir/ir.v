module ir

import v.ast
import v.pref
import v.parser
import strings

pub enum Ins {
	module_
	print_
	call_
}

type Operand = int | string

@[minify]
struct IR {
pub:
	ins Ins
	op1 Operand
	op2 Operand
	res Operand
}

@[heap]
pub struct VVMIR {
pub mut:
	ir_list []IR
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
		op1: call.name
		op2: (call.args[0].expr as ast.StringLiteral).val
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
	if op is string {
		return 's"${string(op)}"'
	} else {
		return 'unused'
	}
}

fn (ii IR) str() string {
	return '${ii.ins:10s} | ${ii.op1:10s} | ${ii.op2:10s} | ${ii.res:10s}'
}

pub fn (i VVMIR) str() string {
	eprintln('Collected IR:')
	mut s := strings.new_builder(100)
	for item in i.ir_list {
		s.write_string(item.str())
	}
	return s.str()
}
