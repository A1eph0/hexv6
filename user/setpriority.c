#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main (int argc, char *argv[])
{
    // input error handling
    if(argc < 3 || argv[1][0] > '9' || argv[1][0] < '0' || argv[2][0] > '9' || argv[2][0] < '0')
    {
        fprintf(2, "setpriority: incorrect usage, use as: setpriority [priority] [pid]\n");
        exit(1);
    }

    // setting priority
    set_priority(atoi(argv[1]), atoi(argv[2]));
    
    exit(0);
}