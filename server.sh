#!/bin/bash

main(){
	log_message "Server starting on port $PORT"
	setup_socket


	while true; do
		log_message "Wating for connection on port $PORT..."
		if wait_for_connection; then
			handle_client &
		else 
			log_message "Failed to accpet connection"
		fi
	done
}

main
