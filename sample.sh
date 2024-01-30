#!/usr/bin/env bash
#
BASHLIB="$( dirname $( readlink -f "$0" ) )/bashlib.sh"
source $BASHLIB || exit 1
#

# for more details see getopt(1)
declare -rA __options__=(
    [short]="Ais::hV" [long]="no-addrconfig,no-idn,service::,help,usage,version"
)

# text borrowed from 'getent'
_usage( ) {
cat <<EOF

Usage: $__this__ [OPTION...] database [key ...]
Get entries from administrative database.

  -A, --no-addrconfig        do not filter out unsupported IPv4/IPv6 addresses
                             (with ahosts*)
  -i, --no-idn               disable IDN encoding
  -s, --service=CONFIG       Service configuration to be used
  -h, --help                 Give this help list
      --usage                Give a short usage message
  -V, --version              Print program version

Mandatory or optional arguments to long options are also mandatory or optional
for any corresponding short options.

Supported databases:
ahosts ahostsv4 ahostsv6 aliases ethers group gshadow hosts initgroups
netgroup networks passwd protocols rpc services shadow
EOF
}

# clear options
unset NOADDRCONFIG NOIDN SERVICE VERSION

# options callback
_on_options( ) {
    local opt="$1" arg="$2"
    case $opt in
        A|no-addrconfig) NOADDRCONFIG=yes ;;
        i|no-idn) NOIDN=yes ;;
        s|service) _is_not_empty arg && SERVICE="$arg"; true ;;
        h|help) _usage; exit 0 ;;
        usage) _usage; exit 0 ;;
        V|version) VERSION="Version-0.99" ;;
    esac
}

# clear parameter
unset DATABASE KEYS

SUPPORTED=(
    ahosts ahostsv4 ahostsv6 aliases ethers group gshadow hosts initgroups
    netgroup networks passwd protocols rpc services shadow
)

##
##  M A I N
##
__main__( ) {

    # print version and ignore the rest
    _is_set VERSION && { echo $VERSION; exit 0; }

    # set database
    (( $# > 0 )) || _fatal no database.
    DATABASE="${1,,}"; shift;
    _in_array SUPPORTED $DATABASE || \
        _fatal database \'$DATABASE\' is not supported.

    # set keys
    KEYS=( $@ )

    # show options
    for option in NOADDRCONFIG NOIDN SERVICE; do
        _is_set $option && echo option $option is set to \'${!option}\'.
    done

    # show database and keys
    echo database=\'$DATABASE\'
    (( ${#KEYS[@]} > 0 )) && { \
        echo -n keys=\(\  
        for key in ${KEYS[@]}; do echo -n $key \ ; done
        echo \)
    }
    return 0
}

__run__ 
