#!/bin/bash
#
# Script collects numerous metrics for PostgreSQL and the Operating System.
# It then compresses all the data into a single archive file which can then
# be shared with Support.  Script is based upon Percona KB0010933 with a
# number of enhancements.
#
# Written by Michael Patrick (michael.patrick@percona.com)
# Version 0.1 - May 18, 2023
# Version 0.2 - November 11, 2024
#
# It is recommended to run the script as a privileged user (superuser,
# rds_superuser, etc), but it will run as any user.  You can safely ignore any
# warnings.
#
# Percona toolkit is highly encouraged to be installed and available.
# The script will attempt to download only the necessary tools from the Percona
# website.  If that too fails, it will continue gracefully, but some key metrics
# will be missing.  This can also be skipped by the --skip-downloads flag.
#
# The pt-summary and pgGather utilities will be run multi-threaded to collect
# the best metrics.
#
# Modify the Postgres connectivity section below and then you should be able
# to run the script.
#
# Use at your own risk!
#

VERSION=0.2

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

# Trap ctrl-c
trap die SIGINT

# Set postgres password in the environment
export PGPASSWORD="${PG_PASSWORD}"

# Declare some variables
DATETIME=`date +"%F_%H-%M-%S"`
HOSTNAME=`hostname`
DIRNAME="${HOSTNAME}_${DATETIME}"
CURRENTDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
PTDEST=${BASEDIR}/${DIRNAME}

# Setup colors
if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
  NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
else
  NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
fi

# Display output messages with color
msg() {
  if [ "$COLOR" = true ]; then
    echo >&2 -e "${1-}"
  else
    echo >&2 "${1-}"
  fi
}

# Check that a command exists
exists() {
  command -v "$1" >/dev/null 2>&1 ;
}

# Get the script version number
version() {
  echo "Version ${VERSION}"
  exit
}

# Display a colored heading
heading() {
  msg "${PURPLE}${1}${NOFORMAT}"
}

# Cleanup temporary files and working directory
cleanup() {
  echo
  heading "Cleanup"
  echo -n "Deleting temporary files: "
  if [ -d "${PTDEST}" ]; then
    rm -rf ${PTDEST}
    msg "${GREEN}done${NOFORMAT}"
  else
    msg "${YELLOW}skipped${NOFORMAT}"
  fi
}

# Call this when script dies suddenly
die() {
  echo
  cleanup
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

declare -a pids
declare -a processes
waitPids() {
  while [ ${#pids[@]} -ne 0 ]; do
    local range=$(eval echo {0..$((${#pids[@]}-1))})
    local i
    for i in $range; do
      if ! kill -0 ${pids[$i]} 2> /dev/null; then
        TIMESTAMP=`date +"%Y_%m_%d_%H_%M_%S"`
        echo "${TIMESTAMP} Process, ${processes[$i]}, completed."
        unset processes[$i]
        unset pids[$i]
      fi
    done
    pids=("${pids[@]}") # Expunge nulls created by unset.
    processes=("${processes[@]}") # Expunge nulls created by unset.
    sleep 1
  done
  echo "Done!"
}

addPid() {
  local desc=$1
  local pid=$2
  echo "Starting ${desc} process with PID: ${pid}"
  pids=(${pids[@]} $pid)
  processes=(${processes[@]} $desc)
}

os_metrics() {
  # Collect kernel information
  echo -n "Collecting dmesg: "
  if [ "$HAVE_SUDO" = true ] ; then
    sudo dmesg > ${PTDEST}/dmesg.txt
    sudo dmesg -T > ${PTDEST}/dmesg_t.txt
    msg "${GREEN}done${NOFORMAT}"
  else
    msg "${YELLOW}skipped (insufficient user privileges)${NOFORMAT}"
  fi
  # Get the Percona Toolkit version via pt-summary
  if exists pt-summary; then
    PT_EXISTS=true
    PT_SUMMARY=`which pt-summary`
    PT_VERSION_NUM=`${PT_SUMMARY} --version | egrep -o '[0-9]{1,}\.[0-9]{1,}'`
  else
    if [ -f "${TMPDIR}/pt-summary" ]; then
      PT_EXISTS=true
      PT_SUMMARY=${TMPDIR}/pt-summary
      chmod +x ${PT_SUMMARY}
      PT_VERSION_NUM=`${PT_SUMMARY} --version | egrep -o '[0-9]{1,}\.[0-9]{1,}'`
    else
      msg "${RED}Warning: Percona Toolkit not found.${NOFORMAT}"
      echo -n "Attempting to download the tools: "
      if [ "${SKIP_DOWNLOADS}" = false ]; then
        curl -sL https://percona.com/get/pt-summary --output ${TMPDIR}/pt-summary
        if [ $? -eq 0 ]; then
          PT_EXISTS=true
          PT_SUMMARY="${TMPDIR}/pt-summary"
          chmod +x ${PT_SUMMARY}
          PT_VERSION_NUM=`${PT_SUMMARY} --version | egrep -o '[0-9]{1,}\.[0-9]{1,}'`
          msg "${GREEN}done${NOFORMAT}"
        else
          PT_EXISTS=false
          PT_VERSION_NUM=""
          msg "${RED}failed${NOFORMAT}"
        fi
      else
        msg "${YELLOW}skipped (per user request)${NOFORMAT}"
      fi
    fi
  fi

  if [ "$PT_EXISTS" = true ]; then
    # Collect summary info using Percona Toolkit (if available)
    if ! exists $PT_SUMMARY; then
      msg "${ORANGE}warning - Percona Toolkit not found${NOFORMAT}"
    else
      ($PT_SUMMARY > ${PTDEST}/pt-summary.txt) &
      addPid "pt-summary" $!
    fi
  else
    msg "${RED}Warning: Please install the Percona Toolkit.${NOFORMAT}"
  fi

  # Collect top
  echo -n "Collecting top (background): "
  if exists top; then
    top -b -c -n 24 -d 5 > ${PTDEST}/top.txt &
    addPid "top" $!
  else
    msg "${YELLOW}skipped${NOFORMAT}"
  fi

  # Collect pidstat
  echo -n "Collecting pidstat (background): "
  if exists pidstat; then
    pidstat 1 60 > ${PTDEST}/pidstat.txt &
    addPid "pidstat" $!
    pidstat -d 1 60 > ${PTDEST}/pidstat_d.txt &
    addPid "pidstat_d" $!
  else
    msg "${YELLOW}skipped${NOFORMAT}"
  fi  
  
  # mpstat
  echo -n "Collecting mpstat (60 sec): "
  if exists mpstat; then
    mpstat -u -P ALL 1 60 > ${PTDEST}/mpstat.txt &
    addPid "mpstat" $!
  else
    msg "${YELLOW}skipped${NOFORMAT}"
  fi

  # vmstat
  echo -n "Collecting vmstat (60 sec): "
  if exists vmstat; then
    vmstat 1 60 > ${PTDEST}/vmstat.txt &
    addPid "vmstat" $!
  else
    msg "${YELLOW}skipped${NOFORMAT}"
  fi

  # Disk info
  echo -n "Collecting df: "
  if exists df; then
    df -h > ${PTDEST}/df.txt
    msg "${GREEN}done${NOFORMAT}"
  else
    msg "${YELLOW}skipped${NOFORMAT}"
  fi

  # lsblk
  echo -n "Collecting lsblk (all): "
  if exists lsblk; then
    lsblk --ascii > ${PTDEST}/lsblk.txt
    msg "${GREEN}done${NOFORMAT}"
  else
    msg "${YELLOW}skipped${NOFORMAT}"
  fi

  # iostat
  echo -n "Collecting iostat (60 sec): "
  if exists iostat; then
    iostat -dx 1 60 > ${PTDEST}/iostat.txt &
    addPid "iostat" $!
  else
    msg "${YELLOW}skipped${NOFORMAT}"
  fi

  # sysctl
  echo -n "Collecting sysctl: "
  if exists sysctl; then
    sysctl -a > ${PTDEST}/sysctl.txt
    msg "${GREEN}done${NOFORMAT}"
  else
    msg "${YELLOW}skipped${NOFORMAT}"
  fi

  # mount
  echo -n "Collecting mount: "
  if exists mount; then
    mount > ${PTDEST}/mount.txt
    msg "${GREEN}done${NOFORMAT}"
  else
    msg "${YELLOW}skipped${NOFORMAT}"
  fi
}

postgres_metrics() {
  # Get the Postgres version number
  if exists pg_config; then
    PG_VERSION_STR=`pg_config --version`
  fi
  if exists psql; then
    PSQL_EXISTS=true
    PG_VERSION_NUM=`psql -V | egrep -o '[0-9]{1,}\.[0-9]{1,}'`
  else
    PSQL_EXISTS=false
    die "Error: Cannot connect to PostgreSQL!"
  fi

  if exists pg_isready; then
    echo -n "Testing connection to PostgreSQL: "
    pg_isready >/dev/null 2>&1
    if [ $? -eq 0 ]; then
      msg "${GREEN}success${NOFORMAT}"
    else
      msg "${RED}Cannot connect to database!${NOFORMAT}"
      die
    fi
  fi

  # Get the location of the PG config file
  PG_CONFIG=`$PSQL_CONNECT_STR -t -c 'SHOW config_file' | xargs`
  PG_HBA_CONFIG=`$PSQL_CONNECT_STR -t -c 'SHOW hba_file' | xargs`

  # Display the PostgreSQL version number
  echo -n "Postgres Version: "
  msg "${GREEN}${PG_VERSION_STR}${NOFORMAT}"

  # Copy Postgres server configuration file
  echo -n "Copying server configuration file: "
  if [ -r "${PG_CONFIG}" ]; then
    cp ${PG_CONFIG} ${PTDEST}
    if [ $? -eq 0 ]; then
      msg "${GREEN}done${NOFORMAT}"
    else
      msg "${RED}failed${NOFORMAT}"
    fi
  else
    msg "${YELLOW}skipped - insufficient read privileges${NOFORMAT}"
  fi

  # Copy Postgres client configuration file
  echo -n "Copying client configuration file: "
  if [ -r "${PG_HBA_CONFIG}" ]; then
    cp ${PG_HBA_CONFIG} ${PTDEST}
    if [ $? -eq 0 ]; then
      msg "${GREEN}done${NOFORMAT}"
    else
      msg "${RED}failed${NOFORMAT}"
    fi
  else
    msg "${YELLOW}skipped - insufficient read privileges${NOFORMAT}"
  fi

  # Get all Postgres PIDs
  echo -n "Collecting PIDs: "
  pgrep -x postgres > "${PTDEST}/postgres_PIDs.txt"
  if [ $? -eq 0 ]; then
    msg "${GREEN}done${NOFORMAT}"
  else
    msg "${RED}failed${NOFORMAT}"
  fi

  # Get the Postgres gather SQL script and run it
  if awk "BEGIN {exit !($PG_VERSION_NUM >= 10.0)}"; then
    # For versions greater than 10.0, download this SQL script
    SQLFILE="gather.sql"
  else
    # For earlier versions, download this SQL script
    SQLFILE="gather_old.sql"
  fi

  # Check for SQL file in the current dir.  Use instead of downloading if found.
  echo -n "Checking for '${SQLFILE}': "
  if [ -f "${TMPDIR}/${SQLFILE}" ]; then
    msg "${GREEN}found${NOFORMAT}"
    cp ${TMPDIR}/${SQLFILE} ${PTDEST}
    EXECUTE_SQLFILE=true
  else
    msg "${YELLOW}not found${NOFORMAT}"
    EXECUTE_SQLFILE=false

    echo -n "Downloading '${SQLFILE}': "
    if [ "${SKIP_DOWNLOADS}" = false ]; then
      if [ "$PSQL_EXISTS" = true ]; then
        curl -sL https://raw.githubusercontent.com/percona/support-snippets/master/postgresql/pg_gather/${SQLFILE} --output ${TMPDIR}/${SQLFILE}
        if [ $? -eq 0 ]; then
          msg "${GREEN}done${NOFORMAT}"
          EXECUTE_SQLFILE=true
        else
          msg "${RED}failed (file does not exist)${NOFORMAT}"
        fi
      else
        msg "${RED}failed (psql does not exist)${NOFORMAT}"
      fi
    else
      msg "${YELLOW}skipped (per user request)${NOFORMAT}"
    fi
  fi

  if [ "${EXECUTE_SQLFILE}" = true ]; then
    #echo -n "Executing '${SQLFILE}' (20+ sec): "
    if [ -f "$TMPDIR/$SQLFILE" ]; then
      (${PSQL_CONNECT_STR} -X -f ${TMPDIR}/${SQLFILE} > ${PTDEST}/pgGather.txt) &
      addPid "pgGather" $!
    else
      msg "${RED}failed${NOFORMAT}"
    fi
  fi
}

# Display script usage
usage() {
  cat << EOF # remove the space between << and EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-p] [-U] [-v] [-V] [-W] [--help] [--no-color] [--skip-downloads]

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
EOF
  exit
}

# Parse command line options and parameters
parse_params() {
  # default values of variables set from params
  COLOR=true             # Whether or not to show colored output
  SKIP_DOWNLOADS=false   # Whether to skip attempts to download Percona toolkit and scripts

  while :; do
    case "${1-}" in
    --help) usage ;;
    -p | --port) PG_PORT="${2-}"; shift ;;
    -U | --username) PG_USER="${2-}"; shift ;;
    -W | --password) PG_PASSWORD="${2-}"; shift ;;
    -v | --verbose) set -x ;;
    -V | --version) version ;;
    --no-color) COLOR=false ;;
    --skip-downloads) SKIP_DOWNLOADS=true ;;
    -?*) die "Unknown option: $1" ;;
    *) break; die ;;
    esac
    shift
  done

  args=("$@")

  PSQL_CONNECT_STR="psql -U${PG_USER} -p${PG_PORT}"
  export PGPASSWORD="${PG_PASSWORD}"

  return 0
}

parse_params "$@"

# If user doesn't want color displayed, reset the color values to empty strings
if [ "$COLOR" = false ]; then
  NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
fi

# Check to ensure running as root
if [ "$EUID" -ne 0 ]; then
  HAVE_SUDO=false
else
  HAVE_SUDO=true
fi

heading "Collecting Metrics"

# Display script version
echo -n "PostgreSQL Data Collection Version: "
msg "${GREEN}${VERSION}${NOFORMAT}"

# Display user permissions
echo -n "User permissions: "
if [ "$HAVE_SUDO" = true ] ; then
  msg "${GREEN}root${NOFORMAT}"
else
  msg "${YELLOW}unprivileged${NOFORMAT}"
fi

# Display temporary directory
echo -n "Creating temporary directory (${PTDEST}): "
mkdir -p ${PTDEST}
if [ $? -eq 0 ]; then
  msg "${GREEN}done${NOFORMAT}"
else
  msg "${RED}failed${NOFORMAT}"
  exit 1
fi

# Collect Postgres metrics
postgres_metrics

# Collect the OS metrics
os_metrics

# Wait for forked processes to complete
waitPids

echo
heading "Preparing Data Archive"

# Compress files for sending to Percona
cd ${BASEDIR}
chmod a+r ${DIRNAME} -R
echo "Compressing files:"
DEST_TGZ="$(dirname ${PTDEST})/${DIRNAME}.tar.gz"
tar czvf "${DEST_TGZ}" ${DIRNAME}

# Show compressed file location
echo -n "File saved to: "
msg "${CYAN}${DEST_TGZ}${NOFORMAT}"

# Do Cleanup
cleanup

# Exit clean
exit 0
