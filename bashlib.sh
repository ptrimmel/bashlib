#!/usr/bin/env bash
#

[[ $TRACE ]] && set -o xtrace

set -o errexit
set -o nounset
set -o pipefail
set -o errtrace

[[ -v BASHLIB ]] || exit 255

declare -r __here__="$( dirname $( readlink -f "$0" ) )"
declare -r __this__="${0##*/}"

# signal handling
_sigint( ) { _debug "SIGINT ($1) caught!"; exit 127; }
_sigerr( ) { _debug "SIGERR ($1) caught!"; }
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

[[ -v NOTRAP ]] || {
    trap '_sigexit $? 1>&2' EXIT
    trap '_sigint $?' INT
    trap '_sigerr $?' ERR
}

# DEBUG implies VERBOSE
[[ -v DEBUG ]] && VERBOSE=1

# logging
_log( ) { local args="$@"; [[ -v QUIET ]] || { printf "%s: %b\n" "$__this__" "$args"; }; true; }
_err( ) { local args="$@"; printf "%s: %b\n" "$__this__" "$args" >&2; exit 1; }

# verbose logging
_debug( )  { local args="$@"; [[ -v DEBUG ]] && { printf "[%(%T)T] %b %s: %s\n" -1 "\e[94mD\e[0m" "$__this__" "$args" >&2; }; true; }
_inform( ) { local args="$@"; [[ -v VERBOSE ]] && { printf "[%(%T)T] %b %s: %s\n" -1 "\e[32mI\e[0m" "$__this__" "$args" >&2; }; true; }
_warn( )   { local args="$@"; [[ -v VERBOSE ]] && { printf "[%(%T)T] %b %s: %s\n" -1 "\e[33mW\e[0m" "$__this__" "$args" >&2; }; true;  }
_error( )  { local args="$@"; [[ -v VERBOSE ]] && { printf "[%(%T)T] %b %s: %s\n" -1 "\007\e[91mE\e[0m" "$__this__" "$args" >&2; }; true;  }
_fatal( )  { local args="$@"; [[ -v VERBOSE ]] && { printf "[%(%T)T] %b %s: %s\n" -1 "\007\007\007\e[37;41mF\e[0m" "$__this__" "$args" >&2; exit 255; } }

# variable predicates
_is_declared( ) { [[ -n ${!1+__anything__} ]] || declare -p $1 &>/dev/null; } 
_is_unset( ) { [[ -z ${!1+__anything__} ]] && ! declare -p $1 &>/dev/null; }
_is_set( ) { ! _is_unset $1; }
_is_empty( ) { [[ -z ${!1} ]]; }
_is_not_empty( ) { ! _is_empty $1; }
_is_function( ) { [[ "$(declare -Ff "$1")" ]]; }

# string functions
_trim( ) { # str
    local s=$1 LC_CTYPE=C
    s=${s#"${s%%[![:space:]]*}"}
    s=${s%"${s##*[![:space:]]}"}
    printf '%s' "$s"
}

_split( ) { # str del fld
    local s=$1 d=$2 f=$3 LC_CTYPE=C
    mapfile -td $d $f < <(printf "%s\0" "$s")
}

_map( ) { # fld [var...]
    local f=$1[@]; shift
    local v=( ${!f} ) n=( $@ )
    for (( i=0; i < ${#n}; i++ )); do
        eval ${n[i]}="${v[i]}" # yes, bad. I know...
    done    
}

# array functions
_in_array( ) {
    local ref=$1[@] var=$2
    [[ " ${!ref} " =~ [[:space:]]$var[[:space:]] ]]
}

declare -i _in_getopt=0
declare __args__=( "$@" )

# startup
__run__( ) {
    _is_declared __options__ && {
        _is_unset __options__[short] || local opt+=" -o ${__options__[short]}" 
        _is_unset __options__[long] || local opt+=" --long ${__options__[long]}"
        _is_unset opt || {
            _in_getopt=1
            __args__=( $( getopt -n $__this__ $opt -- "${__args__[@]}" 2>/dev/null ) )
            _in_getopt=0
            eval set -- "${__args__[@]}"
            while (( $# )) do
                opt="$1" arg=
                case "$opt" in
                    --) shift; break ;; 
                    --[a-zA-Z0-9]*) 
                        [[ $opt =~ ^[-]+(.+)$ ]]; opt=${BASH_REMATCH[1]}
                        [[ ${__options__[long]} =~ $opt: ]] && { arg="$2"; shift; }
                        ;;
                    -[a-zA-Z0-9]*) 
                        [[ $opt =~ ^[-]+(.+)$ ]]; opt=${BASH_REMATCH[1]}
                        [[ ${__options__[short]} =~ $opt: ]] && { arg="$2"; shift; }
                        ;;
                    *) _fatal "something wrong in getopt" ;;
                esac
                shift
                _is_function _on_options && _on_options "$opt" "$arg"
            done
            __args__=( "${@}" )
        }
    }
    ! _is_function __main__&& _fatal "cannot find '__main__'"
    __main__ "${__args__[@]}" 
}
