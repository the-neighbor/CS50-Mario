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

    self.sounds = {
        ['jump'] = love.audio.newSource('sounds/jump.wav', 'static'),
        ['hit'] = love.audio.newSource('sounds/hit.wav', 'static'),
        ['coin'] = love.audio.newSource('sounds/coin.wav', 'static')
    }

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
            self:movement(dt) -- lateral movement
            self.animation = self.animations['idle']
            self:jumpAbility(dt)
        end,
        ['walking'] = function(dt)
            self:movement(dt) -- lateral movement
            self.animation = self.animations['walking']
            self:jumpAbility(dt)
        end,
        ['jumping'] = function(dt)
            self:airMovement(dt)
            self.dy = self.dy + self.map.gravity
            
            if self.map:collides(self.map:tileAt(self.x, self.y + self.height)) or
            self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y +  self.height)) then
    
            --if one is there / colliding with the two bottom cornersfile:
            --reset velocity and position and change state
                self.dy = 0
                self.state = 'idle'
                self.animation = self.animations['idle']
                self.y = (self.map:tileAt(self.x, self.y + self.height).y - 1) * self.map.tileHeight - self.height
            end
        end
    }
end

function Player:jumpAbility(dt)
    if love.keyboard.wasPressed('space') then
        self.sounds['jump']:play()
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
    
    -- while moving laterally, check for collisions to the left and right
    self:checkRightCollision()
    self:checkLeftCollision()
end

--COLLISION CHECKING FUNCTIONS

function Player:checkLeftCollision()
    if self.dx < 0 then
        --if the player is moving to the left
        --check the two left corners of the bounding box for collisions
        if self.map:collides(self.map:tileAt(self.x - 1, self.y)) or 
            self.map:collides(self.map:tileAt(self.x - 1, self.y + self.height - 1)) then
            
            --first checked the top left, then the bottom left corner
            --if either are colliding with a 'solid' tile, then reset velocity
            self.dx = 0
            --and adjust the x value of the player to 
            --make sure we aren't partially in the tile
            self.x = self.map:tileAt(self.x - 1, self.y).x * self.map.tileWidth
            --this line of code puts the origin of the player 
            --right at the start of the next tiled
            self.state = 'idle'
            self.animation  = self.animations['idle']
        end
    end
end


function Player:checkRightCollision()
    if self.dx > 0 then
        --if the player is moving to the right
        --check the two right corners of the bounding box for collisions
        if self.map:collides(self.map:tileAt(self.x + self.width, self.y)) or 
            self.map:collides(self.map:tileAt(self.x + self.width, self.y + self.height - 1)) then
            
            --first checked the top right, then the bottom right corner
            --if either are colliding with a 'solid' tile, then reset velocity
            self.dx = 0
            --and adjust the x value of the player to 
            --make sure we aren't partially in the tile
                self.x = (self.map:tileAt(self.x + self.width, self.y).x - 1) * self.map.tileWidth - self.width
            --this line of code puts the origin of the player 
            --right at the start of the previous tile
                self.state = 'idle'
                self.animation  = self.animations['idle']
        end
    end
end

function Player:checkBottomCollision()
    if not self.map:collides(self.map:tileAt(self.x, self.y + self.height)) and
        not self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y +  self.height)) then
        
        self.state = 'jumping'
        self.animation = self.animations['jumping']
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

    -- while moving laterally, check for collisions to the left and right
    self:checkRightCollision()
    self:checkLeftCollision()

    --check for collisions below
    self:checkBottomCollision()


end

function Player:update(dt)
    self.behaviors[self.state](dt)
    self.animation:update(dt)
    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt

    if self.dy < 0 then
        -- if dy is negative the player is moving upwards or jumping
        -- this is when we check for collisions with overhead boxes
        if self.map:tileAt(self.x, self.y).id ~= TILE_EMPTY or
        self.map:tileAt(self.x + self.width - 1, self.y).id ~= TILE_EMPTY then
        -- if the upper left or upper right corner intersects a non empty tile
        -- reset y velocity
            self.dy = 0

            local playCoin = false
            local playHit = false
        --if upper left intersects with a jump block, change it to the hit version
            if self.map:tileAt(self.x, self.y).id == JUMP_BLOCK then
                self.map:setTile(math.floor(self.x/self.map.tileWidth) + 1,
                math.floor(self.y / self.map.tileHeight) + 1, JUMP_BLOCK_HIT)
                --record the appropriate sfx to play
                playCoin = true
            else
                playHit = true
            end
            if self.map:tileAt(self.x + self.width - 1, self.y).id == JUMP_BLOCK then
                --if the upper right corner of the player intersects a block
                self.map:setTile(math.floor((self.x + self.width - 1) / self.map.tileWidth) + 1,
                math.floor(self.y / self.map.tileHeight) + 1, JUMP_BLOCK_HIT)
                --change to the hit block sprite and take note of the appropriate sfx.
                playCoin = true
            else
                playHit = true
            end
            
            if playCoin then
                self.sounds['coin']:play()
            end
            if playHit then
                self.sounds['hit']:play()
            end
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