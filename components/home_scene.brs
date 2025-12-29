function init()
    ? "[home_scene] init"

    m.search_box = m.top.findNode("search_box")
    m.search_label = m.top.findNode("search_label")
    m.search_keyboard = m.top.findNode("search_keyboard")
    m.content_grid = m.top.findNode("content_grid")
    m.details_screen = m.top.findNode("details_screen")
    m.error_dialog = m.top.findNode("error_dialog")
    m.videoplayer = m.top.findNode("videoplayer")

    initializeVideoPlayer()

    m.search_keyboard.observeField("text", "onSearchTextChanged")
    m.content_grid.observeField("itemSelected", "onContentSelected")
    m.details_screen.observeField("play_button_pressed", "onPlayButtonPressed")

    m.allContent = invalid
    m.searchActive = true

    m.search_keyboard.visible = false
    m.search_label.text = "Search"
    m.search_label.color = "0x888888"

    m.search_box.setFocus(true)

    loadFeed()
end function

sub initializeVideoPlayer()
    m.videoplayer.EnableCookies()
    m.videoplayer.setCertificatesFile("common:/certs/ca-bundle.crt")
    m.videoplayer.InitClientCertificates()
    m.videoplayer.notificationInterval = 1
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
        m.allContent = data.items
        ? "Feed loaded with "; m.allContent.Count(); " items"

        populateGrid(m.allContent)
        m.content_grid.visible = true
        m.content_grid.setFocus(true)
    else
        showErrorDialog("Feed data malformed.")
    end if
end sub

sub onFeedError(obj)
    showErrorDialog(obj.getData())
end sub

sub populateGrid(items as Object)
    content = createObject("roSGNode", "ContentNode")

    for each item in items
        node = createContentNode(item)
        content.appendChild(node)
    end for

    m.content_grid.content = content
end sub

sub onSearchTextChanged()
    searchText = m.search_keyboard.text
    searchLower = LCase(searchText)

    if searchText <> ""
        m.search_label.text = searchText
        m.search_label.color = "0xFFFFFF"
    else
        m.search_label.text = "Search"
        m.search_label.color = "0x888888"
    end if

    if m.allContent = invalid then return

    filtered = createObject("roArray", 0, true)

    if searchText = ""
        for each item in m.allContent
            filtered.Push(item)
        end for
    else
        for each item in m.allContent
            titleMatch = Instr(1, LCase(item.title), searchLower) > 0
            descMatch = Instr(1, LCase(item.description), searchLower) > 0

            if titleMatch or descMatch
                filtered.Push(item)
            end if
        end for
    end if

    populateGrid(filtered)
end sub

function createContentNode(item as Object) as Object
    node = createObject("roSGNode", "ContentNode")
    node.streamformat = item.streamformat
    node.title = item.title
    node.url = item.url
    node.description = item.description
    node.HDGRIDPOSTERURL = item.thumbnail
    node.SHORTDESCRIPTIONLINE1 = item.title
    return node
end function

sub onContentSelected(obj)
    selected_index = obj.getData()
    m.selected_media = m.content_grid.content.getChild(selected_index)

    m.details_screen.content = m.selected_media
    m.content_grid.visible = false
    m.details_screen.visible = true
end sub

sub onPlayButtonPressed(obj)
    m.details_screen.visible = false
    m.videoplayer.visible = true
    m.videoplayer.setFocus(true)
    m.videoplayer.content = m.selected_media
    m.videoplayer.control = "play"
end sub

sub onPlayerStateChanged(obj)
    state = obj.getData()
    ? "onPlayerStateChanged: "; state

    if state = "error"
        showErrorDialog(m.videoplayer.errorMsg + chr(10) + "Error Code: " + m.videoplayer.errorCode.toStr())
    else if state = "finished"
        closeVideo()
    end if
end sub

sub closeVideo()
    m.videoplayer.control = "stop"
    m.videoplayer.visible = false
    m.content_grid.visible = true
    m.content_grid.setFocus(true)
end sub

sub showErrorDialog(message)
    m.error_dialog.title = "ERROR"
    m.error_dialog.message = message
    m.error_dialog.visible = true
    m.top.dialog = m.error_dialog
end sub

function onKeyEvent(key, press) as Boolean
    if key = "OK" and press
        if m.search_box.hasFocus()
            m.search_keyboard.visible = true
            m.search_keyboard.setFocus(true)
            return true
        end if
    end if

    if key = "back" and press
        if m.search_keyboard.visible
            m.search_keyboard.visible = false
            m.search_keyboard.text = ""
            m.search_label.text = "Search"
            m.search_label.color = "0x888888"
            m.search_box.setFocus(true)
            return true
        else if m.details_screen.visible
            m.details_screen.visible = false
            m.content_grid.visible = true
            m.content_grid.setFocus(true)
            return true
        else if m.videoplayer.visible
            closeVideo()
            return true
        end if
    end if

    return false
end function
