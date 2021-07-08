#/bin/sh

RADIO=radio
INIT=init
ON=on
OFF=off
RESET=reset
STATUS=status
SETATTEN=setatten
SETCFRGAIN=setcfrgain
SETPOSTCFRGAIN=setpostcfrgain
CHECK=check
RELOCK=relock
ZERO=0
RETRYCOUNT=3

function check_failure()
{
	retVal=$1
	if [ $retVal -ne 0 ]
	then
		echo "Command FAILED!!!"
		exit $retVal
	fi
}

function set_time_adveance()
{
	# TDD: -138(0xFF76) / 19351(0x4B97, w/ WIMAX), FDD: -178(0xFF53)
	if [ $# -eq 2 ]
	then
		let ADVANCEH=$1
		let ADVANCEL=$2
		let ADVANCE=${ADVANCEH}*256+${ADVANCEL}
	elif [ $# -eq 1 ]
	then
		let ADVANCE=$1
		if [ ${ADVANCE} -lt "0" ]; then
			let ADVANCEH=(4294967296 + ${ADVANCE})/256
			let ADVANCEL=(4294967296 + ${ADVANCE})%256
		else
			let ADVANCEH=${ADVANCE}/256
			let ADVANCEL=${ADVANCE}%256
		fi
	else
		echo "Invalide params"
	fi
	echo "Time Advance = ${ADVANCE} (${ADVANCEH}, ${ADVANCEL})"

	if [ -f /usr/sbin/set_tdd_advance ]
	then
		echo "Time Advance = ${ADVANCE}"
		/usr/sbin/set_tdd_advance ${ADVANCE}
	elif [ -f /usr/sbin/set_fpga_reg ]
	then
		echo "Time Advance = ${ADVANCEH}, ${ADVANCEL})"
		/usr/sbin/set_fpga_reg 29 ${ADVANCEH}
		/usr/sbin/set_fpga_reg 28 ${ADVANCEL}
	fi
}

if [ $# -lt 1 ]
then
	echo "ERROR: No Arguments has been passed!!!"
	exit 1
fi

if [ $1 == $RADIO ]
then
	#echo "RADIO has been triggered"
	#cell_stop - cell_start Fix Start
    #radio_init(U8  bandwidth, U8  ant_port_count, U32  samplingrate, U8  tdd_subframe, U8  tdd_specialsubframe,
    #U8  use_zero_if,  U8  DuplexMode[RADIO_OAM_MAX_DUP_LEN], U8 hwType)
	#cell_stop - cell_start Fix End
    if [ $2 == $INIT ]
    then
        echo "RADIO INIT has been triggered"
		echo "Number of parameters are $#"
		#cell_stop - cell_start Fix Start
		if [ $# -eq 11 -o $# -eq 12 ]
		then
			echo "RADIO INIT has 9 parameters"
			#cell_stop - cell_start Fix End
			#Fetch all arguments
			FREQ_BAND=$3
			ANTENNA_PORT=$4
			SAMPLING_RATE=$5
			#cell_stop - cell_start Fix Start
			TDD_SUBFRAME=$6
			TDD_SPESUBFRAME=$7
			USE_ZERO_IF=$8
			DUPLEXMODE=$9
			EXPLICIT_RADIO=${10}
			CONFIG_FILE=${11}
		#cell_stop - cell_start Fix End
			CONFIG_ADVANCE=0
			if [ $# -eq 12 ]; then
				CONFIG_ADVANCE=${12}
			fi

			#RADIO TDD CONFIG for TDD Duplex Mode ONLY
			if [ ${CONFIG_ADVANCE} -eq 0 ]
			then
				if [ $DUPLEXMODE == 0 ];
				then
					MODE=FDD
					set_time_adveance 255 83
				elif [ $DUPLEXMODE == 1 ];
				then
					MODE=TDD
					#set_time_adveance 75 151
					set_time_adveance 255 118
				else
					MODE=INVALID
				fi
			else
				set_time_adveance ${CONFIG_ADVANCE}
			fi

			echo "FREQ_BAND: $FREQ_BAND"
			echo "ANTENNA_PORT: $ANTENNA_PORT"
			echo "SAMPLING_RATE: $SAMPLING_RATE"
			#cell_stop - cell_start Fix Start
			echo "TDD_SUBFRAME: $TDD_SUBFRAME"
			echo "TDD_SPESUBFRAME: $TDD_SPESUBFRAME"
			#cell_stop - cell_start Fix End
			echo "USE_ZERO_IF: $USE_ZERO_IF"
			echo "DUPLEXMODE: $MODE"
			echo "EXPLICIT_RADIO: $EXPLICIT_RADIO"
			echo "CONFIG_FILE: $CONFIG_FILE"

			if [ $EXPLICIT_RADIO -ne 0 ];
			then
				CONFIGURATION=$CONFIG_FILE
			echo "$CONFIGURATION"
			else
			if [ $SAMPLING_RATE -ne 0 ]
			then
				#Validate for ZIF or LIF
				if [ $USE_ZERO_IF == 0 ]
				then
					echo "ZIF is required in RADIO Config"
					ZIF=ZIF
					CONFIGURATION="2x2_${ANTENNA_PORT}xLTE${FREQ_BAND}_${MODE}_${SAMPLING_RATE}_${ZIF}"
					echo "$CONFIGURATION"
				elif [ $USE_ZERO_IF == 1 ]
				then
					echo "LIF is required in RADIO Config"
					ZIF=LIF
					CONFIGURATION="2x2_${ANTENNA_PORT}xLTE${FREQ_BAND}_${MODE}_${SAMPLING_RATE}_${ZIF}"
					echo "$CONFIGURATION"
				elif [ $USE_ZERO_IF == 2 ]
				then
					echo "ZIF is NOT required in RADIO Config"
					CONFIGURATION="2x2_${ANTENNA_PORT}xLTE${FREQ_BAND}_${MODE}_${SAMPLING_RATE}"
					echo "$CONFIGURATION"
				fi
			else
				#Validate for ZIF or LIF
				if [ $USE_ZERO_IF == 0 ]
				then
					echo "ZIF is required in RADIO Config"
					ZIF=ZIF
					CONFIGURATION="2x2_${ANTENNA_PORT}xLTE${FREQ_BAND}_${MODE}_${ZIF}"
					echo "$CONFIGURATION"
				elif [ $USE_ZERO_IF == 1 ]
				then
					echo "LIF is required in RADIO Config"
					ZIF=LIF
					CONFIGURATION="2x2_${ANTENNA_PORT}xLTE${FREQ_BAND}_${MODE}_${ZIF}"
					echo "$CONFIGURATION"
				elif [ $USE_ZERO_IF == 2 ]
				then
					echo "ZIF is NOT required in RADIO Config"
					CONFIGURATION="2x2_${ANTENNA_PORT}xLTE${FREQ_BAND}_${MODE}"
					echo "$CONFIGURATION"
				fi
			fi
		fi

		#RADIO SELECT
		radio select $CONFIGURATION
		check_failure $?

		#RADIO INIT
		retry=0
		while [ $retry -lt $RETRYCOUNT ]
		do
			retry=`expr $retry + 1`
			radio init
			ret=$?
			if [ $ret -eq 0 ]; then
				break
			fi
			if [ $retry -ge $RETRYCOUNT ]; then
				check_failure $ret
			fi
		done

		#cell_stop - cell_start Fix Start
		#RADIO TDD CONFIG for TDD Duplex Mode ONLY
		if [ "$MODE" == "TDD" ];
		then
			echo "DUPLEXMODE has the value 'TDD'"
			radio tddconfig normal $TDD_SUBFRAME $TDD_SPESUBFRAME 71 71 0 -142
			check_failure $?
		fi
		#cell_stop - cell_start Fix End

	else
		echo "Error: Invalid number of parameters[$#] for RADIO_INIT!!!"
	fi

	#cell_stop - cell_start Fix Start
    # radio_on(U16  ul_frequency, U16  dl_frequency, U8  hwType)
	#cell_stop - cell_start Fix End
	elif [ $2 == $ON ]
	then
		echo "RADIO ON has been triggered"
		echo "Number of parameters are $#"
		#cell_stop - cell_start Fix Start
		if [ $# -eq 4 ]
		then
			echo "RADIO ON has 2 parameters"
			#cell_stop - cell_start Fix End
			#Fetch all arguments
			EARFCN_UL=$3
			EARFCN_DL=$4

			echo "EARFCN_UL: ${EARFCN_UL}"
			echo "EARFCN_DL: ${EARFCN_DL}"

			#RADIO ON
			#retry=0
			#while [ $retry -lt $RETRYCOUNT ]
			#do
				#retry=`expr $retry + 1`
				radio on ${EARFCN_UL} ${EARFCN_DL}
				#ret=$?
				#if [ $ret -eq 0 ] ; then
				#	break
				#	fi
				#if [ $retry -ge $RETRYCOUNT ] ; then
				#	check_failure $ret
				#fi
            #done
		elif [ $# -eq 6 ]
		then
			EARFCN_UL=$3
			EARFCN_DL=$4
			EARFCN_UL_100K=$5
			EARFCN_DL_100K=$6

			echo "FREQ_UL: ${EARFCN_UL}.${EARFCN_UL_100K}"
			echo "FREQ_DL: ${EARFCN_DL}.${EARFCN_DL_100K}"

			radio on ${EARFCN_UL}.${EARFCN_UL_100K} ${EARFCN_DL}.${EARFCN_DL_100K}
		else
			echo "Error: Invalid number of parameters[$#] for RADIO_ON!!!"
		fi

	# radio_off()
	elif [ $2 == $OFF ]
	then
		echo "RADIO OFF has been triggered"
		echo "Number of parameters are $#"
		if [ $# -eq 3 ]
		then
			echo "RADIO OFF has 1 parameter"
			EXPLICIT_RADIO=$3
			echo "EXPLICIT_RADIO: $EXPLICIT_RADIO"

			#RADIO OFF
			retry=0
			while [ $retry -lt $RETRYCOUNT ]
			do
				retry=`expr $retry + 1`
				if [ $EXPLICIT_RADIO -ne 0 ];
				then
					echo "EXPLICIT RADIO..."
					`radio off`
				else
					`radio off`
					echo "NOT EXPLICIT RADIO..."
				fi
				ret=$?
				if [ $ret -eq 0 ] ; then
					break
				fi
				if [ $retry -ge $RETRYCOUNT ] ; then
					check_failure $ret
				fi
			done

		else
			echo "Error: Invalid number of parameters[$#] for RADIO_OFF!!!"
		fi

	# radio_reset()
	elif [ $2 == $RESET ]
	then
		echo "RADIO RESET has been triggered"
		echo "Number of parameters are $#"
		if [ $# -eq 2 ]
		then
			echo "RADIO RESET has NO parameters"

			#RADIO RESET
			retry=0
			while [ $retry -lt $RETRYCOUNT ]
			do
				retry=`expr $retry + 1`
				OUTPUT=`radio reset`
				ret=$?
				if [ $ret -eq 0 ] ; then
					break
				fi
				if [ $retry -ge $RETRYCOUNT ] ; then
					check_failure $ret
				fi
			done
		else
			echo "Error: Invalid number of parameters[$#] for RADIO_reset!!!"
		fi

	# radio_get_status(char* statusmsg)
	elif [ $2 == $STATUS ]
    then
		echo "RADIO STATUS has been triggered"
		echo "Number of parameters are $#"
		if [ $# -eq 3 ]
		then
			echo "RADIO STATUS has 1 parameter"
			SET_ATTEN=$3
			echo "SET_ATTEN: $SET_ATTEN"

			#RADIO STATUS
			radio status
			check_failure $?

			if [ $SET_ATTEN == 1 ];
			then
				echo "Radio State for Set Tx Atten"
				radio status | grep "state" | awk 'NF>1{print $NF}' | tr -d '"' | tr -d ','
			else
				echo "Radio Status Command only"
			fi
		else
			echo "Error: Invalid number of parameters[$#] for RADIO_GET_STATUS!!!"
		fi

	# radio_atten_set
	elif [ $2 == $SETATTEN ]
	then
		echo "RADIO SET ATTEN has been triggered"
		echo "Number of parameters are $#"
		if [ $# -eq 6 ]
		then
			echo "RADIO SET ATTEN has 4 parameters"
			export TX1_ATTEN=$3
			export TX2_ATTEN=$4
			export TX3_ATTEN=$5
			export TX4_ATTEN=$6
			echo "TX1_ATTEN: $TX1_ATTEN"
			echo "TX2_ATTEN: $TX2_ATTEN"
			echo "TX3_ATTEN: $TX3_ATTEN"
			echo "TX4_ATTEN: $TX4_ATTEN"

			#RADIO SET ATTENUATION
			radio set afe[0].tx[0].attenuation $TX1_ATTEN
			check_failure $?
			radio set afe[0].tx[1].attenuation $TX2_ATTEN
			check_failure $?
			radio set afe[1].tx[0].attenuation $TX3_ATTEN
			check_failure $?
			radio set afe[1].tx[1].attenuation $TX4_ATTEN
			check_failure $?
		else
			echo "Error: Invalid number of parameters[$#] for RADIO_GET_STATUS!!!"
		fi

	# radio_precrfgain_set
	elif [ $2 == $SETCFRGAIN ]
	then
		echo "RADIO SET CFRGAIN has been triggered"
		echo "Number of parameters are $#"
		if [ $# -eq 6 ]
		then
			echo "RADIO SET CFRGAIN has 4 parameters"
			export TX1_CFRGAIN=$3
			export TX2_CFRGAIN=$4
			export TX3_CFRGAIN=$5
			export TX4_CFRGAIN=$6
			echo "TX1_CFRGAIN: $TX1_CFRGAIN"
			echo "TX2_CFRGAIN: $TX2_CFRGAIN"
			echo "TX3_CFRGAIN: $TX3_CFRGAIN"
			echo "TX4_CFRGAIN: $TX4_CFRGAIN"

			radio set dfe.stream[0].cfr.preGain $TX1_CFRGAIN
			check_failure $?
			radio set dfe.stream[1].cfr.preGain $TX2_CFRGAIN
			check_failure $?
			radio set dfe.stream[2].cfr.preGain $TX3_CFRGAIN
			check_failure $?
			radio set dfe.stream[3].cfr.preGain $TX4_CFRGAIN
			check_failure $?
		else
			echo "Error: Invalid number of parameters[$#] for RADIO_GET_STATUS!!!"
		fi

	# radio_postcrfgain_set
	elif [ $2 == $SETPOSTCFRGAIN ]
	then
		echo "RADIO SET POST CFRGAIN has been triggered"
		echo "Number of parameters are $#"
		if [ $# -eq 6 ]
		then
			echo "RADIO SET POSET CFRGAIN has 4 parameters"
			export TX1_CFRGAIN=$3
			export TX2_CFRGAIN=$4
			export TX3_CFRGAIN=$5
			export TX4_CFRGAIN=$6
			echo "TX1_CFRGAIN: $TX1_CFRGAIN"
			echo "TX2_CFRGAIN: $TX2_CFRGAIN"
			echo "TX3_CFRGAIN: $TX3_CFRGAIN"
			echo "TX4_CFRGAIN: $TX4_CFRGAIN"

			radio set dfe.stream[0].cfr.postGain $TX1_CFRGAIN
			check_failure $?
			radio set dfe.stream[1].cfr.postGain $TX2_CFRGAIN
			check_failure $?
			radio set dfe.stream[2].cfr.postGain $TX3_CFRGAIN
			check_failure $?
			radio set dfe.stream[3].cfr.postGain $TX4_CFRGAIN
			check_failure $?
		else
			echo "Error: Invalid number of parameters[$#] for RADIO_GET_STATUS!!!"
		fi

	# radio_check
	elif [ $2 == $CHECK ]
	then
		# echo "RADIO CHECK has been triggered"
		# echo "Number of parameters are $#"
		if [ $# -eq 3 ]
		then
			# echo "RADIO CHECK has 1 parameter"
			if [ $3 == 0 ]
			then
				export CHECK_TARGET=dfe
			elif [ $3 == 1 ]
			then
				export CHECK_TARGET=afe
			else
				export CHECK_TARGET=all
			fi

			#RADIO CHECK
			radio check $CHECK_TARGET
			check_failure $?
		else
			echo "Error: Invalid number of parameters[$#] for RADIO_CHECKS!!!"
		fi

	# radio_relock()
	elif [ $2 == $RELOCK ]
	then
		echo "RADIO RELOCK has been triggered"
		echo "Number of parameters are $#"
		if [ $# -eq 2 ]
		then
			echo "RADIO RELOCK has NO parameters"

			#RADIO RELOCK, not support new RFSDK
			#radio relock
			#check_failure $?
		else
			echo "Error: Invalid number of parameters[$#] for RADIO_RELOCK!!!"
		fi

	else
		echo "Error: Invalid RADIO COMMAND!!!"
	fi

elif [ $1 == "EXPLICIT_INIT" ]
then
	#syslogd
	#/etc/init.d/syslog restart
	radio reset

	radio select $2

	#RADIO INIT
	radio init
	check_failure $?

elif [ $1 == "EXPLICIT_ON" ]
then
	EARFCN_UL=$2
	EARFCN_DL=$3
	TDD_SUBFRAME=$4
	TDD_SPESUBFRAME=$5
	DUPLEXMODE=$6
	RETRYCOUNT=3

	while [ 1 ]
	do
		sleep 1
		echo "Configuring Radio..."
		if grep -q "Value of Cfi :" "/sys/kernel/debug/remoteproc/remoteproc3/trace0"; then
			break
		fi
	done

	if [ $# -eq 8 ]
	then
		EARFCN_UL_100K=$7
		EARFCN_DL_100K=$8
		echo "FREQ_UL: ${EARFCN_UL}.${EARFCN_UL_100K}"
		echo "FREQ_DL: ${EARFCN_DL}.${EARFCN_DL_100K}"
	else
		EARFCN_UL_100K=0
		EARFCN_DL_100K=0
		echo "EARFCN_UL: ${EARFCN_UL}"
		echo "EARFCN_DL: ${EARFCN_DL}"
	fi

	if [ "$DUPLEXMODE" == "TDDMOde" ];
	then
		MODE=FDD
	elif [ "$DUPLEXMODE" == "FDDMode" ];
	then
		MODE=TDD
	else
		MODE=INVALID
	fi

	if [ "$MODE" == "TDD" ];
	then
		echo "DUPLEXMODE has the value 'TDD'"
		radio tddconfig normal $TDD_SUBFRAME $TDD_SPESUBFRAME 71 71 0 -142
		check_failure $?
	fi

	#RADIO ON
	retry=0
	while [ $retry -lt $RETRYCOUNT ]
	do
		retry=`expr $retry + 1`
		if [ $# -eq 8 ]
		then
			radio on ${EARFCN_UL}.${EARFCN_UL_100K} ${EARFCN_DL}.${EARFCN_DL_100K}
		else
			radio on ${EARFCN_UL} ${EARFCN_DL}
		fi
		ret=$?
		if [ $ret -eq 0 ] ; then
			break
		fi
		if [ $retry -ge $RETRYCOUNT ] ; then
			check_failure $ret
		fi
	done

	echo -e "set pa all on\r\n" > /dev/ttyS1

else
	echo "ERROR: This script is intended for RADIO ONLY!!!"
	exit 1
fi
