set slack_token to "xoxp-XXXXXXXX-XXXXXXXXX"
set slack_dnd_url to "https://slack.com/api/dnd.setSnooze"
set slack_dnd_num_minutes to 60

set slack_status_url to "https://slack.com/api/users.profile.set"
set status_text to "In a Zoom meeting"
set status_emoji to ":telephone_receiver:"
set delay_secs to 5

repeat
	
	if isMeetingInProgress() then
		-- set DnD and status
		set curl_cmd to "curl 'https://slack.com/api/dnd.setSnooze?token=" & slack_token & "&num_minutes=" & slack_dnd_num_minutes & "'"
		do shell script curl_cmd
		
		set payload to "profile={\"status_text\": \"" & status_text & "\", \"status_emoji\": \"" & status_emoji & "\"}"
		set curl_cmd to "curl -sS -X POST -d \"token=" & slack_token & "\" --data-urlencode '" & payload & "' " & slack_status_url
		do shell script curl_cmd
		
		-- wait for the meeting to end
		repeat while isMeetingInProgress() is true
			delay delay_secs
		end repeat
		
	else
		-- remove DnD
		set curl_cmd to "curl 'https://slack.com/api/dnd.endSnooze?token=" & slack_token & "'"
		do shell script curl_cmd
		
		set payload to "profile={\"status_text\": \"\", \"status_emoji\": \"\"}"
		set curl_cmd to "curl -sS -X POST -d \"token=" & slack_token & "\" --data-urlencode '" & payload & "' " & slack_status_url
		do shell script curl_cmd
		
		-- wait for the meeting to start
		repeat while isMeetingInProgress() is false
			delay delay_secs
		end repeat
	end if
	
end repeat

on isMeetingInProgress()
	tell application "System Events"
		if exists (window "Zoom Meeting" of process "zoom.us") then
			return true
		else
			return false
		end if
	end tell
end isMeetingInProgress