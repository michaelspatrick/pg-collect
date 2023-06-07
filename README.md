# pg-collect
Data gathering script for PostgreSQL, written in Bash, which can be useful to diagnose issues.  The tool collects numerous Operating System metrics as well as PostgreSQL metrics which can be analyzed.  These metrics are written to text files and then tar and gzipped into an archive file which is easy to send to an engineer or attach to a support ticket.  If using the Percona Toolkit, processes are multi-threaded so that OS metrics and database metrics are collected simultaneously.

It is best to run the script with elevated privileges in order to collect the most OS system metrics as some require root privileges.  If you cannot do this, the script will run just fine as an unprivileged user and will skip commands which require root.  

The output is colorized (unless you pass the "--no-color" option) for easy identification of successful commands versus warnings or errors.  If a command is skipped, it will be identified along with either a "done" on success, or a warning message if it is unable to be successfully processed.  Time estimates for longer running commands are also shown.

This tool utilizes the [Percona Toolkit](https://www.percona.com/software/database-tools/percona-toolkit) for [pt-summary](https://docs.percona.com/percona-toolkit/pt-summary.html) and [pt-pg-summary](https://docs.percona.com/percona-toolkit/pt-pg-summary.html).  You can read more about other tools in the toolkit at [Percona Toolkit Documentation](https://docs.percona.com/percona-toolkit/index.html).  If you do not have these installed, the tool will attempt to download the required tools from the Percona Github and execute them unless you utilize the "--no-downloads" option.  These tools are read-only and make no changes to the server.  In the event you are not permitted to download tools and run them, you can always use the "--skip-downloads" option and nothing will be downloaded.

In addition, the gather.sql and gather_old.sql files are also downloaded and utilized unless you "--skip-downloads".  These SQL files can be found in [pgGather](https://github.com/percona/support-snippets/tree/master/postgresql/pg_gather) and were written by Jobin Augustine of [Percona](https://percona.com).

You can also save the Percona Toolkit and pgGather scripts locally in the TMPDIR and the script will look for them there to execute.

## Help Output
```
mpatrick@localhost:~/postgres$ ./pg-collect.sh --help
Usage: pg-collect.sh [-p] [-U] [-v] [-V] [-W] [--help] [--no-color] [--skip-downloads]

Script collects various Operating System and PostgreSQL diagnostic information and stores output in an archive file.

Available options:
--help        Print this help and exit
-p, --port        database server port
-U, --username    database user name
-v, --verbose     Print script debug info
-V, --version     Print script version info
-W, --password    database password
--no-color        Do not display colors
--skip-downloads  Do not attempt to download any Percona tools
```

## Use Cases
* Collecting metrics to send to a support team to help diagnose an issue.
* Collecting metrics to send to a DBA or engineer to review during an issue.
* Collecting metrics to store as a baseline of server performance.  If and when a problem arises, these metrics could be compared against the current state.

## Sample Output (Fast collection with no color)
```
mpatrick@localhost:~/postgres$ ./pg-collect.sh
Collecting Metrics
PostgreSQL Data Collection Version: 0.1
User permissions: unprivileged
Creating temporary directory (/tmp/metrics/localhost_2023-06-07_01-21-18): done
Testing connection to PostgreSQL: success
Postgres Version: PostgreSQL 15.2 - Percona Distribution
Copying server configuration file: done
Copying client configuration file: skipped - insufficient read privileges
Collecting PIDs: done
Checking for 'gather.sql': found
Starting pgGather process with PID: 346312
Collecting uname: done
Collecting dmesg: skipped (insufficient user privileges)
Collecting /var/log/syslog (up to 1000 lines): done
Collecting journalctl: done
Percona Toolkit Version: 3.5
Starting pt-summary process with PID: 346396
Starting pt-stalk process with PID: 346397
2023_06_07_01_21_21 Starting /usr/bin/pt-stalk --function=status --variable=Threads_running --threshold=25 --match= --cycles=0 --interval=1 --iterations=2 --run-time=30 --sleep=30 --dest=/tmp/metrics/localhost_2023-06-07_01-21-18 --prefix= --notify-by-email= --log=/tmp/metrics/localhost_2023-06-07_01-21-18/pt-stalk.log --pid=/var/run/pt-stalk.pid --plugin=
2023_06_07_01_21_21 Not running with root privileges!
2023_06_07_01_21_21 Not stalking; collect triggered immediately
2023_06_07_01_21_21 Collect 1 triggered
2023_06_07_01_21_21 SYSTEM_ONLY: yes
2023_06_07_01_21_21 Collect 1 PID 347034
2023_06_07_01_21_21 Collect 1 done
2023_06_07_01_21_21 Sleeping 30 seconds after collect
2023_06_07_01_21_25 Process, pt-summary, completed.
2023_06_07_01_21_42 Process, pgGather, completed.
2023_06_07_01_21_51 Not stalking; collect triggered immediately
2023_06_07_01_21_51 Collect 2 triggered
2023_06_07_01_21_51 SYSTEM_ONLY: yes
2023_06_07_01_21_51 Collect 2 PID 348542
2023_06_07_01_21_51 Collect 2 done
2023_06_07_01_21_51 Waiting up to 90 seconds for subprocesses to finish...
2023_06_07_01_22_52 Exiting because no more iterations
2023_06_07_01_22_52 /usr/bin/pt-stalk exit status 0
2023_06_07_01_22_52 Process, pt-stalk, completed.
Done!

Preparing Data Archive
Compressing files:
localhost_2023-06-07_01-21-18/
localhost_2023-06-07_01-21-18/postgres_PIDs.txt
localhost_2023-06-07_01-21-18/uname_a.txt
localhost_2023-06-07_01-21-18/2023_06_07_01_21_21-ps
localhost_2023-06-07_01-21-18/2023_06_07_01_21_21-netstat_s
localhost_2023-06-07_01-21-18/2023_06_07_01_21_21-numastat
localhost_2023-06-07_01-21-18/2023_06_07_01_21_51-trigger
localhost_2023-06-07_01-21-18/pgGather.txt
localhost_2023-06-07_01-21-18/2023_06_07_01_21_51-netstat_s
localhost_2023-06-07_01-21-18/2023_06_07_01_21_51-hostname
localhost_2023-06-07_01-21-18/2023_06_07_01_21_21-meminfo
localhost_2023-06-07_01-21-18/2023_06_07_01_21_21-output
localhost_2023-06-07_01-21-18/2023_06_07_01_21_21-mpstat
localhost_2023-06-07_01-21-18/2023_06_07_01_21_51-iostat-overall
localhost_2023-06-07_01-21-18/2023_06_07_01_21_51-interrupts
localhost_2023-06-07_01-21-18/syslog
localhost_2023-06-07_01-21-18/gather.sql
localhost_2023-06-07_01-21-18/pt-summary.txt
localhost_2023-06-07_01-21-18/2023_06_07_01_21_21-netstat
localhost_2023-06-07_01-21-18/2023_06_07_01_21_51-mpstat
localhost_2023-06-07_01-21-18/2023_06_07_01_21_21-sysctl
localhost_2023-06-07_01-21-18/2023_06_07_01_21_51-netstat
localhost_2023-06-07_01-21-18/2023_06_07_01_21_51-procvmstat
localhost_2023-06-07_01-21-18/2023_06_07_01_21_51-diskstats
localhost_2023-06-07_01-21-18/2023_06_07_01_21_51-top
localhost_2023-06-07_01-21-18/2023_06_07_01_21_21-disk-space
localhost_2023-06-07_01-21-18/2023_06_07_01_21_21-diskstats
localhost_2023-06-07_01-21-18/postgresql.conf
localhost_2023-06-07_01-21-18/2023_06_07_01_21_21-vmstat-overall
localhost_2023-06-07_01-21-18/2023_06_07_01_21_21-hostname
localhost_2023-06-07_01-21-18/2023_06_07_01_21_21-iostat
localhost_2023-06-07_01-21-18/2023_06_07_01_21_21-interrupts
localhost_2023-06-07_01-21-18/2023_06_07_01_21_51-output
localhost_2023-06-07_01-21-18/2023_06_07_01_21_51-df
localhost_2023-06-07_01-21-18/2023_06_07_01_21_51-vmstat-overall
localhost_2023-06-07_01-21-18/2023_06_07_01_21_51-ps
localhost_2023-06-07_01-21-18/2023_06_07_01_21_51-disk-space
localhost_2023-06-07_01-21-18/2023_06_07_01_21_21-procvmstat
localhost_2023-06-07_01-21-18/2023_06_07_01_21_51-procstat
localhost_2023-06-07_01-21-18/2023_06_07_01_21_21-procstat
localhost_2023-06-07_01-21-18/2023_06_07_01_21_21-df
localhost_2023-06-07_01-21-18/2023_06_07_01_21_51-mpstat-overall
localhost_2023-06-07_01-21-18/2023_06_07_01_21_21-trigger
localhost_2023-06-07_01-21-18/2023_06_07_01_21_51-vmstat
localhost_2023-06-07_01-21-18/2023_06_07_01_21_21-mpstat-overall
localhost_2023-06-07_01-21-18/2023_06_07_01_21_51-iostat
localhost_2023-06-07_01-21-18/2023_06_07_01_21_21-vmstat
localhost_2023-06-07_01-21-18/2023_06_07_01_21_21-iostat-overall
localhost_2023-06-07_01-21-18/2023_06_07_01_21_21-top
localhost_2023-06-07_01-21-18/journalctl.txt
localhost_2023-06-07_01-21-18/2023_06_07_01_21_51-meminfo
localhost_2023-06-07_01-21-18/2023_06_07_01_21_51-sysctl
localhost_2023-06-07_01-21-18/2023_06_07_01_21_51-numastat
File saved to: /tmp/metrics/localhost_2023-06-07_01-21-18.tar.gz

Cleanup
Deleting temporary files: done
```

## Getting Started
After downloading the script, you can edit the PostgreSQL configuration variables at the top of the script.  If you want to change the location of the temporary directory or the number of lines of system logs collected, you can do so in the Configuration section as noted below:
```
# ------------------------- Begin Configuation -------------------------

# Setup directory paths
TMPDIR=/tmp
BASEDIR=${TMPDIR}/metrics

# Postgres connectivity
PG_USER="postgres"
PG_PASSWORD="password"
PG_PORT=5432

# Number of log entries to collect from messages or syslog
NUM_LOG_LINES=1000

# -------------------------- End Configuation --------------------------
```

## Licensing
The code is Open Source and can be used as you see fit.  There is no support given and you use the code at your own risk. 
