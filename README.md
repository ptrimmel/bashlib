# BASHLIB

`bashlib.sh` provides a small framework of useful shell functions (e.g. paramter parsing, trap handling, tests, etc.). 

### Getting started:
Include `bashlib.sh` on top of your script. The example below expects `bashlib.sh` in the same directory as the script.
```sh
#!/usr/bin/env bash
#
BASHLIB="$( dirname $( readlink -f "$0" ) )/bashlib.sh"
source $BASHLIB || exit 1
```
>NOTE: the `BASHLIB` variable must be set as it is checkd in `bashlib.sh`.

### First steps:

Declare the necessary functions in your script in order to use the provided framework. The following example shows the bare minimum you have to do.

```sh
#!/usr/bin/env bash
#
BASHLIB="$( dirname $( readlink -f "$0" ) )/bashlib.sh"
source $BASHLIB || exit 1

# entry point called from `bashlib.sh`
__main__( ) {

    echo "'${__this__}' lives '${__here__}'."
    return 0
}

# startup
__run__ 
```
> `bashlib` defines the variables _\_\_this\_\__, i.e. the name of the script, and _\_\_here\_\__ i.e. the path to the script.

### Option parsing:

You may define `getopt` style options for the script and if you declare a function to receive such options through the framework you can implement option parsing very easily.

```sh
#!/usr/bin/env bash
#
BASHLIB="$( dirname $( readlink -f "$0" ) )/bashlib.sh"
source $BASHLIB || exit 1

# getopt(1) short and long options
declare -rA __options__=(
    [short]="hVg:" [long]="help,version,greet:"
)

# options callback
_on_options( ) {
    local opt="$1" arg="$2"
    case $opt in
        h|help) echo "no help."; exit 0 ;;
        V|version) echo "Version 0"; exit 0 ;;
        g|greet) echo "greetings, $arg!" ;;
    esac
}

# entry point called from `bashlib.sh`
__main__( ) {

    echo "'${__this__}' lives '${__here__}'."
    return 0
}

# startup
__run__ 
```

You may also declare a _\_usage_ function that gets called whenever option parsing through getopt fails.
```sh
_usage( ) {
cat <<EOF

Usage: $__this__ [OPTION...]
Test for bashlib.

  -h, --help                 Give this help list
  -V, --version              Print program version
  -g, --greet=person         Send greets to someone

Mandatory or optional arguments to long options are also mandatory or optional
for any corresponding short options.
EOF
}
```

### Further readings:

I have provided a more detailed `sample.sh` script that implements a real world use case with more complex options and parameter parsing. Try it.

In order to understand it all I strongly recommend to read `bashlib.sh` - don't just use it. 