sub main()
	' Print information from Roku manifest
	app_info = createObject("roAppInfo")
	? "App Title: ", app_info.getTitle()
	device_info = createObject("roDeviceInfo")
	? "Model: ", device_info.getModel()
	display_size = device_info.getDisplaySize()
	? "Display Size: ", display_size.w;"x";display_size.h

	m.port = createObject("roMessagePort")
	screen = createObject("roSGScreen")
	screen.setMessagePort(m.port)
	scene = screen.createScene("home_scene")
	screen.Show()
	' this loop is necessary to keep the application open
	' otherwise the channel will exit when it reaches the end of main()
	while(true)
		msg = wait(0, m.port)
		msgType = type(msg)
		if msgType = "roSGScreenEvent"
			if msg.isScreenClosed() then return
		end if
	end while
end sub
