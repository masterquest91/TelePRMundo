function init()
	? "[home_scene] init"

	m.rows_container = m.top.findNode("rows_container")
	m.tv_row = m.top.findNode("tv_row")
	m.radio_row = m.top.findNode("radio_row")
	m.live_row = m.top.findNode("live_row")
	m.preview_thumbnail = m.top.findNode("preview_thumbnail")
	m.preview_title = m.top.findNode("preview_title")
	m.preview_description = m.top.findNode("preview_description")
	m.radio_bg_container = m.top.findNode("radio_bg_container")
	m.radio_background = m.top.findNode("radio_background")
	m.stream_nav_modal = m.top.findNode("stream_nav_modal")
	m.nav_next_title = m.top.findNode("nav_next_title")
	m.nav_prev_title = m.top.findNode("nav_prev_title")
	m.error_dialog = m.top.findNode("error_dialog")
	m.videoplayer = m.top.findNode("videoplayer")
	
	initializeVideoPlayer()
	
	m.tv_row.observeField("itemFocused", "onTVItemFocused")
	m.tv_row.observeField("itemSelected", "onTVItemSelected")
	m.radio_row.observeField("itemFocused", "onRadioItemFocused")
	m.radio_row.observeField("itemSelected", "onRadioItemSelected")
	m.live_row.observeField("itemFocused", "onLiveItemFocused")
	m.live_row.observeField("itemSelected", "onLiveItemSelected")

	' Store content and state
	m.tvContent = []
	m.radioContent = []
	m.liveContent = []
	m.currentRow = 0 ' 0=TV, 1=Radio, 2=Live
	m.currentStreamIndex = 0
	m.currentStreamType = ""
	
	' Set initial focus to TV row
	m.tv_row.setFocus(true)

	' Load feed
	loadFeed()
end function

sub initializeVideoPlayer()
	m.videoplayer.EnableCookies()
	m.videoplayer.setCertificatesFile("common:/certs/ca-bundle.crt")
	m.videoplayer.InitClientCertificates()
	m.videoplayer.notificationInterval=1
	m.videoplayer.observeFieldScoped("state", "onPlayerStateChanged")
end sub

sub loadFeed()
	m.feed_task = createObject("roSGNode", "load_feed_task")
	m.feed_task.observeField("response", "onFeedResponse")
	m.feed_task.observeField("error", "onFeedError")
	m.feed_task.url = "https://raw.githubusercontent.com/masterquest91/TelePRMundo/main/feeds/pr.json"
	m.feed_task.control = "RUN"
end sub

sub onFeedResponse(obj)
	response = obj.getData()
	data = parseJSON(response)
	if data <> invalid and data.items <> invalid
		? "Feed loaded with "; data.items.Count(); " items"
		
		' Separate TV, Radio, and Live items based on ID prefix
		tvItems = []
		radioItems = []
		liveItems = []
		
		for each item in data.items
			if item.id <> invalid
				itemId = LCase(item.id)
				if Left(itemId, 3) = "tv-"
					tvItems.Push(item)
				else if Left(itemId, 6) = "radio-"
					radioItems.Push(item)
				else if Left(itemId, 5) = "live-"
					liveItems.Push(item)
				end if
			end if
		end for
		
		? "TV items: "; tvItems.Count()
		? "Radio items: "; radioItems.Count()
		? "Live items: "; liveItems.Count()
		
		' Store for later use
		m.tvContent = tvItems
		m.radioContent = radioItems
		m.liveContent = liveItems
		
		' Display rows
		displayRows()
		
		' Update preview with first TV item
		if tvItems.Count() > 0
			updatePreview(tvItems[0])
		end if
	else
		showErrorDialog("Feed data malformed.")
	end if
end sub

sub displayRows()
	' Populate TV row
	if m.tvContent.Count() > 0
		tvContent = createObject("roSGNode", "ContentNode")
		for each item in m.tvContent
			node = createObject("roSGNode", "ContentNode")
			node.title = item.title
			node.HDPosterUrl = item.thumbnail
			node.HDGRIDPOSTERURL = item.thumbnail
			tvContent.appendChild(node)
		end for
		m.tv_row.content = tvContent
	end if
	
	' Populate Radio row
	if m.radioContent.Count() > 0
		radioContent = createObject("roSGNode", "ContentNode")
		for each item in m.radioContent
			node = createObject("roSGNode", "ContentNode")
			node.title = item.title
			node.HDPosterUrl = item.thumbnail
			node.HDGRIDPOSTERURL = item.thumbnail
			radioContent.appendChild(node)
		end for
		m.radio_row.content = radioContent
	end if
	
	' Populate Live row
	if m.liveContent.Count() > 0
		liveContent = createObject("roSGNode", "ContentNode")
		for each item in m.liveContent
			node = createObject("roSGNode", "ContentNode")
			node.title = item.title
			node.HDPosterUrl = item.thumbnail
			node.HDGRIDPOSTERURL = item.thumbnail
			liveContent.appendChild(node)
		end for
		m.live_row.content = liveContent
	end if
end sub

sub onTVItemFocused(obj)
	focusedIndex = obj.getData()
	? "TV item focused: "; focusedIndex
	if focusedIndex >= 0 and focusedIndex < m.tvContent.Count()
		updatePreview(m.tvContent[focusedIndex])
	end if
end sub

sub onTVItemSelected(obj)
	? "TV item selected"
	selectedIndex = obj.getData()
	if selectedIndex >= 0 and selectedIndex < m.tvContent.Count()
		m.currentStreamIndex = selectedIndex
		m.currentStreamType = "tv"
		playItem(m.tvContent[selectedIndex], "tv")
	end if
end sub

sub onRadioItemFocused(obj)
	focusedIndex = obj.getData()
	? "Radio item focused: "; focusedIndex
	if focusedIndex >= 0 and focusedIndex < m.radioContent.Count()
		updatePreview(m.radioContent[focusedIndex])
	end if
end sub

sub onRadioItemSelected(obj)
	? "Radio item selected"
	selectedIndex = obj.getData()
	if selectedIndex >= 0 and selectedIndex < m.radioContent.Count()
		m.currentStreamIndex = selectedIndex
		m.currentStreamType = "radio"
		playItem(m.radioContent[selectedIndex], "radio")
	end if
end sub

sub onLiveItemFocused(obj)
	focusedIndex = obj.getData()
	? "Live item focused: "; focusedIndex
	if focusedIndex >= 0 and focusedIndex < m.liveContent.Count()
		updatePreview(m.liveContent[focusedIndex])
	end if
end sub

sub onLiveItemSelected(obj)
	? "Live item selected"
	selectedIndex = obj.getData()
	if selectedIndex >= 0 and selectedIndex < m.liveContent.Count()
		m.currentStreamIndex = selectedIndex
		m.currentStreamType = "live"
		playItem(m.liveContent[selectedIndex], "live")
	end if
end sub

sub updatePreview(item as Object)
	' Update preview area with selected item details
	m.preview_thumbnail.uri = item.thumbnail
	m.preview_title.text = item.title
	m.preview_description.text = item.description
	
	' Adjust title font size if it wraps
	m.preview_title.font = "font:LargeBoldSystemFont"
	if m.preview_title.numLines > 1
		m.preview_title.font = "font:MediumBoldSystemFont"
	end if
	
	' Adjust description font size if it exceeds bounds
	m.preview_description.font = "font:MediumSystemFont"
	if m.preview_description.numLines > 8
		m.preview_description.font = "font:SmallSystemFont"
	end if
end sub

sub switchToRow(rowIndex as Integer)
	' Move the focused row to the top of the carousel area
	m.currentRow = rowIndex
	
	' Calculate new Y position for rows container
	' Each row is 400px tall (50px label + 20px spacing + 70px translation + 245px items + padding)
	newY = -(rowIndex * 400)
	
	' Animate the rows container
	animateRows = m.rows_container.createChild("Animation")
	animateRows.duration = 0.3
	animateInterp = animateRows.createChild("Vector2DFieldInterpolator")
	animateInterp.key = [0, 1]
	animateInterp.keyValue = [m.rows_container.translation, [0, newY]]
	animateInterp.fieldToInterp = "rows_container.translation"
	animateRows.control = "start"
	
	' Set focus to the appropriate row
	if rowIndex = 0
		m.tv_row.setFocus(true)
	else if rowIndex = 1
		m.radio_row.setFocus(true)
	else if rowIndex = 2
		m.live_row.setFocus(true)
	end if
end sub

sub playItem(item as Object, itemType as String)
	' Create content node for playback
	playContent = createObject("roSGNode", "ContentNode")
	playContent.url = item.url
	playContent.streamformat = item.streamformat
	playContent.title = item.title
	
	' Show thumbnail background for radio streams
	if itemType = "radio"
		m.radio_background.uri = item.thumbnail
		m.radio_bg_container.visible = true
	else
		m.radio_bg_container.visible = false
	end if
	
	m.tv_row.visible = false
	m.radio_row.visible = false
	m.live_row.visible = false
	m.videoplayer.visible = true
	m.videoplayer.setFocus(true)
	m.videoplayer.content = playContent
	m.videoplayer.control = "play"
	
	' Show navigation modal and update it
	updateStreamNavModal()
	m.stream_nav_modal.visible = true
end sub

sub updateStreamNavModal()
	' Update the stream navigation modal with next/prev stream info
	contentArray = []
	if m.currentStreamType = "tv"
		contentArray = m.tvContent
	else if m.currentStreamType = "radio"
		contentArray = m.radioContent
	else if m.currentStreamType = "live"
		contentArray = m.liveContent
	end if
	
	if contentArray.Count() > 0
		' Calculate next stream (wrap around)
		nextIndex = m.currentStreamIndex + 1
		if nextIndex >= contentArray.Count()
			nextIndex = 0
		end if
		
		' Calculate previous stream (wrap around)
		prevIndex = m.currentStreamIndex - 1
		if prevIndex < 0
			prevIndex = contentArray.Count() - 1
		end if
		
		' Update modal labels
		m.nav_next_title.text = contentArray[nextIndex].id
		m.nav_prev_title.text = contentArray[prevIndex].id
	end if
end sub

sub navigateToNextStream()
	contentArray = []
	if m.currentStreamType = "tv"
		contentArray = m.tvContent
	else if m.currentStreamType = "radio"
		contentArray = m.radioContent
	else if m.currentStreamType = "live"
		contentArray = m.liveContent
	end if
	
	if contentArray.Count() > 0
		' Move to next stream (with wrap)
		m.currentStreamIndex = m.currentStreamIndex + 1
		if m.currentStreamIndex >= contentArray.Count()
			m.currentStreamIndex = 0
		end if
		
		' Play the new stream
		playStreamByIndex(m.currentStreamIndex)
	end if
end sub

sub navigateToPrevStream()
	contentArray = []
	if m.currentStreamType = "tv"
		contentArray = m.tvContent
	else if m.currentStreamType = "radio"
		contentArray = m.radioContent
	else if m.currentStreamType = "live"
		contentArray = m.liveContent
	end if
	
	if contentArray.Count() > 0
		' Move to previous stream (with wrap)
		m.currentStreamIndex = m.currentStreamIndex - 1
		if m.currentStreamIndex < 0
			m.currentStreamIndex = contentArray.Count() - 1
		end if
		
		' Play the new stream
		playStreamByIndex(m.currentStreamIndex)
	end if
end sub

sub playStreamByIndex(index as Integer)
	selectedItem = invalid
	if m.currentStreamType = "tv"
		selectedItem = m.tvContent[index]
	else if m.currentStreamType = "radio"
		selectedItem = m.radioContent[index]
	else if m.currentStreamType = "live"
		selectedItem = m.liveContent[index]
	end if
	
	if selectedItem <> invalid
		' Create content node for playback
		playContent = createObject("roSGNode", "ContentNode")
		playContent.url = selectedItem.url
		playContent.streamformat = selectedItem.streamformat
		playContent.title = selectedItem.title
		
		' Update radio background if needed
		if m.currentStreamType = "radio"
			m.radio_background.uri = selectedItem.thumbnail
		end if
		
		m.videoplayer.content = playContent
		m.videoplayer.control = "play"
		
		' Update navigation modal
		updateStreamNavModal()
	end if
end sub

sub onPlayerStateChanged(obj)
	state = obj.getData()
	? "onPlayerStateChanged: "; state
	if state = "error"
		' Custom error message for stream errors
		errorMsg = "La transmisión no está disponible ahora. Inténtelo más tarde."
		showErrorDialog(errorMsg)
	else if state = "finished"
		closeVideo()
	end if
end sub

sub closeVideo()
	m.videoplayer.control = "stop"
	m.videoplayer.visible = false
	m.radio_bg_container.visible = false
	m.stream_nav_modal.visible = false
	m.tv_row.visible = true
	m.radio_row.visible = true
	m.live_row.visible = true
	
	' Reload feed from JSON (this will reset all carousels)
	loadFeed()
	
	' Reset to TV row at top
	m.currentRow = 0
	switchToRow(0)
end sub

sub onFeedError(obj)
	showErrorDialog(obj.getData())
end sub

sub showErrorDialog(message)
	m.error_dialog.title = "ERROR"
	m.error_dialog.message = message
	m.error_dialog.visible = true
	m.top.dialog = m.error_dialog
end sub

function onKeyEvent(key, press) as Boolean
	? "[home_scene] onKeyEvent", key, press
	
	' Handle stream navigation when video is playing
	if m.videoplayer.visible
		if key = "up" and press
			navigateToNextStream()
			return true
		else if key = "down" and press
			navigateToPrevStream()
			return true
		else if key = "back" and press
			closeVideo()
			return true
		end if
		return false
	end if
	
	' Handle row switching
	if key = "down" and press
		' Move to next row
		nextRow = m.currentRow + 1
		if nextRow > 2 ' We have 3 rows (0=TV, 1=Radio, 2=Live)
			nextRow = 2 ' Stop at last row
		end if
		if nextRow <> m.currentRow
			switchToRow(nextRow)
			return true
		end if
	end if
	
	if key = "up" and press
		' Move to previous row
		prevRow = m.currentRow - 1
		if prevRow < 0
			prevRow = 0 ' Stop at first row
		end if
		if prevRow <> m.currentRow
			switchToRow(prevRow)
			return true
		end if
	end if
	
	' Handle back button in menu - reload carousels
	if key = "back" and press
		' Reload feed from JSON to reset everything
		loadFeed()
		' Reset to TV row at top
		m.currentRow = 0
		switchToRow(0)
		return true
	end if
	
	return false
end function

sub resetBackFlag()
	' No longer needed - removed back button warning
end sub