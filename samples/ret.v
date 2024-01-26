fn test() {
	println(1)
	return
}

fn main() {
	if true {
		test()
		return
	}
	println(2)
}
