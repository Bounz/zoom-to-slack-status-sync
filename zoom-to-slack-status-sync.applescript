-- User settings
property slack_token : "xoxp-XXXXXXXX-XXXXXXXXX"
property zoom_status_text : "In a Zoom meeting"
property zoom_status_emoji : ":telephone_receiver:"

-- System settings
property slack_dnd_url : "https://slack.com/api/dnd.setSnooze"
property slack_dnd_num_minutes : 60
property slack_status_url : "https://slack.com/api/users.profile.set"
property status_text : ""
property status_emoji : ""
property status_expiration : 0
property delay_secs : 5
property prevMeetingInProgressState : false

property slack_profile_get_url : "https://slack.com/api/users.profile.get"
property status_emoji_rx : "\"\\\"status_emoji\\\":\\\"(.*?)\\\",\""
property status_text_rx : "\"\\\"status_text\\\":\\\"(.*?)\\\",\""
property status_expiration_rx : "\"\\\"status_expiration\\\":(.*?),\""


on idle
	
	if isMeetingInProgress() and prevMeetingInProgressState is false then
		-- get current status
		set curl_cmd to "curl -sS -X POST -d token=" & slack_token & " " & slack_profile_get_url
		set profile_resp to do shell script curl_cmd
		set status_emoji to match(profile_resp, status_emoji_rx)
		set status_text to match(profile_resp, status_text_rx)
		set status_expiration to match(profile_resp, status_expiration_rx)

		-- set DnD and status
		set prevMeetingInProgressState to true
		set curl_cmd to "curl -sS -X POST -d token=" & slack_token & " https://slack.com/api/dnd.setSnooze?num_minutes=" & slack_dnd_num_minutes
		do shell script curl_cmd
		
		set payload to "profile={\"status_text\": \"" & zoom_status_text & "\", \"status_emoji\": \"" & zoom_status_emoji & "\"}"
		set curl_cmd to "curl -sS -X POST -d \"token=" & slack_token & "\" --data-urlencode '" & payload & "' " & slack_status_url
		do shell script curl_cmd		
	else
		if isMeetingInProgress() is false and prevMeetingInProgressState is true then			
			-- remove DnD and restore status
			set prevMeetingInProgressState to false
			set curl_cmd to "curl -sS -X POST -d token=" & slack_token & " https://slack.com/api/dnd.endSnooze"
			do shell script curl_cmd
			
			set payload to "profile={\"status_text\": \"" & status_text & "\", \"status_emoji\": \"" & status_emoji & "\", \"status_expiration\": " & status_expiration & "}"
			set curl_cmd to "curl -sS -X POST -d \"token=" & slack_token & "\" --data-urlencode '" & payload & "' " & slack_status_url
			do shell script curl_cmd			
		end if
	end if
	
	return delay_secs
end idle


on isMeetingInProgress()
	try
		tell application "System Events"
			set windowsList to windows of process "zoom.us"
			
			repeat with theWindow in windowsList
				set windowTitle to title of theWindow
				log windowTitle
				if windowTitle contains "Zoom Meeting" or windowTitle contains "zoom share" then
					return true
				end if
			end repeat
		end tell
	end try
	
	return false
end isMeetingInProgress

on match(_subject, _regex)
	set _js to "(new String(`" & _subject & "`)).match(" & _regex & ")[1]"
	set _result to run script _js in "JavaScript"
	if _result is null or _result is missing value then
		return {}
	end if
	return _result
end match

on quit
	continue quit
end quit
