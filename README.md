# VVM

Experimental Register-based Virtual Machine for V Programming Language


### Usage

```
$ cat samples/fib.v 
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

$ vvm -d -f samples/fib.v 
Collected IR:
[0000]    oscope_ |                lit.8 |               unused |     unused
[0001]      pass_ |              [lit]#1 |               unused |     unused
[0002]        lt_ |              var$num |                lit.2 |      tmp.0
[0003]      jmpz_ |                tmp.0 |               unused |      jmp.5
[0004]       ret_ |              [var]#1 |               jmp.12 |      tmp.1
[0005]      jmpz_ |               unused |               unused |     jmp.12
[0006]       sub_ |              var$num |                lit.1 |      tmp.4
[0007]      call_ |         lit$main.fib |              [tmp]#1 |      tmp.3
[0008]       sub_ |              var$num |                lit.2 |      tmp.6
[0009]      call_ |         lit$main.fib |              [tmp]#1 |      tmp.5
[0010]       add_ |                tmp.3 |                tmp.5 |      tmp.2
[0011]       ret_ |              [tmp]#1 |               jmp.12 |      tmp.7
[0012]    escope_ |               unused |               unused |     unused
[0013]    oscope_ |                lit.2 |               unused |     unused
[0014]      call_ |         lit$main.fib |              [lit]#1 |      tmp.1
[0015]      call_ |     lit$main.println |              [tmp]#1 |      tmp.0
[0016]    escope_ |               unused |               unused |     unused

Running (entry point=0013):
121393
```