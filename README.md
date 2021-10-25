# HEXV6: An extension to the xv6-riscv OS

## Specification 1: Syscall Tracing via `strace`
* `strace` traces the the system calls called by a given command during execution, till exit.
* The system calls to be traced are specified by the argument `mask`.
* Usage of the `strace` is as given below:
    ```
    strace mask command [args]
    ```
* The system call `strace` has been implemented from scratch.
* Changes have been made on the predefined `struct proc` to contain the mask as `int mask`.
* The variable `mask` is later used to identify the system call whenever it is called by the process.
* For implementing this specification, the following files have been modified:
    1. `Makefile`: the system call was added to `UPROGS` list, as `$U/_strace`.
    2. `kernel/proc.h`: the `struct proc` is modified to contain `int mask`.
    3. `kernel/proc.c`: both `allocproc()` and `freeproc()` were modified to set `p->mask=0`, while in `fork()`, the mask of the child process is set to be equal to that of parent.
    4. `kernel/syscall.c`: within the `syscall()` function, logic of the strace is implemented, which requires the list of syscall names defined in `syscall_name` the `sys_strace` added to the list of syscalls. 
