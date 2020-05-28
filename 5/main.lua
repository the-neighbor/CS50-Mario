Class = require 'class'
push = require 'push'

require 'Map'
require 'util'

-- actual window resolution
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

-- virtual resolution used for our raster/framebuffer
VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243


function love.load()
    --load/initialize our game.
    math.randomseed(os.time())

    map = Map() --set the map object to be an instance of our Map class

    love.graphics.setDefaultFilter('nearest', 'nearest') -- enable nearest neighbor scaling

    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = false,
        vsync = true
    }) --use the push library to set up our 720p window with our virtual raster 
end

function love.update(dt)
    --update our game each frame
    map:update(dt)
end

function love.draw()
    --draw the current state of our game to the window
    
    push:apply('start') -- start the call to our push library
    love.graphics.translate(math.floor(-map.camX), math.floor(-map.camY))
    love.graphics.clear(108/255, 140/255, 1,1) -- clear our window out with a sky blue color
    map:render() -- render our current map object
    push:apply('end') -- end the call to our push library
end
