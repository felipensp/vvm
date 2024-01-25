# VVM

Experimental Register-based Virtual Machine for V Programming Language


### Usage

```
$ cat samples/print.v 
fn main() {
        println('foobar')
        println(1 + 1)
        println(2 - 3)
}

$ vvm -f samples/print.v
Collected IR:
     call_ |     lit$println |      lit$foobar |      unu.0
      add_ |           lit.1 |           lit.1 |      fet.0
     call_ |     lit$println |           fet.0 |      unu.0
      sub_ |           lit.2 |           lit.3 |      fet.1
     call_ |     lit$println |           fet.1 |      unu.0

Running:
foobar
2
-1
```