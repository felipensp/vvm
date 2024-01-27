module ir

import v.ast

// gen_call emits IR for fn calling
fn (mut i VVMIR) gen_call(call &ast.CallExpr) Operand {
	res := i.new_tmp()
	i.emit(IR{
		ins: .call_
		op1: i.new_str('${call.mod}.${call.name}')
		op2: i.new_arr(call.args.map(i.get_op(it.expr)))
		res: res
	})
	return res
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
		ast.CallExpr {
			return i.gen_call(&expr)
		}
		else {
			return Operand{
				typ: .unused
			}
		}
	}
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
