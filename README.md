# pg-collect
Data gathering script for PostgreSQL, written in Bash, which can be useful to diagnose issues.  The tool collects numerous Operating System metrics as well as PostgreSQL metrics which can be analyzed.  These metrics are written to text files and then tar and gzipped into an archive file which is easy to send to an engineer or attach to a support ticket.  If using the Percona Toolkit, processes are multi-threaded so that OS metrics and database metrics are collected simultaneously.

It is best to run the script with elevated privileges in order to collect the most OS system metrics as some require root privileges.  If you cannot do this, the script will run just fine as an unprivileged user and will skip commands which require root.  

The output is sorted into sections with color output (unless you pass the "--no-color" option) for easy identification of what is being collected.  If a command is skipped, it will be identified along with either a "done" on success, or a warning message if it is unable to be successfully processed.  Time estimates for longer running commands are also shown.

Also, if you don't need Operating System metrics, you can skip them with the "--skip-os" option.  Likewise, PostgreSQL metrics can be skipped with the "--skip-postgres" option.

This tool utilizes the [Percona Toolkit](https://www.percona.com/software/database-tools/percona-toolkit) for [pt-summary](https://docs.percona.com/percona-toolkit/pt-summary.html) and [pt-pg-summary](https://docs.percona.com/percona-toolkit/pt-pg-summary.html).  You can read more about other tools in the toolkit at [Percona Toolkit Documentation](https://docs.percona.com/percona-toolkit/index.html).  If you do not have these installed, the tool will attempt to download the required tools from the Percona Github and execute them unless you utilize the "--no-downloads" option.  These tools are read-only and make no changes to the server.  In the event you are not permitted to download tools and run them, you can always use the "--skip-downloads" option and nothing will be downloaded.

In addition, the gather.sql and gather_old.sql files are also downloaded and utilized unless you "--skip-downloads".  These SQL files can be found in [pgGather](https://github.com/percona/support-snippets/tree/master/postgresql/pg_gather) and were written by Jobin Augustine of [Percona](https://percona.com).

You can also save the Percona Toolkit and pgGather scripts locally in the TMPDIR and the script will look for them there to execute.

## Help Output
```
localhost:~/postgres$ ./pg-collect.sh --help
Usage: pg-collect.sh [-h] [-v] [-V] [-f]

Script collects various Operating System and PostgreSQL diagnostic information and stores output in an archive file.

Available options:
-h, --help        Print this help and exit
-v, --verbose     Print script debug info
-V, --version     Print script version info
--no-color        Do not display colors
--skip-downloads  Do not attempt to download any Percona tools
--skip-os         Do not attempt to collect OS metrics
--skip-postgres   Do not attempt to collect PostgreSQL metrics
```

## Use Cases
* Collecting metrics to send to a support team to help diagnose an issue.
* Collecting metrics to send to a DBA or engineer to review during an issue.
* Collecting metrics to store as a baseline of server performance.  If and when a problem arises, these metrics could be compared against the current state.

## Sample Output (Fast collection with no color)
```
mpatrick@localhost:~/postgres$ ./pg-collect.sh
Notes
PostgreSQL Data Collection Version: 0.1
User permissions: unprivileged
Creating temporary directory (/tmp/metrics/localhost_2023-06-02_15-17-12): done

Operating System
Collecting uname: done
Collecting dmesg: skipped (insufficient user privileges)
Collecting /var/log/syslog (up to 1000 lines): done
Collecting journalctl: done
Percona Toolkit Version: 3.5
Starting pt-summary process with PID: 178582
Starting pt-stalk process with PID: 178583

PostgreSQL
Postgres Version: PostgreSQL 15.2 - Percona Distribution
Copying server configuration file: done
Copying client configuration file: skipped - insufficient read privileges
Collecting PIDs: done
Checking for 'gather.sql': found
Starting pgGather process with PID: 178791
2023_06_02_15_17_14 Starting /usr/bin/pt-stalk --function=status --variable=Threads_running --threshold=25 --match= --cycles=0 --interval=1 --iterations=4 --run-time=30 --sleep=30 --dest=/tmp/metrics/localhost_2023-06-02_15-17-12 --prefix= --notify-by-email= --log=/var/log/pt-stalk.log --pid=/var/run/pt-stalk.pid --plugin=
2023_06_02_15_17_14 Not running with root privileges!
2023_06_02_15_17_14 Not stalking; collect triggered immediately
2023_06_02_15_17_14 Collect 1 triggered
2023_06_02_15_17_14 SYSTEM_ONLY: yes
2023_06_02_15_17_14 Collect 1 PID 179214
2023_06_02_15_17_14 Collect 1 done
2023_06_02_15_17_15 Sleeping 30 seconds after collect
2023_06_02_15_17_20 Process, pt-summary, completed.
2023_06_02_15_17_37 Process, pgGather, completed.
2023_06_02_15_17_45 Not stalking; collect triggered immediately
2023_06_02_15_17_45 Collect 2 triggered
2023_06_02_15_17_45 SYSTEM_ONLY: yes
2023_06_02_15_17_45 Collect 2 PID 180722
2023_06_02_15_17_45 Collect 2 done
2023_06_02_15_17_45 Sleeping 30 seconds after collect
2023_06_02_15_18_15 Not stalking; collect triggered immediately
2023_06_02_15_18_15 Collect 3 triggered
2023_06_02_15_18_15 SYSTEM_ONLY: yes
2023_06_02_15_18_15 Collect 3 PID 182093
2023_06_02_15_18_15 Collect 3 done
2023_06_02_15_18_15 Sleeping 30 seconds after collect
2023_06_02_15_18_46 Not stalking; collect triggered immediately
2023_06_02_15_18_46 Collect 4 triggered
2023_06_02_15_18_46 SYSTEM_ONLY: yes
2023_06_02_15_18_46 Collect 4 PID 183537
2023_06_02_15_18_46 Collect 4 done
2023_06_02_15_18_46 Waiting up to 90 seconds for subprocesses to finish...
2023_06_02_15_19_47 Exiting because no more iterations
2023_06_02_15_19_47 /usr/bin/pt-stalk exit status 0
2023_06_02_15_19_48 Process, pt-stalk, completed.
Done!

Preparing Data Archive
Compressing files:
localhost_2023-06-02_15-17-12/
localhost_2023-06-02_15-17-12/postgres_PIDs.txt
localhost_2023-06-02_15-17-12/2023_06_02_15_18_15-top
localhost_2023-06-02_15-17-12/uname_a.txt
localhost_2023-06-02_15-17-12/2023_06_02_15_17_14-netstat_s
localhost_2023-06-02_15-17-12/2023_06_02_15_18_46-df
localhost_2023-06-02_15-17-12/2023_06_02_15_17_14-output
localhost_2023-06-02_15-17-12/2023_06_02_15_18_46-diskstats
localhost_2023-06-02_15-17-12/2023_06_02_15_17_45-hostname
localhost_2023-06-02_15-17-12/2023_06_02_15_18_46-top
localhost_2023-06-02_15-17-12/2023_06_02_15_18_46-mpstat-overall
localhost_2023-06-02_15-17-12/2023_06_02_15_17_45-iostat-overall
localhost_2023-06-02_15-17-12/2023_06_02_15_18_15-numastat
localhost_2023-06-02_15-17-12/2023_06_02_15_17_45-df
localhost_2023-06-02_15-17-12/2023_06_02_15_17_14-numastat
localhost_2023-06-02_15-17-12/2023_06_02_15_18_46-vmstat-overall
localhost_2023-06-02_15-17-12/pgGather.txt
localhost_2023-06-02_15-17-12/2023_06_02_15_18_15-netstat
localhost_2023-06-02_15-17-12/2023_06_02_15_18_15-vmstat-overall
localhost_2023-06-02_15-17-12/2023_06_02_15_17_14-vmstat-overall
localhost_2023-06-02_15-17-12/2023_06_02_15_18_46-procvmstat
localhost_2023-06-02_15-17-12/2023_06_02_15_17_14-hostname
localhost_2023-06-02_15-17-12/2023_06_02_15_18_15-ps
localhost_2023-06-02_15-17-12/2023_06_02_15_18_15-disk-space
localhost_2023-06-02_15-17-12/2023_06_02_15_18_15-meminfo
localhost_2023-06-02_15-17-12/2023_06_02_15_17_45-iostat
localhost_2023-06-02_15-17-12/2023_06_02_15_18_46-vmstat
localhost_2023-06-02_15-17-12/2023_06_02_15_18_15-procstat
localhost_2023-06-02_15-17-12/2023_06_02_15_17_45-trigger
localhost_2023-06-02_15-17-12/2023_06_02_15_17_45-netstat_s
localhost_2023-06-02_15-17-12/2023_06_02_15_17_14-trigger
localhost_2023-06-02_15-17-12/2023_06_02_15_18_15-iostat-overall
localhost_2023-06-02_15-17-12/2023_06_02_15_18_46-iostat
localhost_2023-06-02_15-17-12/2023_06_02_15_17_45-sysctl
localhost_2023-06-02_15-17-12/2023_06_02_15_18_15-procvmstat
localhost_2023-06-02_15-17-12/syslog
localhost_2023-06-02_15-17-12/2023_06_02_15_17_14-procstat
localhost_2023-06-02_15-17-12/2023_06_02_15_17_14-diskstats
localhost_2023-06-02_15-17-12/2023_06_02_15_17_45-disk-space
localhost_2023-06-02_15-17-12/2023_06_02_15_17_14-vmstat
localhost_2023-06-02_15-17-12/2023_06_02_15_17_14-netstat
localhost_2023-06-02_15-17-12/gather.sql
localhost_2023-06-02_15-17-12/pt-summary.txt
localhost_2023-06-02_15-17-12/2023_06_02_15_18_46-numastat
localhost_2023-06-02_15-17-12/2023_06_02_15_17_45-vmstat
localhost_2023-06-02_15-17-12/2023_06_02_15_18_46-netstat
localhost_2023-06-02_15-17-12/2023_06_02_15_18_15-diskstats
localhost_2023-06-02_15-17-12/2023_06_02_15_18_46-interrupts
localhost_2023-06-02_15-17-12/2023_06_02_15_18_46-trigger
localhost_2023-06-02_15-17-12/2023_06_02_15_17_14-disk-space
localhost_2023-06-02_15-17-12/2023_06_02_15_18_46-ps
localhost_2023-06-02_15-17-12/2023_06_02_15_17_45-mpstat-overall
localhost_2023-06-02_15-17-12/2023_06_02_15_18_46-hostname
localhost_2023-06-02_15-17-12/2023_06_02_15_17_45-numastat
localhost_2023-06-02_15-17-12/postgresql.conf
localhost_2023-06-02_15-17-12/2023_06_02_15_17_14-sysctl
localhost_2023-06-02_15-17-12/2023_06_02_15_17_14-iostat
localhost_2023-06-02_15-17-12/2023_06_02_15_18_46-procstat
localhost_2023-06-02_15-17-12/2023_06_02_15_18_15-mpstat-overall
localhost_2023-06-02_15-17-12/2023_06_02_15_17_45-interrupts
localhost_2023-06-02_15-17-12/2023_06_02_15_17_45-diskstats
localhost_2023-06-02_15-17-12/2023_06_02_15_18_15-hostname
localhost_2023-06-02_15-17-12/2023_06_02_15_17_45-vmstat-overall
localhost_2023-06-02_15-17-12/2023_06_02_15_18_46-meminfo
localhost_2023-06-02_15-17-12/2023_06_02_15_18_15-trigger
localhost_2023-06-02_15-17-12/2023_06_02_15_17_45-ps
localhost_2023-06-02_15-17-12/2023_06_02_15_17_14-meminfo
localhost_2023-06-02_15-17-12/2023_06_02_15_18_15-sysctl
localhost_2023-06-02_15-17-12/2023_06_02_15_17_45-output
localhost_2023-06-02_15-17-12/2023_06_02_15_17_45-top
localhost_2023-06-02_15-17-12/2023_06_02_15_17_14-procvmstat
localhost_2023-06-02_15-17-12/2023_06_02_15_17_45-mpstat
localhost_2023-06-02_15-17-12/2023_06_02_15_18_15-df
localhost_2023-06-02_15-17-12/2023_06_02_15_17_14-ps
localhost_2023-06-02_15-17-12/2023_06_02_15_18_15-output
localhost_2023-06-02_15-17-12/2023_06_02_15_18_15-interrupts
localhost_2023-06-02_15-17-12/2023_06_02_15_17_45-netstat
localhost_2023-06-02_15-17-12/2023_06_02_15_17_14-top
localhost_2023-06-02_15-17-12/2023_06_02_15_18_46-disk-space
localhost_2023-06-02_15-17-12/2023_06_02_15_18_46-netstat_s
localhost_2023-06-02_15-17-12/2023_06_02_15_17_14-mpstat-overall
localhost_2023-06-02_15-17-12/2023_06_02_15_17_14-mpstat
localhost_2023-06-02_15-17-12/2023_06_02_15_18_46-iostat-overall
localhost_2023-06-02_15-17-12/2023_06_02_15_17_14-interrupts
localhost_2023-06-02_15-17-12/2023_06_02_15_18_15-iostat
localhost_2023-06-02_15-17-12/2023_06_02_15_18_46-sysctl
localhost_2023-06-02_15-17-12/2023_06_02_15_17_45-procstat
localhost_2023-06-02_15-17-12/2023_06_02_15_18_15-vmstat
localhost_2023-06-02_15-17-12/2023_06_02_15_18_15-netstat_s
localhost_2023-06-02_15-17-12/2023_06_02_15_18_15-mpstat
localhost_2023-06-02_15-17-12/2023_06_02_15_18_46-mpstat
localhost_2023-06-02_15-17-12/2023_06_02_15_17_45-procvmstat
localhost_2023-06-02_15-17-12/2023_06_02_15_17_14-df
localhost_2023-06-02_15-17-12/journalctl.txt
localhost_2023-06-02_15-17-12/2023_06_02_15_17_14-iostat-overall
localhost_2023-06-02_15-17-12/2023_06_02_15_18_46-output
localhost_2023-06-02_15-17-12/2023_06_02_15_17_45-meminfo
File saved to: /tmp/metrics/localhost_2023-06-02_15-17-12.tar.gz

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
PG_DBNAME="postgres"
PSQL_CONNECT_STR="psql -U${PG_USER} -d ${PG_DBNAME}"

# Number of log entries to collect from messages or syslog
NUM_LOG_LINES=1000

# -------------------------- End Configuation --------------------------
```

## Licensing
The code is Open Source and can be used as you see fit.  There is no support given and you use the code at your own risk. 
