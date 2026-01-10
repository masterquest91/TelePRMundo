function init()
	? "[home_scene] init"

	m.tv_carousel = m.top.findNode("tv_carousel")
	m.radio_carousel = m.top.findNode("radio_carousel")
	m.preview_thumbnail = m.top.findNode("preview_thumbnail")
	m.preview_title = m.top.findNode("preview_title")
	m.preview_description = m.top.findNode("preview_description")
	m.radio_background = m.top.findNode("radio_background")
	m.error_dialog = m.top.findNode("error_dialog")
	m.videoplayer = m.top.findNode("videoplayer")
	
	initializeVideoPlayer()
	
	m.tv_carousel.observeField("itemFocused", "onTVFocusChanged")
	m.tv_carousel.observeField("itemSelected", "onTVSelected")
	m.radio_carousel.observeField("itemFocused", "onRadioFocusChanged")
	m.radio_carousel.observeField("itemSelected", "onRadioSelected")

	' Store content and state
	m.tvContent = invalid
	m.radioContent = invalid
	m.tvFocusIndex = 0
	m.radioFocusIndex = 0
	m.currentCarousel = "tv"
	m.currentThumbnail = ""
	
	' Set initial focus to TV carousel
	m.tv_carousel.setFocus(true)

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
		
		' Separate TV and Radio items based on ID prefix
		tvItems = []
		radioItems = []
		
		for each item in data.items
			if item.id <> invalid
				itemId = LCase(item.id)
				if Left(itemId, 3) = "tv-"
					tvItems.Push(item)
				else if Left(itemId, 6) = "radio-"
					radioItems.Push(item)
				end if
			end if
		end for
		
		? "TV items: "; tvItems.Count()
		? "Radio items: "; radioItems.Count()
		
		' Store for later use
		m.tvContent = tvItems
		m.radioContent = radioItems
		
		' Display carousels
		displayCarousels()
		
		' Update preview with first TV item
		if tvItems.Count() > 0
			updatePreview(tvItems[0])
		end if
	else
		showErrorDialog("Feed data malformed.")
	end if
end sub

sub displayCarousels()
	' Create TV carousel content
	if m.tvContent <> invalid and m.tvContent.Count() > 0
		tvContent = createObject("roSGNode", "ContentNode")
		
		for each item in m.tvContent
			node = createObject("roSGNode", "ContentNode")
			node.title = item.title
			node.HDPosterUrl = item.thumbnail
			node.HDGRIDPOSTERURL = item.thumbnail
			tvContent.appendChild(node)
		end for
		
		m.tv_carousel.content = tvContent
	end if
	
	' Create Radio carousel content
	if m.radioContent <> invalid and m.radioContent.Count() > 0
		radioContent = createObject("roSGNode", "ContentNode")
		
		for each item in m.radioContent
			node = createObject("roSGNode", "ContentNode")
			node.title = item.title
			node.HDPosterUrl = item.thumbnail
			node.HDGRIDPOSTERURL = item.thumbnail
			radioContent.appendChild(node)
		end for
		
		m.radio_carousel.content = radioContent
	end if
end sub

function createCarouselNode(item as Object) as Object
	node = createObject("roSGNode", "ContentNode")
	
	' Create markup with black background
	markup = "<Poster uri='" + item.thumbnail + "' width='400' height='280' loadDisplayMode='scaleToFit'/>"
	
	node.title = item.title
	node.HDPosterUrl = item.thumbnail
	node.streamformat = item.streamformat
	node.url = item.url
	node.description = item.description
	
	return node
end function

sub onTVFocusChanged(obj)
	focusedIndex = obj.getData()
	? "TV focus changed to: "; focusedIndex
	m.currentCarousel = "tv"
	m.tvFocusIndex = focusedIndex
	
	if m.tvContent <> invalid and focusedIndex >= 0 and focusedIndex < m.tvContent.Count()
		updatePreview(m.tvContent[focusedIndex])
	end if
end sub

sub onTVSelected(obj)
	? "TV item selected"
	playSelectedItem("tv")
end sub

sub onRadioFocusChanged(obj)
	focusedIndex = obj.getData()
	? "Radio focus changed to: "; focusedIndex
	m.currentCarousel = "radio"
	m.radioFocusIndex = focusedIndex
	
	if m.radioContent <> invalid and focusedIndex >= 0 and focusedIndex < m.radioContent.Count()
		updatePreview(m.radioContent[focusedIndex])
	end if
end sub

sub onRadioSelected(obj)
	? "Radio item selected"
	playSelectedItem("radio")
end sub

sub updatePreview(item as Object)
	' Update preview area with selected item details
	m.preview_thumbnail.uri = item.thumbnail
	m.preview_title.text = item.title
	m.preview_description.text = item.description
	m.currentThumbnail = item.thumbnail
	
	' Adjust title font size if it wraps
	m.preview_title.font = "font:LargeBoldSystemFont"
	if m.preview_title.numLines > 1
		m.preview_title.font = "font:MediumBoldSystemFont"
	end if
	
	' Adjust description font size if it exceeds bounds
	m.preview_description.font = "font:MediumSystemFont"
	' Check if content exceeds the available height (220px)
	' Note: Roku doesn't provide exact height measurement, so we use line count as proxy
	if m.preview_description.numLines > 8
		m.preview_description.font = "font:SmallSystemFont"
	end if
end sub

sub playSelectedItem(carouselType as String)
	selectedItem = invalid
	if carouselType = "tv" and m.tvContent <> invalid
		selectedItem = m.tvContent[m.tvFocusIndex]
	else if carouselType = "radio" and m.radioContent <> invalid
		selectedItem = m.radioContent[m.radioFocusIndex]
	end if
	
	if selectedItem <> invalid
		' Create content node for playback
		playContent = createObject("roSGNode", "ContentNode")
		playContent.url = selectedItem.url
		playContent.streamformat = selectedItem.streamformat
		playContent.title = selectedItem.title
		
		' Show thumbnail background for radio streams
		if carouselType = "radio"
			m.radio_background.uri = selectedItem.thumbnail
			m.radio_background.visible = true
		else
			m.radio_background.visible = false
		end if
		
		m.tv_carousel.visible = false
		m.radio_carousel.visible = false
		m.videoplayer.visible = true
		m.videoplayer.setFocus(true)
		m.videoplayer.content = playContent
		m.videoplayer.control = "play"
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
	m.radio_background.visible = false
	m.tv_carousel.visible = true
	m.radio_carousel.visible = true
	
	' Return focus to the last active carousel
	if m.currentCarousel = "tv"
		m.tv_carousel.setFocus(true)
	else
		m.radio_carousel.setFocus(true)
	end if
end sub

sub showErrorDialog(message)
	m.error_dialog.title = "ERROR"
	m.error_dialog.message = message
	m.error_dialog.visible = true
	m.top.dialog = m.error_dialog
end sub

function onKeyEvent(key, press) as Boolean
	? "[home_scene] onKeyEvent", key, press
	
	if key = "left" and press
		if m.currentCarousel = "tv" and m.tvContent <> invalid
			' Loop carousel to the left
			m.tvFocusIndex = m.tvFocusIndex - 1
			if m.tvFocusIndex < 0
				m.tvFocusIndex = m.tvContent.Count() - 1
			end if
			m.tv_carousel.jumpToItem = m.tvFocusIndex
			return true
		else if m.currentCarousel = "radio" and m.radioContent <> invalid
			m.radioFocusIndex = m.radioFocusIndex - 1
			if m.radioFocusIndex < 0
				m.radioFocusIndex = m.radioContent.Count() - 1
			end if
			m.radio_carousel.jumpToItem = m.radioFocusIndex
			return true
		end if
	end if
	
	if key = "right" and press
		if m.currentCarousel = "tv" and m.tvContent <> invalid
			' Loop carousel to the right
			m.tvFocusIndex = m.tvFocusIndex + 1
			if m.tvFocusIndex >= m.tvContent.Count()
				m.tvFocusIndex = 0
			end if
			m.tv_carousel.jumpToItem = m.tvFocusIndex
			return true
		else if m.currentCarousel = "radio" and m.radioContent <> invalid
			m.radioFocusIndex = m.radioFocusIndex + 1
			if m.radioFocusIndex >= m.radioContent.Count()
				m.radioFocusIndex = 0
			end if
			m.radio_carousel.jumpToItem = m.radioFocusIndex
			return true
		end if
	end if
	
	if key = "up" and press
		if m.currentCarousel = "tv"
			' Loop from TV to Radio
			m.radio_carousel.setFocus(true)
			m.radio_carousel.jumpToItem = m.radioFocusIndex
			m.currentCarousel = "radio"
			return true
		else if m.currentCarousel = "radio"
			' Loop from Radio to TV
			m.tv_carousel.setFocus(true)
			m.tv_carousel.jumpToItem = m.tvFocusIndex
			m.currentCarousel = "tv"
			return true
		end if
	end if
	
	if key = "down" and press
		if m.currentCarousel = "tv"
			' Loop from TV to Radio
			m.radio_carousel.setFocus(true)
			m.radio_carousel.jumpToItem = m.radioFocusIndex
			m.currentCarousel = "radio"
			return true
		else if m.currentCarousel = "radio"
			' Loop from Radio to TV
			m.tv_carousel.setFocus(true)
			m.tv_carousel.jumpToItem = m.tvFocusIndex
			m.currentCarousel = "tv"
			return true
		end if
	end if
	
	if key = "OK" and press
		' Play the selected item directly
		if m.currentCarousel = "tv"
			playSelectedItem("tv")
		else if m.currentCarousel = "radio"
			playSelectedItem("radio")
		end if
		return true
	end if
	
	if key = "back" and press
		if m.videoplayer.visible
			closeVideo()
			return true
		end if
	end if
	
	return false
end function