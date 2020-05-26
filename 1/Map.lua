Map = Class{}

TILE_BRICK = 1
TILE_EMPTY = 4

SCROLL_SPEED = 62

require 'util'

function Map:init()
    self.spritesheet = love.graphics.newImage('graphics/spritesheet.png')
    self.tileWidth = 16
    self.tileHeight = 16
    self.mapWidth = 30
    self.mapHeight = 28
    self.tiles = {}

    --track camera coordinates so we draw the right subsection of the map
    self.camX = 0
    self.camY = -3

    self.tileSprites = generateQuads(self.spritesheet, self.tileWidth, self.tileHeight)

    self.mapWidthPixels = self.mapWidth * self.tileWidth
    self.mapHeightPixels = self.mapHeight * self.tileHeight

   --draw sky
    for y = 1, self.mapHeight / 2 do
       for x = 1, self.mapWidth do
	  self:setTile(x, y, TILE_EMPTY)
       end
    end
    --draw ground
    for y = self.mapHeight / 2, self.mapHeight do
       for x = 1, self.mapWidth do
	  self:setTile(x, y, TILE_BRICK)
       end
    end
end

function Map:setTile(x, y, tile)
   self.tiles[(y - 1) * self.mapWidth + x] = tile
end

function Map:getTile(x, y)
   return self.tiles[(y - 1) * self.mapWidth + x]
end

function Map:update(dt)
   self.camX = self.camX + SCROLL_SPEED * dt -- simulate the camera to the right edge
end

function Map:render()
   for y = 1, self.mapHeight do
      for x = 1, self.mapWidth do
	 love.graphics.draw(self.spritesheet, self.tileSprites[self:getTile(x, y)], (x - 1) * self.tileWidth, (y - 1) * self.tileHeight)
      end
   end
end
