#!/bin/bash

OPT=$1

function config_collect_cmd_cli()
{
	local tmpfile="${PWD}/cmd.list"

	cat << EOF > ${tmpfile}
Set OAM_USER_INTF_RESP_TIMEOUT 5
Show Config InternetGatewayDevice Services FAPService CellConfig LTE RAN RF FreqBandIndicator
Show Config InternetGatewayDevice Services FAPService CellConfig LTE RAN RF DLBandwidth
Show Config InternetGatewayDevice Services FAPService CellConfig LTE RAN RF ULBandwidth
Show Config InternetGatewayDevice Services FAPService CellConfig LTE RAN RF EARFCNDL
Show Config InternetGatewayDevice Services FAPService CellConfig LTE RAN RF EARFCNUL
Show Config InternetGatewayDevice Services FAPService CellConfig LTE RAN RF PhyCellID
Show Config InternetGatewayDevice Services FAPService CellConfig LTE RAN Common CellIdentity
EOF

	cd /spico/running/L3
	#show_header "lte_oamCli"
	./lte_oamCli -f ${tmpfile}
	cd - >/dev/null

	rm -f ${tmpfile}
}

function alarm_collect_cmd_cli()
{
	local tmpfile="${PWD}/cmd.list"

	cat << EOF > ${tmpfile}
Set OAM_USER_INTF_RESP_TIMEOUT 5
Show Alarm CurrentAlarm
EOF

	cd /spico/running/L3
	#show_header "lte_oamCli"
	./lte_oamCli -f ${tmpfile}
	cd - >/dev/null

	rm -f ${tmpfile}
}

function cell_onoff_collect_cmd_cli()
{
	local tmpfile="${PWD}/cmd.list"

	cat << EOF > ${tmpfile}
Set OAM_USER_INTF_RESP_TIMEOUT 5
Show Config InternetGatewayDevice Services FAPService FAPControl LTE eNBState X_VENDOR_CELL1_ENABLE
EOF

	cd /spico/running/L3
	#show_header "lte_oamCli"
	./lte_oamCli -f ${tmpfile}
	cd - >/dev/null

	rm -f ${tmpfile}
}

function cell_onoff_cmd_cli()
{
	local tmpfile="${PWD}/cmd.list"

	if [ -z $1 ]; then
		return
	fi

    if [ $1 == "on" ]
    then
	    cat << EOF > ${tmpfile}
Set OAM_USER_INTF_RESP_TIMEOUT 60
Config InternetGatewayDevice Services FAPService FAPControl LTE eNBState X_VENDOR_CELL1_ENABLE 1
EOF
	else
	    cat << EOF > ${tmpfile}
Set OAM_USER_INTF_RESP_TIMEOUT 10
Config InternetGatewayDevice Services FAPService FAPControl LTE eNBState X_VENDOR_CELL1_ENABLE 0
EOF
    fi

	cd /spico/running/L3
	#show_header "lte_oamCli"
	./lte_oamCli -f ${tmpfile}
	cd - >/dev/null

	rm -f ${tmpfile}
}

case $OPT in
	all )
		config_collect_cmd_cli
		alarm_collect_cmd_cli
		;;
	config )
		config_collect_cmd_cli
		;;
	alarm )
		alarm_collect_cmd_cli
		;;
	cell )
		cell_onoff_collect_cmd_cli
		;;
	onoff )
		cell_onoff_cmd_cli $2
		;;
	* )
		;;
esac
