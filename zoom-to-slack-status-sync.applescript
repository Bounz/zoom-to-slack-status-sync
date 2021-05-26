property slack_token : "xoxp-XXXXXXXX-XXXXXXXXX"
property slack_dnd_url : "https://slack.com/api/dnd.setSnooze"
property slack_dnd_num_minutes : 60

property slack_status_url : "https://slack.com/api/users.profile.set"
property status_text : "In a Zoom meeting"
property status_emoji : ":telephone_receiver:"
property delay_secs : 5
property prevMeetingInProgressState : false


on idle
	
	if isMeetingInProgress() and prevMeetingInProgressState is false then
		-- set DnD and status
		set prevMeetingInProgressState to true
		set curl_cmd to "curl -sS -X POST -d token=" & slack_token & " https://slack.com/api/dnd.setSnooze?num_minutes=" & slack_dnd_num_minutes
		do shell script curl_cmd
		
		set payload to "profile={\"status_text\": \"" & status_text & "\", \"status_emoji\": \"" & status_emoji & "\"}"
		set curl_cmd to "curl -sS -X POST -d \"token=" & slack_token & "\" --data-urlencode '" & payload & "' " & slack_status_url
		do shell script curl_cmd		
	else
		if isMeetingInProgress() is false and prevMeetingInProgressState is true then			
			-- remove DnD and clear status
			set prevMeetingInProgressState to false
			set curl_cmd to "curl -sS -X POST -d token=" & slack_token & " https://slack.com/api/dnd.endSnooze"
			do shell script curl_cmd
			
			set payload to "profile={\"status_text\": \"\", \"status_emoji\": \"\"}"
			set curl_cmd to "curl -sS -X POST -d \"token=" & slack_token & "\" --data-urlencode '" & payload & "' " & slack_status_url
			do shell script curl_cmd			
		end if
	end if
	
	return delay_secs
end idle


on isMeetingInProgress()
	tell application "System Events"
		if exists (window "Zoom Meeting" of process "zoom.us") then
			return true
		else
			return false
		end if
	end tell
end isMeetingInProgress


on quit
	continue quit
end quit
