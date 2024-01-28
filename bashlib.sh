#!/usr/bin/env bash
#

[[ $TRACE ]] && set -o xtrace

set -o errexit
set -o nounset
set -o pipefail
set -o errtrace

[[ -v BASHLIB2 ]] || exit 255

declare -r __here__="$( dirname $( readlink -f "$0" ) )"
declare -r __this__="${0##*/}"

# signal handling
_sigint( ) { _debug "SIGINT caught!"; exit 127; }
_sigerr( ) { _debug "SIGERR caught!"; }
_sigexit( ) {
    (( _in_getopt == 1 )) && { _is_function _usage && _usage; exit 0; }
    (( $1 == 0 || $1 == 255 )) && exit $1
    _error "terminated with error $1"
    _debug "exit_status=$1"
    _debug "call stack:"
    for (( i=0; i < ${#FUNCNAME[@]} -1; i++ )); do
        _debug "    [$i]=${BASH_SOURCE[$i+1]}:${BASH_LINENO[$i]} ${FUNCNAME[$i]}(...)"
    done
}
trap '_sigexit $? 1>&2' EXIT
trap '_sigint $?' INT
trap '_sigerr $?' ERR

# logging
_debug( ) { local args="$@"; [[ -v DEBUG ]] && { printf "[%(%T)T] %b %s: %s\n" -1 "\e[94mD\e[0m" "$__this__" "$args" >&2; }; true; }
_info( )  { local args="$@"; [[ -v QUIET ]] || { printf "[%(%T)T] %b %s: %s\n" -1 "\e[32mI\e[0m" "$__this__" "$args" >&2; }; true; }
_warn ( ) { local args="$@"; printf "[%(%T)T] %b %s: %s\n" -1 "\e[33mW\e[0m" "$__this__" "$args" >&2; }
_error( ) { local args="$@"; printf "[%(%T)T] %b %s: %s\n" -1 "\007\e[91mE\e[0m" "$__this__" "$args" >&2; }
_fatal( ) { local args="$@"; printf "[%(%T)T] %b %s: %s\n" -1 "\007\007\007\e[37;41mF\e[0m" "$__this__" "$args" >&2; }

# predicates
_is_declared( ) { { [[ -n ${!1+__anything__} ]] || declare -p $1 &>/dev/null; } }
_is_unset( ) { { [[ -z ${!1+__anything__} ]] && ! declare -p $1 &>/dev/null; } }
_is_function( ) { [[ "$(declare -Ff "$1")" ]]; }

declare -i _in_getopt=0
declare __args__=( "$@" )

# startup
__run__( ) {
    _is_declared __options__ && {
        _in_getopt=1
        __args__=( $( getopt -an $__this__ $__options__ -- "${__args__[@]}" 2>/dev/null ) )
        _in_getopt=0
        eval set -- "${__args__[@]}"
        while :; do
            local cbk= arg=
            case "$1" in
                --) break ;; 
                -*) [[ $1 =~ ^[-]+(.+)$ ]]; cbk=_on_opt_${BASH_REMATCH[1]}; arg=; shift;
                    case "$1" in --) ;; -*) ;; *) arg="$1"; shift ;; esac 
                    ;;
                *) _fatal "something wrong in getopt" ;;
            esac
            _is_function $cbk && $cbk "$arg"
        done
        shift; __args__=( "${@}" )
    }
    ! _is_function __main__&& _fatal "cannot find '__main__'"
    __main__ "${__args__[@]}" 
}
