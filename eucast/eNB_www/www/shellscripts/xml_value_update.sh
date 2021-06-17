#!/bin/bash

function update_cfg_first_occurence_xml()
{
	key_name=$1
	tmp_key_val=$2
	target_file=$3
																																
	#change all '/' to '\/' before sed
	key_val=`echo $2 | sed -e 's,/,\\\/,g'`

	l_key="<${key_name}>"
	r_key="<\/${key_name}>"
	xml_line="${l_key}${key_val}${r_key}"
	sed -i -e  "1,/${l_key}.*/s/${l_key}.*/${xml_line}/" ${target_file}
}  

if [ "$1" == "" ]; then
	exit
fi
if [ "$2" == "" ]; then
	exit
fi
if [ "$3" == "" ]; then
	exit
fi
update_cfg_first_occurence_xml $1 $2 $3
