# HEXV6: An extension to the xv6-riscv OS

## Introduction
This project is the extension of the xv6-riscv OS, a pedagogical OS designed by the team at MIT.

The extensions to the OS include:
* `strace` system call, which traces system calls during command execution
* `waitx` system call, which is similar to `wait` syscall, but it also gives times spent running and waiting for a child process.
* Implementation of multiple scheduling protocols in addition to the default Round Robin method, including:
    1. First Come First Serve (FCFS)
    2. Priority Based Scheduler (PBS)
    3. Multi-Level Feedback Queues (MLFQ)
* `setpriority` function, which changes the static priority of a given process.
* `schedulertest` command to run predefined tasks to test the scheduling policies. Note that the test needs `waitx` system call.

For instructions running, click [here](#running-the-os).

## Syscall Tracing via `strace`
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
    4. `kernel/syscall.c`: within the `syscall()` function, printing logic of the strace is implemented, which requires the list of syscall names defined in `syscall_name` the `sys_strace` added to the list of syscalls.
    5. `kernel/sysproc.c`: within the `sys_strace()` function, the main logic of strace implemented, wherein the mask is given to current process.
    6. `user/usys.pl`: `"strace"` is added to the entries to make corresponding link.

## Scheduling Policies
* xv6-riscv OS uses Round-Robin scheduling policy as the default scheduling policy. 

* In this version however, there are other scheduling policies that have been implemented. For instructions running these scheduling policies click [here](##Running-the-OS).

* The following files were changed during the implementation of the scheduling policies:
    1. `kernel/proc.c`: 
        - Changes were made to the `scheduler()` function, wherein each specific scheduling policy was implemented.
        - `update_val()` function was impemented to update values pertaining to each process after every clock tick. This function is called from the `clock_intr()` function within the `kernel/trap.c`.
        - Other scheduler specific changes were made throughout the file.
    2. `kernel/trap.c`: 
        - `usertrap()` and `kerneltrap()` functions were modified to prevent pre-emptive timer interupts in FCFS and PBS. 
        - Further, modifications were made to implement interupts specific to MLFQ.

* The details about the individual scheduling mechanisms are as supplied below.

### First Come First Serve (FCFS)
* First Come First Serve scheduling policy implies that the first process (earliest to be created) will be executed first.
* The scheduler iterates over all processes in the processing table and selects the one with the least create time, and runs it.
* The create times of the process are stored within `p->ctime` corresponding to each process.
* The scheduling is *not pre-emptive*.

### Priority Based Scheduling (PBS)
* Priority Based Scheduling works on the basis of priorities assigned to each process.
* The dynamic priority of the process, stored within `p->priority`, is determined by the static priority and niceness of the process.
* The static priority of the process, stored withing `p->spriority`, is set as 60 (unless modified by the `setpriority` function).
* The niceness of the process, stored within `p->niceness`, is determined by the runtime and waitimes of the process since creation/last scheduling, `p->rtime` and `p->wtime`.
* `p->rtime`, `p->wtime`, `p->niceness` and `p->priority` are updated every tick withing `update_vals()`.
* The scheduler iterates over all processes and picks the one with the highest (lowest numerical value) priority.
* In case of a tie, the scheduler picks the process with lower number of runs, `p->nrun`. If the tie still remains, the scheduler picks the process with the earlier (lower) creation time, `p->ctime`.
* The scheduling is *not pre-emptive*.

#### `set_priority` system call and `setpriority` command
* In order to set the static priority of a process to a specific value, `set_priority` system call and `setpriority` command have been implemented.
* Usage of the `setpriority` is as given below:
    ```
    setpriority priority pid
    ```
* Implementation of `set_priority` system call and `setpriority` command is similar to that of `strace`.

### Multi-Level Feedback Queues (MLFQ)
* In Multi-Level Feedback Queues, the processes are stored within multiple queues.
* There are a total of 5 queues of varying priorities, with the lowest queue having the highest priority and the highest queue having the lowest priority.
* The tick quotas for the queues are `{1, 2, 4, 8, 16}` from the lowest queue through the highest queue.
* Each new process is added to the queue 0.
* At the start of each scheduling round, if the age of the process, given by `p->atime`, is greater than the `AGE_LIMIT` (set at 30), then the process is sent to the next queue, if it exists.
* Scheduled processes run according to the time limit specified by their queues, after which they are made to yield in `usertrap()` and `kerneltrap()` functions within the `kernel/trap.c`.They then are sent to the next queue, if it exists.
* In case the process gives up control on it's own, it is sent back to the back of the same queue. This maybe exploited, as shown below.

#### Exploiting MLFQ by Yielding
* When process gives up control on it's own, it is sent back to the back of the same queue.
* Thus if the process knows the tick quotas of each queue, it can exploit it by yeilding the queue just before the tick quota gets over.
* This way, the process can use most of the tick quota and yet remain in the same high priority queue.

### Testing and Performance Comparison for Schedulers
* Testing of the scheduler was done using the userprogram `schedulertest` provided.
* The `waitx` system call used by the `schedulertest` is implemented in a manner similar to `strace`.

#### Performance comparison
* For comparing performance, for each scheduling policy, `schedulertest` was run with `CPUS=1`
* The results are as demonstrated:

    | Scheduler | Average Run Time | Average Wait Time |
    | --------- | ---------------- | ----------------- |
    | RR        | 23               | 124               |
    | FCFS      | 48               | 54                |
    | PBS       | 40               | 116               |
    | MLFQ      | 22               | 188               |

## Modifying `procdump` functionality
* `procdump` is responsible for printing the necessary information about the processes running on the OS
* The `procdump()` within `kernel/proc.c` has been modified to print additional information for each type of scheduler.

## Running the OS

* Compile and run the OS as:
    ```
    make qemu
    ```
* Scheduler can be specified during complilation as demonstrated below. Default scheduling scheme is Round-Robin (DEFAULT).
    ```
    make qemu SCHEDULER={DEFAULT, FCFS, PBS, MLFQ}
    ```
