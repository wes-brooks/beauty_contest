#! /bin/sh

i=$1
site=$2
method=$3

mkdir -p /home/wbrooks2/beauty_contest/output/$site
mkdir -p /home/wbrooks2/beauty_contest/output/$site/$method

cp /home/wbrooks2/beauty_contest/chtc/beautyoutput-$site-$method/$i/beautyrun* /home/wbrooks2/beauty_contest/output/$site/$method

