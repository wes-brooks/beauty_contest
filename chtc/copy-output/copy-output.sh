#! /bin/sh

set i [lindex $argv 0]
set site [lindex $argv 1]
set method [lindex $argv 2]

mkdir -p /home/wbrooks2/beauty_contest/output/$site
mkdir -p /home/wbrooks2/beauty_contest/output/$site/$method

cp /home/wbrooks2/beauty_contest/chtc/beautyoutput-$site-$method/$i/beautyrun* /home/wbrooks2/beauty_contest/output/$site/$method

