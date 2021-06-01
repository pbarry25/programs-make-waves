#!/usr/bin/env bash
#
# Simple script to convert an executable or script execution into human-audible
# tones.  Specifically, SYSCALLs (system calls) are monitored during execution 
# via `strace` and converted to tones, then written out to a WAV file.

if [ ${#} -lt 1 -o "${1}" == "-h" -o "${1}" = "--help" ]
then
	echo "Usage: ${0} <program name> [<program name> ...]"
	exit 1
fi

HWFILES=${*}

# Number of WAVE samples per tone...
SAMPLE_COUNT_SLICE=1000

# Write out a wave file with valid header information...
# Reference: https://web.archive.org/web/20210526072758/http://soundfile.sapp.org/doc/WaveFormat/
function write_wave_file() {
	FILE=${1}
	TOTAL_SAMPLES=${2}
	SAMPLE_SIZE_BYTES=${3}

	SUB_CHUNK_2_SIZE=$((TOTAL_SAMPLES * SAMPLE_SIZE_BYTES))
	CHUNK_SIZE=$((36 + SUB_CHUNK_2_SIZE))

	# RIFF header
	printf '\x52\x49\x46\x46' > ${FILE}
	COUNT=0
	while [ ${COUNT} -lt 4 ]
	do
		MOD=$((CHUNK_SIZE % 256))
		MOD_HEX=`printf "%x" ${MOD}`
		printf "\x${MOD_HEX}" >> ${FILE}
		CHUNK_SIZE=$((CHUNK_SIZE / 256))
		COUNT=$((COUNT + 1))
	done
	printf '\x57\x41\x56\x45' >> ${FILE}

	# "fmt" subchunk...
	printf '\x66\x6d\x74\x20' >> ${FILE}
	printf '\x10\x00\x00\x00' >> ${FILE}
	printf '\x01\x00' >> ${FILE}
	printf '\x01\x00' >> ${FILE}
	printf '\x80\x3e\x00\x00' >> ${FILE}
	printf '\x00\x7d\x00\x00' >> ${FILE}
	printf '\x02\x00' >> ${FILE}
	printf '\x10\x00' >> ${FILE}

	# "data" subchunk...
	printf '\x64\x61\x74\x61' >> ${FILE}
	COUNT=0
	while [ ${COUNT} -lt 4 ]
	do
		MOD=$((SUB_CHUNK_2_SIZE % 256))
		MOD_HEX=`printf "%x" ${MOD}`
		printf "\x${MOD_HEX}" >> ${FILE}
		SUB_CHUNK_2_SIZE=$((SUB_CHUNK_2_SIZE / 256))
		COUNT=$((COUNT + 1))
	done

	# Append all the sample data to the new WAV file...
	cat ${FILE}.tmp >> ${FILE}
}

# Iterate through all given programs and convert each into to WAVs...
declare -A CALL_MAP
rm -f tmp-freq-*.wav
for HWFILE in ${HWFILES}
do
	if [ ! -e ${HWFILE} ]
	then
		echo "Could not locate file ${HWFILE}, skipping..."
		continue
	fi

	echo -n "Processing ${HWFILE}..."

	# Execute program and convert SYSCALLS to arbitrary byte values (0-255)...
	rm -f ${HWFILE}.rawdat
	for CALL in `strace ${HWFILE} 2>&1 | sed -n 's/^\([^(]*\)(.*$/\1/p'`
	do
		if [ -z "${CALL_MAP[$CALL]}" ]
		then
			# First time we've seen this SYSCALL, calculate it's value...
			TONE=`echo -n $CALL|shasum -a 256|cut -b 3-4`
			CALL_MAP[$CALL]=${TONE}
		else
			# We already have this SYSCALL, grab the associated value from memory...
			TONE=${CALL_MAP[$CALL]}
		fi
		echo $TONE >> ${HWFILE}.rawdat
	done

	# Convert to note frequency (Hz)...
	rm -f ${HWFILE}.freqdat
	while read -r VALUE
	do
		# Arbitrary calculation to change a hex byte value into a human-audible freq...
		expr $((16#${VALUE})) \* 3 \+ 50 >> ${HWFILE}.freqdat
	done < ${HWFILE}.rawdat
	rm -f ${HWFILE}.rawdat

	# Create the associated WAVE file...
	rm -f ${HWFILE}.wav.tmp
	TOTAL_SAMPLE_COUNT=0
	while read -r FREQ
	do
		if [ ! -e tmp-freq-${FREQ}.wav ]
		then
			# We haven't created waveform samples for this frequency yet, so do now...
			# Compute the cycles needed to create this frequency for 16kHz sample rate...
			PERIOD=$((16000 / ${FREQ}))
			STEP=$((32767 / (${PERIOD} / 2)))
			
			# Write audio sample values out as waveforms...

			SAMPLE_COUNT=0
			VALUE=0
			# Write 2k samples, which works out to 1/8 of a second per tone...
			while [ ${SAMPLE_COUNT} -lt ${SAMPLE_COUNT_SLICE} ]; do
				SAMPLE_COUNT=$((SAMPLE_COUNT + 1))
				if [ ${VALUE} -eq 0 ]
				then
					printf '\x00\x00' >> tmp-freq-${FREQ}.wav
				else
					VALUE_TMP=${VALUE}
					BYTES_OUT=0
					while [ ${VALUE_TMP} -gt 0 ]
					do
						MOD=$((VALUE_TMP % 256))
						MOD_HEX=`printf "%x" ${MOD}`
						printf "\x${MOD_HEX}" >> tmp-freq-${FREQ}.wav
						BYTES_OUT=$((BYTES_OUT + 1))
						VALUE_TMP=$((VALUE_TMP / 256))
						if [ ${VALUE_TMP} -eq 0 -a ${BYTES_OUT} -lt 2 ]
						then
							printf '\x00' >> tmp-freq-${FREQ}.wav
						fi
					done
				fi
				VALUE=$((VALUE + STEP))
				if [ ${VALUE} -ge 32767 ]
				then
					VALUE=$((VALUE - (STEP * 2)))
					STEP=$((STEP * -1))
				elif [ ${VALUE} -le 0 ]
				then
					STEP=$((STEP * -1))
					VALUE=0
				fi
			done
		fi
		cat tmp-freq-${FREQ}.wav >> ${HWFILE}.wav.tmp
		TOTAL_SAMPLE_COUNT=$((TOTAL_SAMPLE_COUNT + SAMPLE_COUNT_SLICE))
		echo -n "."
	done < ${HWFILE}.freqdat
	rm -f ${HWFILE}.freqdat
	rm -f ${HWFILE}.*.wav.tmp

	# Create header and the final version of the WAV file...
	rm -f ${HWFILE}.wav
	write_wave_file ${HWFILE}.wav ${TOTAL_SAMPLE_COUNT} 2
	rm -f ${HWFILE}.wav.tmp

	echo " Done."
done
rm -f tmp-freq-*.wav

exit 0
