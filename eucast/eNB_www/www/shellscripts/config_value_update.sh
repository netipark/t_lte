#!/bin/bash

function update_cfg_normal()
{
	key_name=$1
	tmp_key_val=$2
	target_file=$3

	#change all '/' to '\/' before sed
	key_val=`echo $2 | sed -e 's,/,\\\/,g'`

	sed -i -e "s/^${key_name}=.*/${key_name}\=${key_val}/g" ${target_file}
}

function update_cfg_nth_occurence()
{
	key_name=$1
	tmp_key_val=$2
	target_file=$3
	nth=$4

	# change all '/' to '\/' before sed
	key_val=`echo $2 | sed -e 's,/,\\\/,g'`

	l_key="<${key_name}>"
	r_key="<\/${key_name}>"
	xml_line="${l_key}${key_val}${r_key}"
	line_num=`awk "/${key_name}/{n++; if (n==${nth}) {print NR;exit}}" ${target_file}`
	#echo "line num is ${line_num}"
	sed -i -e "${line_num} s/${l_key}.*/${xml_line}/g" ${target_file}
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

if [ "$2" == "PhyCellID" ] ||
	[ "$2" == "TAC" ] ||
	[ "$2" == "PLMNID" ] ||
	[ "$2" == "MODE" ]
then
	update_cfg_nth_occurence $1 $2 $3 1
else
	update_cfg_normal $1 $2 $3
fi
