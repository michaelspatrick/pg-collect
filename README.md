# pg-collect
Data gathering script for PostgreSQL which can be useful to diagnose issues.  The tool collects numerous Operating System metrics as well as PostgreSQL metrics which can be analyzed.  These metrics are written to a text file and then tar and gzipped into an archive file which is easy to send to an engineer or attach to a support ticket.

## Help Output
```
localhost:~/postgres$ ./pg-collect.sh --help
Usage: pg-collect.sh [-h] [-v] [-V] [-f]

Script collects various Operating System and PostgreSQL diagnostic information and stores output in an archive file.

Available options:
-h, --help        Print this help and exit
-v, --verbose     Print script debug info
-V, --version     Print script version info
-f, --fast        Shorten the collection time of OS commands which take 60+ seconds to 3 seconds
--no-color        Do not display colors
--skip-downloads  Do not attempt to download any Percona tools
--skip-os         Do not attempt to collect OS metrics
--skip-postgres   Do not attempt to collect PostgreSQL metrics
```

## Use Cases
* Collecting metrics to send to a support team to help diagnose an issue.
* Collecting metrics to send to a DBA or engineer to review during an issue.
* Collecting metrics to store as a baseline of server performance.  If and when a problem arises, these metrics could be compared against the current state.

## Licensing
The code is Open Source and can be used as you see fit.  There is no support given and you use the code at your own risk. 
