#! /bin/sh

set i $1
set site $2
set method $3

mkdir -p /home/wbrooks2/beauty_contest/output/$site
mkdir -p /home/wbrooks2/beauty_contest/output/$site/$method

cp /home/wbrooks2/beauty_contest/chtc/beautyoutput-$site-$method/$i/beautyrun* /home/wbrooks2/beauty_contest/output/$site/$method

