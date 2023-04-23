#!/usr/bin/env bash

REVERSE="\x1b[7m"
RESET="\x1b[m"

if [ -z "$1" ]; then
	echo "usage: $0 [--tag] FILENAME[:LINENO][:IGNORED]"
	exit 1
fi

if [ "$1" = --tag ]; then
	shift
	"$(dirname "${BASH_SOURCE[0]}")/tagpreview.sh" "$@"
	exit $?
fi

IFS=':' read -r FILE CENTER <<<"$1"

FILE="${FILE/#\~\//$HOME/}"
if [ ! -r "$FILE" ]; then
	echo "File not found ${FILE}"
	exit 1
fi

if [ -z "$CENTER" ]; then
	CENTER=0
fi

# Sometimes bat is installed as batcat.
if command -v batcat >/dev/null; then
	BATNAME="batcat"
elif command -v bat >/dev/null; then
	BATNAME="bat"
fi

MIME=$(file --brief --mime-type -- "$FILE")

if [ -d "$FILE" ]; then
	tree -C "$FILE" -L 3 | head -n 50
elif [[ "$MIME" == "application/"* || "$MIME" == "video/"* || "$MIME" == "audio/"* || "$MIME" == "image/"* || "$MIME" == "font/"* ]]; then
	echo "File information for non-text type:"
	file -b "$FILE"
else
	if [ "${BATNAME:+x}" ]; then
		${BATNAME} --style="${BAT_STYLE:-numbers}" --color=always --pager=never \
			--highlight-line=$CENTER -- "$FILE"
		exit $?
	else
		DEFAULT_COMMAND="highlight -O ansi -l {} || coderay {} || rougify {} || cat {}"
		CMD=${FZF_PREVIEW_COMMAND:-$DEFAULT_COMMAND}
		CMD=${CMD//{\}/$(printf %q "$FILE")}

		eval "$CMD" 2>/dev/null | awk "{ \
        if (NR == $CENTER) \
            { gsub(/\x1b[[0-9;]*m/, \"&$REVERSE\"); printf(\"$REVERSE%s\n$RESET\", \$0); } \
        else printf(\"$RESET%s\n\", \$0); \
        }"
	fi
fi
