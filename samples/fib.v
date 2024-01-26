fn fib(num int) int {
	if num < 2 {
		return num
	} else {
		return fib(num - 1) + fib(num - 2)
	}
}

fn main() {
	println(fib(26))
}
