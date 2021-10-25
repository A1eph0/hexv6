// init: The initial user-level program

#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/spinlock.h"
#include "kernel/sleeplock.h"
#include "kernel/fs.h"
#include "kernel/file.h"
#include "user/user.h"
#include "kernel/fcntl.h"

char *argv[] = { "sh", 0 };

int
main(void)
{
  int pid, wpid;

  if(open("console", O_RDWR) < 0){
    mknod("console", CONSOLE, 0);
    open("console", O_RDWR);
  }
  dup(0);  // stdout
  dup(0);  // stderr

  for(;;){
    printf("init: starting sh\n");
    printf("\e[1;1H\e[2J");
    printf("\033[32;1m\n\
    \n\
 ▄         ▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄       ▄  ▄               ▄  ▄▄▄▄▄▄▄▄▄▄▄ \n\
▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░▌     ▐░▌▐░▌             ▐░▌▐░░░░░░░░░░░▌\n\
▐░▌       ▐░▌▐░█▀▀▀▀▀▀▀▀▀  ▐░▌   ▐░▌  ▐░▌           ▐░▌ ▐░█▀▀▀▀▀▀▀▀▀ \n\
▐░▌       ▐░▌▐░▌            ▐░▌ ▐░▌    ▐░▌         ▐░▌  ▐░▌          \n\
▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄▄▄    ▐░▐░▌      ▐░▌       ▐░▌   ▐░█▄▄▄▄▄▄▄▄▄ \n\
▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌    ▐░▌        ▐░▌     ▐░▌    ▐░░░░░░░░░░░▌\n\
▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀▀▀    ▐░▌░▌        ▐░▌   ▐░▌     ▐░█▀▀▀▀▀▀▀█░▌\n\
▐░▌       ▐░▌▐░▌            ▐░▌ ▐░▌        ▐░▌ ▐░▌      ▐░▌       ▐░▌\n\
▐░▌       ▐░▌▐░█▄▄▄▄▄▄▄▄▄  ▐░▌   ▐░▌        ▐░▐░▌       ▐░█▄▄▄▄▄▄▄█░▌\n\
▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░▌     ▐░▌        ▐░▌        ▐░░░░░░░░░░░▌\n\
 ▀         ▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀       ▀          ▀          ▀▀▀▀▀▀▀▀▀▀▀ \n\
  \n\
  \n\
  Weclome to Hrishi's Extension of XV6\n\
  © Hrishi Narayanan 2021\n\
  \033[0;0m\n");

    
    #ifdef DEFAULT
    printf("\033[31;1mScheduling Policy: Round Robin (DEFAULT)\033[0;0m\n\n");
    #else
    #ifdef FCFS
    printf("\033[31;1mScheduling Policy: First Come First Serve (FCFS)\033[0;0m\n\n");
    #else
    #ifdef PBS
    printf("\033[31;1mScheduling Policy: Priority Based Scheduling (PBS)\033[0;0m\n\n");
    #else
    #ifdef MLFQ
    printf("\033[31;1mScheduling Policy: Multi-Level Feedback Queue (MLFQ)\033[0;0m\n\n");
    #endif
    #endif
    #endif
    #endif

    
    pid = fork();
    if(pid < 0){
      printf("init: fork failed\n");
      exit(1);
    }
    if(pid == 0){
      exec("sh", argv);
      printf("init: exec sh failed\n");
      exit(1);
    }

    for(;;){
      // this call to wait() returns if the shell exits,
      // or if a parentless process exits.
      wpid = wait((int *) 0);
      if(wpid == pid){
        // the shell exited; restart it.
        break;
      } else if(wpid < 0){
        printf("init: wait returned an error\n");
        exit(1);
      } else {
        // it was a parentless process; do nothing.
      }
    }
  }
}
