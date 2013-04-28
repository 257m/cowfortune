#!/bin/bash
COWSAY=cowsay
COWTHINK=cowthink
FORTUNE=fortune
LOLCAT=lolcat
COWPATH=/usr/share/cowsay/cows
CFGPATH=/etc/cowfortune

# read blacklist from home or etc
BLACKLIST=""
if [ -s $HOME/.cowfortune/blacklist ]; then
	BLACKLIST=$(cat $HOME/.cowfortune/blacklist)
elif [ -s $CFGPATH/blacklist ]; then
	BLACKLIST=$(cat ${CFGPATH}/blacklist)
fi

# read whitelist from home or etc
WHITELIST=""
if [ -s $HOME/.cowfortune/whitelist ]; then
	WHITELIST=$(cat $HOME/.cowfortune/whitelist)
elif [ -s $CFGPATH/whitelist ]; then
	WHITELIST=$(cat ${CFGPATH}/whitelist)
fi

# get all existing cows
COWS=$(ls --format="single-column" ${COWPATH}|sed 's/\.cow//g')

# maybe filter from whitelist so we only have existing cows
if [ -n "$WHITELIST" ]; then
	WHITELIST=$(echo $WHITELIST|tr ' ' '|')
	COWS=$(echo "$COWS"|grep -E $WHITELIST)
fi

# filter the blacklist from the remaining cows
if [ -n "$BLACKLIST" ]; then
	BLACKLIST=$(echo $BLACKLIST|tr ' ' '|')
	COWS=$(echo "$COWS"|grep -v -E $BLACKLIST)
fi
COWS=${COWS}|tr "\n" " "

# fortune config file
CONFIG=""
if [ -s $HOME/.cowfortune/config ]; then
	CONFIG=$(cat $HOME/.cowfortune/config)
elif [ -s $CFGPATH/config ]; then
	CONFIG=$(cat ${CFGPATH}/config)
fi

# fortune options
FORTUNE_OPTS=""
COWSAY_OPTS=""
get_var() {
	VALUE=$(eval echo \${$1})
	[ -n "$VALUE" ] || VALUE=$2
	echo $VALUE
}
set_var() {
	eval $1=\""$2"\"
}

# parse config file
for i in $(echo "$CONFIG" | grep -v -e '[#;]'); do
	set_var $(echo $i | tr '=' ' ')
done

# LENGTH_SHORT [INTEGER]
LENGTH_SHORT=$(get_var LENGTH_SHORT 180)
FORTUNE_OPTS+=" -n $LENGTH_SHORT"

# COLUMN_WIDTH [INTEGER]
COLUMN_WIDTH=$(get_var COLUMN_WIDTH 50)
COWSAY_OPTS+=" -W $COLUMN_WIDTH"

# LENGTH_USE [short,long,all]
LENGTH=$(get_var LENGTH_USE "short")
if [ "long" == $LENGTH_USE ]; then
	FORTUNE_OPTS+=" -l"
elif [ "short" == $LENGTH_USE ]; then
	FORTUNE_OPTS+=" -s"
fi

# DEBUG_FILES [0,1]
DEBUG_FILES=$(get_var DEBUG_FILES 0)
if [ 0 -ne $DEBUG_FILES ]; then
	FORTUNE_OPTS+=" -f"
fi

# DEBUG_SOURCE [0,1]
DEBUG_SOURCE=$(get_var DEBUG_SOURCE 0)
if [ 0 -ne $DEBUG_SOURCE ]; then
	FORTUNE_OPTS+=" -c"
fi

# DEBUG_COW [0,1]
DEBUG_COW=$(get_var DEBUG_COW 0)

# OFFENSIVE_ONLY [0,1]
OFFENSIVE_ONLY=$(get_var OFFENSIVE_ONLY 0)
if [ 0 -ne $OFFENSIVE_ONLY ]; then
	FORTUNE_OPTS+=" -o"
fi

# LOLCAT_IGNORE [0,1]
LOLCAT_IGNORE=$(get_var LOLCAT_IGNORE 0)
if [[ 0 -ne $LOLCAT_IGNORE || -z "$(which $LOLCAT)" ]]; then
	LOLCAT=
fi

# FORTUNES [FILE...]
FORTUNE_OPTS+=" $(echo "$CONFIG" | grep -v -e '[#;]' | grep FORTUNES | cut -d'=' -f2 | tr '\n' ' ')"

# DEBUG_OPTIONS [0,1]
DEBUG_OPTIONS=$(get_var DEBUG_OPTIONS 0)
if [ 0 -ne $DEBUG_OPTIONS ]; then
	echo "[DEBUG] fortune options:$FORTUNE_OPTS"
	echo "[DEBUG] cowsay options:$COWSAY_OPTS"
fi

# random cow
set -- "$COWS"
if [ 0 -ne $DEBUG_COW ]; then
	echo "[DEBUG] available cows: $(echo $COWS)"
fi
declare -a COWS=($*)
RANGE=${#COWS[@]}
NUMBER=$RANDOM
let "NUMBER %= $RANGE"
COW=${COWS[$NUMBER]}
if [ 0 -ne $DEBUG_COW ]; then
	echo "[DEBUG] used cow: $COW"
fi

# choose say|think
RANGE=2
NUMBER=$RANDOM
let "NUMBER %= $RANGE"
case $NUMBER in
0)
    COWCMD=$COWSAY
    ;;
1)
    COWCMD=$COWTHINK
    ;;
esac

# execute
if [ -z "$LOLCAT" ]; then
	$FORTUNE $FORTUNE_OPTS | $COWCMD $COWSAY_OPTS -f $COW
	exit
fi
$FORTUNE $FORTUNE_OPTS | $COWCMD $COWSAY_OPTS -f $COW | $LOLCAT
