fn foo() {
	println('cool')
}

fn baz(arg int) {
	print('baz>>')
	println(arg)
}

fn bar(arg int) {
	print('bar>>')
	println(arg)
	baz(arg)
}

fn main() {
	foo()
	bar(123)
	println('here')
}
