#!/bin/bash

setup_socket(){
	coproc nc -l -p $PORT -k
	if [$? -ne 0]; then
		log_message "Failed to create socket"
		exit 1
	fi
}

wait_for_connection(){
	read -r -u ${COPROC[0]} -t 1 || return 1
	return 0 
}

handle_client(){
	local client_id=$RANDOM
	log_message "New client connected: $client_id"

	if ! perform_handshake $client_id; then
		log_message "Handshake failed for client $client_id"
		return
	fi

	while IFS= read -r -u ${COPROC[0]} -t 1 line; do
		case "$line" in
			"FILE:"*)
				receive_file "${line#FILE:}" $client_id
				;;
			"QUIT")
				log_message "Client $client_id disconnected"
				echo "Goodbye !" >&${COPROC[1]}
				break
				;;
			*)
				log_message "Received from client $client_id: $line"
				echo "Server: ${date}" >&${COPROC[1]}
				;;
		esac
	done
}

perform_handshake(){
	local client_id=$1
	echo "HELLO" >&${COPROC[1]}
	read -r -u ${COPROC[0]} -t 5 response
	if [ "$response" != "HELLO_ACK" ]; then
		return 1

	fi
	echo "WELCOME $client_id" >&${COPROC[1]}
	return 0
}

recieve_file(){
	local filename = $1
	local client_id = $2
	local filepath = "$UPLOADS_DIR/${client_id}_${filename}"

	log_message "Recieving file : $filename from client $client_id"
	echo "READY" > &${COPROC[1]}

	#Reading file content
	local content = ""
	while IFS= read -r -u ${COPROC[0]} -t 10 line; do
		if [ "$line" = "EOF" ]; then
			break

		fi
		content += "$line"$'\n'
	done

	echo "$content" > "$filepath"
	log_message "File receive and saved : $filepath"
	echo "File received successfully" >&${COPROC[1]}
}

log_message() {
	echo "${date} : $1" >> "$LOG_FILE"
}

mkdir -p "$UPLOADS_DIR"

