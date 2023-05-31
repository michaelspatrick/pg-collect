# pg-collect
Data gathering script for PostgreSQL which can be useful to diagnose issues.  The tool collects numerous Operating System metrics as well as PostgreSQL metrics which can be analyzed.

## help output
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
