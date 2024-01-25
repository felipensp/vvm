module vm

import ir

@[heap]
pub struct VVM {
}

pub fn (v &VVM) run(ir_ &ir.VVMIR) {
	eprintln('Running:')
	for i in ir_.ir_list {
		match i.ins {
			.call_ {
				fnc := i.op1 as string
				match fnc {
					'println' {
						println(i.op2 as string)
					}
					else {}
				}
			}
			else {}
		}
	}
}
