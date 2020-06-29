Map = Class{}

TILE_BRICK = 1
TILE_EMPTY = -1

-- cloud tiles
CLOUD_LEFT = 6
CLOUD_RIGHT = 7

-- bush tiles
BUSH_LEFT = 2
BUSH_RIGHT = 3

-- mushroom tiles
MUSHROOM_TOP = 10
MUSHROOM_BOTTOM = 11

-- jump block
JUMP_BLOCK = 5
JUMP_BLOCK_HIT = 9


SCROLL_SPEED = 62

require 'util'
require 'Player'

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

   -- clear out map
   for y = 1, self.mapHeight do
       for x = 1, self.mapWidth do
	   self:setTile(x, y, TILE_EMPTY)
       end
   end
   -- generate map
   self:generate()
   -- add player
   self.player = Player(self)

end

function Map:tileAt(x, y)
   -- finds what kind of tile is at a particular x/y pixel location on the map
   return self:getTile(math.floor(x / self.tileWidth) + 1, math.floor(y /self.tileWidth) + 1)
end

function Map:setTile(x, y, tile)
   self.tiles[(y - 1) * self.mapWidth + x] = tile
end

function Map:getTile(x, y)
   return self.tiles[(y - 1) * self.mapWidth + x]
end

function Map:placeCloud(x)
   local cloudY = math.random(self.mapHeight / 2 - 6) -- random height at least 6 tiles up
   self:setTile(x, cloudY, CLOUD_LEFT)
   self:setTile(x + 1, cloudY, CLOUD_RIGHT)
end

function Map:placeMushroom(x)
   self:setTile(x, self.mapHeight / 2 - 2, MUSHROOM_TOP)
   self:setTile(x, self.mapHeight / 2 - 1, MUSHROOM_BOTTOM)
   self:placeGround(x)
   self:placeGround(x + 1)
end

function Map:placeBush(x)
   local bushY = self.mapHeight / 2 - 1
   self:setTile(x, bushY, BUSH_LEFT)
   self:setTile(x + 1, bushY, BUSH_RIGHT)
   self:placeGround(x)
   self:placeGround(x + 1)
end

function Map:placeGround(x)
   for y = self.mapHeight / 2, self.mapHeight do
      self:setTile(x, y, TILE_BRICK)
   end
end

function Map:generate()
   local x = 1
   while x < self.mapWidth do
      -- use rng to determine what function to call
      -- to generate the current column of the map
      if x < self.mapWidth - 2 and math.random(20) == 1 then
         -- if we're at least two tiles from the edge
         -- there's a 1 in 20 chance of generating a cloud
         self:placeCloud(x)
      end
      if math.random(20) == 1 then
         -- 1 in 20 chance of mushroom
         self:placeMushroom(x)
      elseif math.random(10) == 1 and x < self.mapWidth - 3 then
         -- else a 1 in 10 chance of a bush if we're a safe distance from the edge
         self:placeBush(x)
         x = x + 1
      else
         if math.random(15) == 1 then
            -- 1 in 15 chance of creating a block, if th
            self:setTile(x, self.mapHeight / 2 - 4, JUMP_BLOCK)
         end
      end
      self:placeGround(x)
      x = x + 1
   end
end

function Map:update(dt)
   local playerCenteredCamX = self.player.x - VIRTUAL_WIDTH / 2
   self.camX = clamp(playerCenteredCamX, 0, self.mapWidthPixels - VIRTUAL_WIDTH)
   self.camX = math.floor(self.camX)
   self.player:update(dt)
end

function Map:render()
   for y = 1, self.mapHeight do
      for x = 1, self.mapWidth do
         local value = self:getTile(x, y)
         if value >= 0 then
            love.graphics.draw(self.spritesheet, self.tileSprites[value], (x - 1) * self.tileWidth, (y - 1) * self.tileHeight)
         end
      end
   end
   self.player:render()
end
