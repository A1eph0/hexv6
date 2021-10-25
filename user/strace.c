#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main (int argc, char *argv[])
{
    // input error handling
    if(argc < 3 || argv[1][0] > '9' || argv[1][0] < '0')
    {
        fprintf(2, "strace: incorrect usage, use as: strace [mask] [command]");
        exit(1);
    }

    // initiating signal tracing for given mask
    strace(atoi(argv[1]));
    
    // execution of command
    exec(argv[2], argv+2);
    exit(0);
}