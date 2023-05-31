# pg-collect
Data gathering script for PostgreSQL which can be useful to diagnose issues.  The tool collects numerous Operating System metrics as well as PostgreSQL metrics which can be analyzed.  These metrics are written to a text file and then tar and gzipped into an archive file which is easy to send to an engineer or attach to a support ticket.

It is best to run the script with elevated privileges in order to collect the most OS system metrics as some require root privileges.  If you cannot do this, the script will run just fine as an unprivileged user and will skip commands which require root.  

The output is sorted into sections with color output (unless you pass the "--no-color" option) for easy identification of what is being collected.  If a command is skipped, it will be identified along with either a "done" on success, or a warning message if it is unable to be successfully processed.  Time estimates for longer running commands are also shown.

Some of the commands require collecting 60 or 120 seconds of output by default.  If you are in a hurry, you can add the "--fast" option which will shorten the collection time to only 3 seconds.  Of course, this comes at the cost of not collecting as much data.

Also, if you don't need Operating System metrics, you can skip them with the "--skip-os" option.  Likewise, PostgreSQL metrics can be skipped with the "--skip-postgres" option.

This tool utilizes the [Percona Toolkit](https://www.percona.com/software/database-tools/percona-toolkit) for [pt-summary](https://docs.percona.com/percona-toolkit/pt-summary.html) and [pt-pg-summary](https://docs.percona.com/percona-toolkit/pt-pg-summary.html).  You can read more about other tools in the toolkit at [Percona Toolkit Documentation](https://docs.percona.com/percona-toolkit/index.html).  If you do not have these installed, the tool will attempt to download the required tools from the Percona Github and execute them unless you utilize the "--no-downloads" option.  These tools are read-only and make no changes to the server.  In the event you are not permitted to download tools and run them, you can always use the "--skip-downloads" option and nothing will be downloaded.

In addition, the gather.sql and gather_old.sql files are also downloaded and utilized unless you "--skip-downloads".  These SQL files can be found in [pgGather](https://github.com/percona/support-snippets/tree/master/postgresql/pg_gather) and were written by Jobin Augustine of [Percona](https://percona.com).

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

## Sample Output (Fast collection with no color)
```
mpatrick@localhost:~/postgres$ ./pg-collect.sh --fast  --no-color
Notes
PostgreSQL Data Collection Version: 0.1
Metrics collection speed: fast (3 sec)
Percona Toolkit Version: 3.5
Attempt download of Percona Toolkit (if needed): yes
Postgres Version: PostgreSQL 15.2 - Percona Distribution
User permissions: unprivileged
Postgres Server PID (Latest): 906
Postgres Server Configuration File: /etc/postgresql/15/main/postgresql.conf
Postgres Client Configuration File: /etc/postgresql/15/main/pg_hba.conf
Base working directory: /tmp/metrics
Temporary working directory: /tmp/metrics/localhost_2023-05-31_13-25-44
Creating temporary directory: done

Operating System
Collecting pt-summary: done
Collecting sysctl: done
Collecting ps: done
Collecting top: done
Collecting uname: done
Collecting dmesg: skipped (insufficient user privileges)

Logging
Collecting /var/log/syslog (up to 1000 lines): done
Collecting journalctl: done

Resource Limits
Collecting ulimit: done

Swapping
Collecting swappiness: done

NUMA
Collecting numactl: done

CPU
Collecting cpuinfo: done
Collecting mpstat (3 sec): done

Memory
Collecting meminfo: done
Collecting free/used memory: done
Collecting vmstat (3 sec): done

Storage
Collecting df: done
Collecting lsblk: done
Collecting lsblk (all): done
Collecting smartctl: skipped (insufficient user privileges)
Collecting multipath: skipped (insufficient user privileges)
Collecting lvdisplay: skipped (insufficient user privileges)
Collecting pvdisplay: skipped (insufficient user privileges)
Collecting pvs: skipped (insufficient user privileges)
Collecting vgdisplay: skipped (insufficient user privileges)
Collecting nfsstat: done

I/O
Collecting iostat (3 sec): done
Collecting nfsiostat (3 sec): done

Networking
Collecting netstat: done
Collecting sar (3 sec): done

PostgreSQL
Copying server configuration file: done
Copying client configuration file: skipped - insufficient read privileges
Collecting PIDs: done
Copying limits: done
Collecting pt-pg-summary:
INFO[0000] Connecting to the database server using: user=postgres password=****** sslmode=disable dbname=postgres
INFO[0000] Connection OK
INFO[0000] Detected PostgreSQL version: 15.0.2
INFO[0000] Getting global information
INFO[0000] Collecting global counters (1st pass)
INFO[0000] Collecting Cluster information
INFO[0000] Waiting 10 seconds to read  counters
INFO[0000] Collecting Connected Clients information
INFO[0000] Collecting Database Wait Events information
INFO[0000] Collecting Global Wait Events information
INFO[0000] Collecting Port and Data Dir information
INFO[0000] Collecting Tablespaces information
INFO[0000] Collecting Instance Settings information
INFO[0000] Collecting Slave Hosts (PostgreSQL 10+)
INFO[0000] Waiting for counters information
INFO[0010] Collecting global counters (2nd pass)
INFO[0010] Collecting processes command line information
INFO[0010] Finished collecting global information
INFO[0010] Collecting per database information
INFO[0010] Connecting to the "postgres" database
INFO[0010] Collecting Table Access information
INFO[0010] Collecting Table Cache Hit Ratio information
INFO[0010] Collecting Index Cache Hit Ratio information
INFO[0010] Connecting to the "pq" database
INFO[0010] Collecting Table Access information
INFO[0010] Collecting Table Cache Hit Ratio information
INFO[0010] Collecting Index Cache Hit Ratio information
done
Downloading 'gather.sql': done
Executing 'gather.sql' (20+ sec): done

Preparing Data Archive
Compressing files:
localhost_2023-05-31_13-25-44/
localhost_2023-05-31_13-25-44/postgres_PIDs.txt
localhost_2023-05-31_13-25-44/uname_a.txt
localhost_2023-05-31_13-25-44/netstat_s.txt
localhost_2023-05-31_13-25-44/iostat.txt
localhost_2023-05-31_13-25-44/mpstat.txt
localhost_2023-05-31_13-25-44/proc_906_limits.txt
localhost_2023-05-31_13-25-44/ps_auxf.txt
localhost_2023-05-31_13-25-44/numactl-hardware.txt
localhost_2023-05-31_13-25-44/cpuinfo.txt
localhost_2023-05-31_13-25-44/syslog
localhost_2023-05-31_13-25-44/gather.sql
localhost_2023-05-31_13-25-44/pt-summary.txt
localhost_2023-05-31_13-25-44/top.txt
localhost_2023-05-31_13-25-44/postgresql.conf
localhost_2023-05-31_13-25-44/sysctl_a.txt
localhost_2023-05-31_13-25-44/sar_dev.txt
localhost_2023-05-31_13-25-44/free_m.txt
localhost_2023-05-31_13-25-44/nfsstat_m.txt
localhost_2023-05-31_13-25-44/vmstat.txt
localhost_2023-05-31_13-25-44/lsblk.txt
localhost_2023-05-31_13-25-44/df_k.txt
localhost_2023-05-31_13-25-44/swappiness.txt
localhost_2023-05-31_13-25-44/pt-pg-summary.txt
localhost_2023-05-31_13-25-44/nfsiostat.txt
localhost_2023-05-31_13-25-44/lsblk-all.txt
localhost_2023-05-31_13-25-44/psql_gather.txt
localhost_2023-05-31_13-25-44/ulimit_a.txt
localhost_2023-05-31_13-25-44/journalctl.txt
localhost_2023-05-31_13-25-44/meminfo.txt
File saved to: /tmp/metrics/localhost_2023-05-31_13-25-44.tar.gz

Cleanup
Deleting temporary files: done
```

## Licensing
The code is Open Source and can be used as you see fit.  There is no support given and you use the code at your own risk. 
