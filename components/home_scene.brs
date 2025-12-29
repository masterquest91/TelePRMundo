function init()
	? "[home_scene] init"

	m.search_container = m.top.findNode("search_container")
	m.search_label = m.top.findNode("search_label")
	m.search_keyboard = m.top.findNode("search_keyboard")
	m.category_screen = m.top.findNode("category_screen")
	m.content_screen = m.top.findNode("content_screen")
	m.details_screen = m.top.findNode("details_screen")
	m.error_dialog = m.top.findNode("error_dialog")
	m.videoplayer = m.top.findNode("videoplayer")
	
	initializeVideoPlayer()
	
	m.search_keyboard.observeField("text", "onSearchTextChanged")
	m.category_screen.observeField("category_selected", "onCategorySelected")
	m.content_screen.observeField("content_selected", "onContentSelected")
	m.details_screen.observeField("play_button_pressed", "onPlayButtonPressed")

	' Play default livestream on startup
	playDefaultLivestream()
	
	' Set focus to search bar initially
	m.search_container.setFocus(true)

	loadConfig()
end function

sub initializeVideoPlayer()
	m.videoplayer.EnableCookies()
	m.videoplayer.setCertificatesFile("common:/certs/ca-bundle.crt")
	m.videoplayer.InitClientCertificates()
									   
	m.videoplayer.notificationInterval=1
	m.videoplayer.observeFieldScoped("state", "onPlayerStateChanged")
end sub

sub playDefaultLivestream()
	' Create content node for El Conquistador livestream
	livestreamContent = createObject("roSGNode", "ContentNode")
	livestreamContent.url = "https://videos-3.earthcam.com/fecnetwork/30369.flv/playlist.m3u8"
	livestreamContent.streamformat = "hls"
	livestreamContent.title = "El Conquistador Resort - Live"
	
	m.videoplayer.visible = true
	m.videoplayer.content = livestreamContent
	m.videoplayer.control = "play"
end sub

sub onSearchTextChanged()
	searchText = m.search_keyboard.text
	? "Search text changed: "; searchText
	
	' Update the label with the entered text
	if searchText <> ""
		m.search_label.text = searchText
		m.search_label.color = "0xFFFFFF"
	else
		m.search_label.text = "Search"
		m.search_label.color = "0x888888"
	end if
end sub

sub processSearch()
	searchText = m.search_keyboard.text
	searchLower = LCase(searchText)
	
	? "Processing search: "; searchText
	
	' Hide keyboard
	m.search_keyboard.visible = false
	
	if searchLower = "boricua"
		' Correct search term - show category menu
		? "Correct search term! Loading categories..."
		m.videoplayer.control = "stop"
		m.videoplayer.visible = false
		m.category_screen.visible = true
		m.category_screen.setFocus(true)
	else
		' Wrong term or empty - just show the feeds anyway (on error, default to feeds)
		? "Default behavior - loading feeds..."
		m.videoplayer.control = "stop"
		m.videoplayer.visible = false
		m.category_screen.visible = true
		m.category_screen.setFocus(true)
	end if
	
	' Reset search
	m.search_keyboard.text = ""
	m.search_label.text = "Search"
	m.search_label.color = "0x888888"
end sub

sub loadConfig()
    m.config_task = createObject("roSGNode", "load_config_task")
    m.config_task.observeField("filedata", "onConfigResponse")
    m.config_task.observeField("error", "onConfigError")
    m.config_task.filepath = "source/config.json"
    m.config_task.control="RUN"
end sub

sub onConfigResponse(obj)
	params = {config:obj.getData()}
	m.category_screen.callFunc("updateConfig",params)
	m.content_screen.callFunc("updateConfig",params)
end sub

sub onConfigError(obj)
	showErrorDialog(obj.getData())
end sub

sub onCategorySelected(obj)
																	  
	selected_index = obj.getData()
									   
	? "selected_index :";selected_index
	? "checkedItem: ";m.category_screen.findNode("category_list").checkedItem
														 
															
	m.selected_category = m.category_screen.findNode("category_list").content.getChild(selected_index)
																  
	loadFeed(m.selected_category.feed_url)
end sub

sub onContentSelected(obj)
																	  
	selected_index = obj.getData()
															  
	m.selected_media = m.content_screen.findNode("content_grid").content.getChild(selected_index)
	m.details_screen.content = m.selected_media
	m.content_screen.visible = false
	m.details_screen.visible = true
end sub

sub onPlayButtonPressed(obj)
	? "PLAY!!!",m.selected_media
	m.details_screen.visible = false
	m.videoplayer.visible = true
	m.videoplayer.setFocus(true)
	m.videoplayer.content = m.selected_media
	m.videoplayer.control = "play"
end sub

sub loadFeed(url)
	m.feed_task = createObject("roSGNode", "load_feed_task")
	m.feed_task.observeField("response", "onFeedResponse")
	m.feed_task.observeField("error", "onFeedError")
	m.feed_task.url = url
	m.feed_task.control = "RUN"
end sub

sub onFeedResponse(obj)
	response = obj.getData()
												  
	data = parseJSON(response)
	if data <> invalid and data.items <> invalid
													
		m.category_screen.visible = false
		m.content_screen.visible = true
								 
		m.content_screen.feed_data = data
	else
		showErrorDialog("Feed data malformed.")
	end if
end sub

sub onFeedError(obj)
	showErrorDialog(obj.getData())
end sub

sub onPlayerStateChanged(obj)
	state = obj.getData()
	? "onPlayerStateChanged: ";state
	if state="error"
		showErrorDialog(m.videoplayer.errorMsg+ chr(10) + "Error Code: "+m.videoplayer.errorCode.toStr())
	else if state = "finished"
		closeVideo()
	end if
end sub

sub closeVideo()
	m.videoplayer.control = "stop"
	m.videoplayer.visible=false
	m.category_screen.visible=true
end sub

sub showErrorDialog(message)
	m.error_dialog.title = "ERROR"
	m.error_dialog.message = message
	m.error_dialog.visible=true
															  
	m.top.dialog = m.error_dialog
end sub

							  
function onKeyEvent(key, press) as Boolean
	? "[home_scene] onKeyEvent", key, press
	
	if key = "OK" and press
		' If search container has focus, show keyboard
		if m.search_container.hasFocus()
			m.search_keyboard.visible = true
			m.search_keyboard.setFocus(true)
			return true
		' If keyboard is visible and OK is pressed, process search
		else if m.search_keyboard.visible
			processSearch()
			return true
		end if
	end if
	
	if key = "back" and press
		' If keyboard is visible, close it
		if m.search_keyboard.visible
			m.search_keyboard.visible = false
			m.search_keyboard.text = ""
			m.search_label.text = "Search"
			m.search_label.color = "0x888888"
			m.search_container.setFocus(true)
			return true
		else if m.content_screen.visible
			m.content_screen.visible=false
			m.category_screen.visible=true
			return true
		else if m.details_screen.visible
			m.details_screen.visible=false
			m.content_screen.visible=true
			return true
		else if m.videoplayer.visible and not m.search_container.hasFocus()
			' Allow navigation to search bar from video
			m.search_container.setFocus(true)
			return true
		else if m.category_screen.visible
			' Go back to livestream
			m.category_screen.visible = false
			playDefaultLivestream()
			m.search_container.setFocus(true)
			return true
		end if
	end if
	
	return false
end function
