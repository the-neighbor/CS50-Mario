Player = Class{}

require 'Animation'

local MOVE_SPEED = 80
local JUMP_VELOCITY = 400
local GRAVITY = 40


function Player:init(map)
    self.width = 16
    self.height = 20

    self.x = map.tileWidth * 10
    self.onGround = map.tileHeight * (map.mapHeight / 2 - 1) - self.height
    self.y = self.onGround

    self.texture = love.graphics.newImage('graphics/blue_alien.png')
    self.frames = generateQuads(self.texture, 16, 20)

    self.state = 'idle'
    self.map = map
    self.direction = 'right'
    self.dx = 0
    self.dy = 0

    self.animations = {
        ['idle'] = Animation {
            texture = self.texture,
            frames = {self.frames[1]},
            interval = 1
        },
        ['walking'] = Animation {
            texture = self.texture,
            frames = {
                self.frames[9], self.frames[10], self.frames[11]
            },
            interval = 0.15
        },
        ['jumping'] = Animation {
            texture = self.texture,
            frames = {self.frames[3]},
            interval = 1
        }
    }

    self.animation = self.animations['idle']
    
    self.behaviors = {
        ['idle'] = function(dt)
            self:movement(dt)
            self.animation = self.animations['idle']
            self:jumpAbility(dt)
        end,
        ['walking'] = function(dt)
            self:movement(dt)
            self.animation = self.animations['walking']
            self:jumpAbility(dt)
        end,
        ['jumping'] = function(dt)
            self:airMovement(dt)
            self.dy = self.dy + GRAVITY
            if self.y >= self.onGround then
                self.y = self.onGround
                self.dy = 0
                self.state = 'idle'
            end
        end
    }
end

function Player:jumpAbility(dt)
    if love.keyboard.wasPressed('space') then
        self.dy = -JUMP_VELOCITY
        self.state = 'jumping'
        self.animation = self.animations['jumping']
    end
end

function Player:airMovement(dt)
    if love.keyboard.isDown('a') then
        self.dx = -MOVE_SPEED
        self.direction = 'left'
    elseif love.keyboard.isDown('d') then
        self.dx = MOVE_SPEED
        self.direction = 'right'
    else
        self.dx = 0
    end
end

function Player:movement(dt)
    if love.keyboard.isDown('a') then
        self.dx = -MOVE_SPEED
        self.state = "walking"
        self.direction = 'left'
    elseif love.keyboard.isDown('d') then
        self.dx = MOVE_SPEED
        self.state = "walking"
        self.direction = 'right'
    else
        self.state = "idle"
        self.dx = 0
    end
end

function Player:update(dt)
    self.behaviors[self.state](dt)
    self.animation:update(dt)
    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt

    if self.dy < 0 then
        -- if dy is negative the player is moving upwards or jumping
        -- this is when we check for collisions with overhead boxes
        if self.map:tileAt(self.x, self.y) ~= TILE_EMPTY or
        self.map:tileAt(self.x + self.width - 1, self.y) ~= TILE_EMPTY then
        -- if the upper left or upper right corner intersects a non empty tile
        -- reset y velocity
        self.dy = 0
        end
        --if upper left intersects with a jump block, change it to the hit version
        if self.map:tileAt(self.x, self.y) == JUMP_BLOCK then
            self.map:setTile(math.floor(self.x/self.map.tileWidth) + 1,
            math.floor(self.y / self.map.tileHeight) + 1, JUMP_BLOCK_HIT)
        end
        if self.map:tileAt(self.x + self.width - 1, self.y) == JUMP_BLOCK then
            self.map:setTile(math.floor((self.x + self.width - 1) / self.map.tileWidth) + 1,
            math.floor(self.y / self.map.tileHeight) + 1, JUMP_BLOCK_HIT)
        end
    end
end

function Player:render()
    local scaleX = 1
    if self.direction == 'right' then
        scaleX = 1
    elseif self.direction == 'left' then
        scaleX = -1
    end
    love.graphics.draw(self.texture, self.animation:getCurrentFrame(),
     math.floor(self.x + self.width / 2), math.floor(self.y + self.height / 2),
     0, scaleX, 1,
     self.width / 2, self.height / 2
    )
end