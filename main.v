module main

import vm
import ir
import os
import flag

struct VVMOptions {
	file   string
	help   bool
	debug  bool
	dumpir bool
	args   []string
}

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	fp.application('vvm')
	fp.version('0.0.1a')
	fp.description('This tool converts the V AST to an IR and executes on its own virtual machine')
	fp.skip_executable()

	mut opts := &VVMOptions{
		debug: fp.bool('debug', `d`, false, 'show debug information')
		dumpir: fp.bool('dumpir', `D`, false, 'dump IR')
		file: fp.string('file', `f`, '', 'Input file')
		help: fp.bool('help', `h`, false, 'show this help message')
	}

	if opts.help {
		eprintln(fp.usage())
	} else if opts.file != '' {
		mut vvm_ir := ir.VVMIR{}
		vvm_ir.parse_file(opts.file)
		mut vvm_vm := vm.VVM{
			vir: &vvm_ir
			debug: opts.debug
		}
		if opts.dumpir || opts.debug {
			eprintln(vvm_ir)
		}
		vvm_vm.run(mut vvm_ir)
	} else {
		eprintln(fp.usage())
	}
}
