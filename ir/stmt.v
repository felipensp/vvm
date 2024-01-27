module ir

import v.ast

fn (mut i VVMIR) gen_module(mod &ast.Module) {
}

// gen_fn_decl emits IR for fn declaration
fn (mut i VVMIR) gen_fn_decl(func &ast.FnDecl) {
	start_addr := i.get_jmp().value as i64

	i.tmp_size = 0
	mut oscope := i.emit(IR{ ins: .oscope_ })
	if func.is_main {
		i.entry_point = start_addr
		i.gen_stmts(func.stmts)
	} else {
		i.fn_map[func.name] = start_addr
		i.emit(IR{ ins: .pass_, op1: i.new_arr(func.params.map(i.new_str(it.name))) })
		i.gen_stmts(func.stmts)
	}
	// points ret stmts to end of fn scope
	end_addr := i.get_jmp().value as i64
	for mut item in i.ir_list[start_addr..end_addr] {
		if item.ins == .ret_ {
			item.op2 = Operand{
				typ: .jmp
				value: end_addr
			}
		}
	}
	oscope.op1 = i.new_lit(i.tmp_size)
	i.emit(IR{ ins: .escope_ })
}

fn (mut i VVMIR) gen_return(stmt &ast.Return) {
	i.emit(IR{ ins: .ret_, op1: i.new_arr(stmt.exprs.map(i.get_op(&it))), res: i.new_tmp() })
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
