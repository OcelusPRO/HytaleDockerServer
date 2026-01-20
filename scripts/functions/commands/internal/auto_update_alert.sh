#!/bin/bash
# shellcheck disable=SC2148

execute() {
  send_server_command 'eventtitle --title="The server will restart in 5 minutes"  --secondary="Warning, Server Update" --major'

  sleep 180
  send_server_command 'eventtitle --title="The server will restart in 2 minutes"  --secondary="Warning, Server Update" --major'

  sleep 60
  send_server_command 'eventtitle --title="The server will restart in 1 minute"  --secondary="Warning, Server Update" --major'


  sleep 30
  send_server_command 'eventtitle --title="The server will restart in 30 seconds"  --secondary="Warning, Server Update" --major'

  sleep 20
  send_server_command 'eventtitle --title="The server will restart in 10 seconds"  --secondary="Warning, Server Update" --major'

  sleep 10
  send_server_command 'eventtitle --title="Server is restarting now!"  --secondary="Warning, Server Update" --major'

  sleep 2
  send_server_command "stop"
}