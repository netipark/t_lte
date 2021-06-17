#!/bin/bash
# File System Name to Mount
FS_SPICO=/spico                                                                                                                     

ENB_CONFIG_DIR=${FS_SPICO}/config                                                                                                 
ENB_RUNNING_CFG_DIR=${FS_SPICO}/running/cfg                                                                                     
ENB_RUNNING_L3_DIR=${FS_SPICO}/running/L3                                                                                       
                                                                                                                                    
# NAND_RECOVERY, ENB_RECOVERY                                                                                                     
ENB_MGMT_DIR=/spico_mgmt
ENB_CONFIG_UPDATE=spico_config_update.sh

#ENB_CONFIG_FILE=enb_conf.cfg
ENB_CONFIG_FILE=$1
TARGET_FILE_1=eNodeB_systemsetup.cfg
TARGET_FILE_2=eNodeB_Data_Model_TR_196_based.xml

CONFIG_FILE_PATH=${ENB_RUNNING_CFG_DIR}/${TARGET_TEST_FILE}
TARGET_FILE_1_PATH=${ENB_CONFIG_DIR}/${TARGET_FILE_1}
TARGET_FILE_2_PATH=${ENB_RUNNING_CFG_DIR}/${TARGET_FILE_2}

LOG_FILE="/var/log/spico_config_update.log"

function log()
{
	time=`date`
	echo "[${time}] $*" >> ${LOG_FILE}
}

function check_failure()          
{
	time=`date`                
	if [ "$1" != "0" ]; then
		echo "[${time}] Error $1"
		exit $1                        
	fi
} 

function package_usage()                                                                                                    
{                                                                                                                           
	echo ""
	echo "Usage of command: "                                                                                        
	echo "      > enb_conf_update.sh [config_file]"
	echo "      > ex) ./enb_conf_update.sh enb_conf.cfg"
	echo "" 
}

function check_enb_config_file()
{
	if [ ! -f "${ENB_CONFIG_FILE}" ]; then
		log "${ENB_CONFIG_FILE} not exist"
		check_failure 1
	fi

	# Remove CR in config File
	tr -d '\r' < ${ENB_CONFIG_FILE} >  ${ENB_CONFIG_DIR}/config_tmp
	mv -f ${ENB_CONFIG_DIR}/config_tmp ${ENB_CONFIG_FILE}

	if [ ! -f "${ENB_CONFIG_FILE}" ]; then
		log "${ENB_CONFIG_FILE} not exist"
		check_failure 1
	fi 
}


function get_enb_config_value()
{
	enb_config_val=""
	if [ "$1" == "" ]; then
		return
	fi

	while read lines
	do
		if [ "${lines}" == "" ]; then
			continue
		fi
		if [[ "${lines}" == "#"* ]]; then
			continue
		fi
		if [[ "${lines}" == *"$1"* ]]; then
			temp=`echo $lines | cut -d \= -f 1`
			if [[ "${temp}" == "$1" ]]; then
				line=`echo $lines |sed -e "s/[ \t]//g" | grep -v "\#"`
				break
			fi
		fi
	done < ${ENB_CONFIG_FILE}

	lhs=`echo $line | cut -d \= -f 1`
	rhs=`echo $line | cut -d \= -f 2`

	enb_config_value="$rhs"
}

function read_enb_file()
{
	get_enb_config_value "IPInterfaceIPAddress"
	enb_ip_addr="${enb_config_value}"
	log ">>> eNodeB IP Address         [${enb_ip_addr}]"

	get_enb_config_value "X_VENDOR_DEFAULT_GATEWAY"
	enb_gw_addr="${enb_config_value}"
	log ">>> eNodeB GW Address         [${enb_gw_addr}]"

	get_enb_config_value "PhyCellID"
	phycellid="${enb_config_value}"
	log ">>> PCI               [$phycellid]"

	get_enb_config_value "CellIdentity"
	cell_id="${enb_config_value}"
	log ">>> CELL_ID           [$cell_id]"

	get_enb_config_value "FreqBandIndicator"
	FreqBandIndicator="${enb_config_value}"
	log ">>> FreqbandInd       [$FreqBandIndicator]"

	get_enb_config_value "EARFCNDL"
	earfcndl="${enb_config_value}"
	log ">>> EARFCNDL          [$earfcndl]"

	get_enb_config_value "EARFCNUL"
	earfcnul="${enb_config_value}"
	log ">>> EARFCNUL          [$earfcnul]"

	get_enb_config_value "X_VENDOR_CELL1_ENABLE"
	cell1enable="${enb_config_value}"
	log ">>> CELL1_ENABLE      [$cell1enable]"

	get_enb_config_value "X_VENDOR_ANTENNA_PORT1_TX_ATTEN"
	tx1atten="${enb_config_value}"
	log ">>> TX1_ATTEN         [$tx1atten]"

	get_enb_config_value "X_VENDOR_ANTENNA_PORT2_TX_ATTEN"
	tx2atten="${enb_config_value}"
	log ">>> TX1_ATTEN         [$tx2atten]"

	get_enb_config_value "TAC"
	tac="${enb_config_value}"
	log ">>> TAC              [$tac]"

	get_enb_config_value "PLMNID"
	plmnid="${enb_config_value}"
	log ">>> PLMNID             [$plmnid]"

	get_enb_config_value "S1SigLinkServerList"
	s1sig="${enb_config_value}"
	log ">>> S1SigLinkServerList   [$s1sig]"

	get_enb_config_value "MODE"
	syncmode="${enb_config_value}"
	log ">>> Sync Mode   [$syncmode]"
}

function update_cfg_xml()
{
	key_name=$1
	tmp_key_val=$2
	target_file=$3

	#change all '/' to '\/' before sed 
	key_val=`echo $2 | sed -e 's,/,\\\/,g'`

	l_key="<${key_name}>"
	r_key="<\/${key_name}>"
	xml_line="${l_key}${key_val}${r_key}"

	log ">>> Input line ==> ${xml_line}"

	sed -i -e "s/${l_key}.*/${xml_line}/g" ${target_file}
} 

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

function update_cfg_nth_occurence_xml()
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

function update_cfg_normal()
{
	key_name=$1
	tmp_key_val=$2
	target_file=$3

	#change all '/' to '\/' before sed
	key_val=`echo $2 | sed -e 's,/,\\\/,g'`

	sed -i -e "s/^${key_name}=.*/${key_name}\=${key_val}/g" ${target_file}
}

if [ $# -lt 1 ]
then
	package_usage
	exit 1
fi 

log "======================================="
log "1. Check CFG file"
check_enb_config_file

log "2. Read CFG file"
read_enb_file

log "3. Update [${TARGET_FILE_1_PATH}]"
update_cfg_normal "IPInterfaceIPAddress" ${enb_ip_addr} ${TARGET_FILE_1_PATH}
update_cfg_normal "X_VENDOR_DEFAULT_GATEWAY" ${enb_gw_addr} ${TARGET_FILE_1_PATH}

if [ -f ${ENB_MGMT_DIR}/${ENB_CONFIG_UPDATE} ]; then
	${ENB_MGMT_DIR}/${ENB_CONFIG_UPDATE}
fi

log "4. Update XML Configuration"
update_cfg_nth_occurence_xml "PhyCellID"  ${phycellid} ${TARGET_FILE_2_PATH} 1
update_cfg_xml "CellIdentity"   ${cell_id} ${TARGET_FILE_2_PATH}
update_cfg_xml "FreqBandIndicator"   ${FreqBandIndicator} ${TARGET_FILE_2_PATH}
update_cfg_xml "EARFCNDL"   ${earfcndl} ${TARGET_FILE_2_PATH}
update_cfg_xml "EARFCNUL"   ${earfcnul} ${TARGET_FILE_2_PATH}
update_cfg_xml "X_VENDOR_CELL1_ENABLE"   ${cell1enable} ${TARGET_FILE_2_PATH}
update_cfg_xml "X_VENDOR_ANTENNA_PORT1_TX_ATTEN"   ${tx1atten} ${TARGET_FILE_2_PATH}
update_cfg_xml "X_VENDOR_ANTENNA_PORT2_TX_ATTEN"   ${tx2atten} ${TARGET_FILE_2_PATH}
update_cfg_nth_occurence_xml "TAC"  ${tac} ${TARGET_FILE_2_PATH} 1
update_cfg_nth_occurence_xml "PLMNID"  ${plmnid} ${TARGET_FILE_2_PATH} 2
update_cfg_xml "S1SigLinkServerList"   ${s1sig} ${TARGET_FILE_2_PATH}
update_cfg_nth_occurence_xml "MODE"  ${syncmode} ${TARGET_FILE_2_PATH} 1
sync;sync

#cat ${TARGET_FILE_2_PATH}
log "======================================="
