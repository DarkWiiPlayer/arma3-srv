#!/bin/sh

if [ -z "$1" ]
then
	dir="."
else
	dir="$1"
fi

find $dir -depth -not -name '*.bisign' -exec rename 's/(.*)\/([^\/]*)/$1\/\L$2/' {} \;
