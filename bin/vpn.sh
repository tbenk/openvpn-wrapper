#!/bin/bash
## copyright: B1 Systems GmbH <info@b1-systems.de>, 2017.
## license: GPLv3+, http://www.gnu.org/licenses/gpl-3.0.html
## author: Timo Benk <benk@b1-systems.de>

# expected directory structure:
#
# $base/bin/vpn.sh
# $base/config/<NAME1>/config.opvn
# $base/config/<NAME2>/config.opvn
# $base/config/<...>/config.opvn
# $base/misc/screenrc
# $base/pidfiles/<NAME1>
# $base/pidfiles/<NAME2>
# $base/pidfiles/<...>

# openvpn config requirements:
# 
# - vpn config must be located at $base/<NAME>/config.ovpn
# - username/password auth only via auth-user-pass file

# connect to vpn screen session: screen -r vpn

base="`dirname "$(readlink -f "$0")"`/.."

# check if process with pid from _pidfile is running
check() {

  local _pidfile="$1"

  if test -f "$_pidfile"
  then

    exec 3>&2 2>/dev/null
    local pid="$(<"$_pidfile")"
    local cmd="$(<"/proc/$pid/comm")"
    exec 2>&3

    if test "$cmd" = 'openvpn'
    then

      echo $pid
      return 0
    fi

    rm -f "$_pidfile"
  fi

  return 1
}

# evaluate _pattern glob and return matching vpn configs
get_vpn() {

  local _pattern="$1"

  (cd "$base"/config; ls -d1 *$_pattern* 2>/dev/null)
}

# pretty list available and active vpn sessions
list() {

  local _pattern="$1"

  for i in `get_vpn "*$_pattern*" | sort`
  do

    pid="`check "$base"/pidfiles/"$i"`"
    if test $? -eq 0
    then

      print 'green' "$i [$pid]"
    else 

      print 'red' "$i"
    fi
  done
}

# print string in red, blue or green
print() {

  local _color="$1"
  local _text="$2"

  shift 2

  case "$_color" in 
    'red')
      _color='31'
      ;;
    'green')
      _color='32'
      ;;
    'blue')
      _color='34'
      ;;
    *)
      _color='0'
      ;;
  esac

  printf "\e[${_color}m$_text\e[0m\n" $@
}

# re-exec me inside a (possibly existing) screen session
screenify() {

  local _session="${1:-`basename "$0"`}"
  local _title="${2:-`basename "$0"`}"
  local _config="${3:-/dev/null}"

  local me="`readlink -f "$0"`"

  # step 0: return if already screenified
  local parent="`ps -hp "$PPID" -o comm 2>/dev/null`"
  if test "$parent" = "screen"

    then return
  fi

  # step 1: reverse BASH_ARGV
  for (( idx=${#BASH_ARGV[@]}-1 ; idx>=0 ; idx-- ))
  do
  
    local ARGV[${#ARGV[*]}]="${BASH_ARGV[idx]}"
  done

  # step 2: execute me in a new screen window
  if ! screen -S "$_session" -Q "select" . 1>/dev/null 2>&1
  then

    screen -d -m -t "$_title" -S "$_session" -c "$_config" "$me" "${ARGV[@]}"
  else

    screen -S "$_session" -X screen -t "$_title" "$me" "${ARGV[@]}"
  fi

  # step 3: if in debug mode, attach to the screen session
  if test -n "$DEBUG"
  then

    for i in `seq 1 100`
    do

      screen -S "$_session" -Q "select" . 1>/dev/null 2>&1 && break
      sleep 0.1
    done

    screen -r "$_session" 
  fi

  exit 0
}

# main
main() {

  local num="`get_vpn "$1" | wc -l`"
  local vpn="`get_vpn "$1"`"

  if test "$#" -eq 0
  then

    print 'blue' 'available vpn configs'
    list '*' 
    exit 1
  elif test "$num" -gt 1
  then
  
    print 'blue' 'error: more than one matching config found'
    list "$1" 
    exit 1
  elif test "$num" -eq 0
  then
    
    print 'blue' 'error: no matching config found, available vpn configurations'
    list '*' 
    exit 1
  elif check "$base"/pidfiles/"$vpn" >/dev/null
  then

    print 'blue' 'error: vpn is already active'
    list "$1" 
    exit 1
  fi

  screenify vpn "$vpn" "$base"/misc/screenrc

  trap "rm -f '$base'/pidfiles/'$vpn'" EXIT
  openvpn --writepid "$base"/pidfiles/"$vpn" --config "$base"/config/"$vpn"/config.ovpn
}

main "$@"
