-- -----------------------------------------------------------------------------------------
-- --
-- -- main.lua
-- --
-- -----------------------------------------------------------------------------------------

-- Your code here





local admob = require( "plugin.admob" )
local myAppId = "ca-app-pub-4294781738729561~1944325413"
-- local myBannerAdUnitIdBottom = "ca-app-pub-4294781738729561/4811862023"
local myBannerAdUnitIdBottom = "ca-app-pub-3940256099942544/6300978111"





local gameStatus = 0

-- gameStatus = 0 -- se inicia el juego y se muestra el get ready
-- gameStatus = 1 -- se inicia el juego y se mueve el escenario
-- gameStatus = 2 -- se cambia el estado del juego a 2 y termina el juego todo se pausa cuando chocas
-- gameStatus = 3 -- se cambia el estado del juego a 3 y termina el juego todo se pausa cuando chocas  y puedes empezar de nuevo

local yLand = display.actualContentHeight - display.actualContentHeight*0.2
local hLand = display.actualContentHeight * 0.1
local xLand = display.contentCenterX

local yBird = display.contentCenterY-50
local xBird = display.contentCenterX-50

local wPipe = display.contentCenterX+40 -- con este numero da espacio de pixeles entre cada 3 pipes

local yReady = display.contentCenterY-140

local uBird = -200
local vBird = 0
local wBird = -320
local g = 800
local dt = 0.025

local score = 0
-- local score = 50
local bestScore = 0
local scoreStep = 5

local bird
local land
local title
local getReady
local gameOver
local emitter

local board
local scoreTitle
local bestTitle
local silver
local gold

local pipes = {}

local function loadSounds()
    dieSound = audio.loadSound( "Sounds/die.mp3" ) -- sonido de colision 
    hitSound = audio.loadSound( "Sounds/hit.mp3" ) -- sonido de choque contra el piso
    pointSound = audio.loadSound( "Sounds/point.mp3" ) -- sonido cuando pasas 5 pipes
    swooshingSound = audio.loadSound( "Sounds/swoosh.mp3" ) -- this sound is when init the game
    wingSound = audio.loadSound( "Sounds/flap.mp3" )  -- this sound is when bird is flying up and touch the screen
end

local function birdRandom ()
    local randomFolder = math.random(1, 2)
    local randomBird = math.random(1, 7)
    local birdImage = "Assets/FlappyBirdAssets/Player/StyleBird" .. randomFolder .. "/Bird_" .. randomBird .. ".png"
    return birdImage
end



local function calcRandomHole()
    local h = 100 + 20*math.random(4)
    -- local h = 100 + 20*math.random(10)
    print('----h -------', h)
    return h
end

local function loadBestScore()
    local path = system.pathForFile( "bestscore.txt", system.DocumentsDirectory )

    -- Open the file handle
    local file, errorString = io.open( path, "r" )

    if not file then
        -- Error occurred; output the cause
        print( "File error: " .. errorString )
    else
        print( "Contents of " .. path )
        -- Read data from file
        local contents = file:read( "*a" )
        print( 'contents' .. contents )
        -- Output the file contents
        bestScore = tonumber( contents )
        -- Close the file handle
        io.close( file )
    end
    print( "bestScore = ", bestScore )

    file = nil
end

local function saveBestScore()
-- Path for the file to write
    local path = system.pathForFile( "bestscore.txt", system.DocumentsDirectory )
    local file, errorString = io.open( path, "w" )
    if not file then
        -- Error occurred; output the cause
        print( "File error: " .. errorString )
    else
        file:write( bestScore )
        io.close( file )
    end
    file = nil
    -- show appodeal ad
    --  appodeal.show()
end


local function setupBird()
    local options =
    {
      width = 40,
      height = 40,
      numFrames = 4,
      sheetContentWidth = 160,  -- width of original 1x size of entire sheet
      sheetContentHeight = 40  -- height of original 1x size of entire sheet
    }
--   local imageSheet = graphics.newImageSheet( "Assets/bird.png", options )
    local imageSheet = graphics.newImageSheet(birdRandom(), options )

    local sequenceData = {
        name="walking",
        start=1,
        count=3,
        time=400,
        loopCount = 3,   -- Optional ; default is 0 (loop indefinitely)
        loopDirection = "forward"    -- Optional ; values include "forward" or "bounce"
    }


    bird = display.newSprite( imageSheet, sequenceData )
    bird.x = xBird
    bird.y = yBird
end

local function prompt(tempo)
  bird:play() -- mueve al ave al incio del juego solo recorre los sprites
end


local function initGame()
    score = 0
    scoreStep = 5
    title.text = score
    -- title.text = hLand

    for i=1,3 do
        local dx = 500 + display.contentCenterX * (i-1) -- solo son pipes de los 3 primeros
        -- local dx =  600 * i -- solo son pipes de los 3 primeros
        print('----dx -------', dx)
        pipes[i].x =  dx -- solo son pipes de los 3 primeros
        -- pipes[i].x = 800 + wPipe * (i-1)
        pipes[i].y =  calcRandomHole()
        -- aqui da los primeros 3 pipes la la altura de los huecos en y
        -- pipes[i].y = 10
    end
    yBird = display.contentCenterY-50
    xBird = display.contentCenterX-50
    getReady.y = 0
    getReady.alpha = 1
    gameOver.y = 0
    gameOver.alpha = 0
    board.y = 0
    board.alpha = 0
    audio.play( swooshingSound )
    transition.to( bird, { time=300, x=xBird, y=yBird, rotation = 0 } ) -- tranbsiscion de la posicion del pajaro
    transition.to( getReady, { time=600, y=yReady, transition=easing.outBounce, onComplete=prompt   } ) -- mueve el get ready al empezar el juego mas tiempo es mas lento
end


local function wing()
    if gameStatus==0 then
        gameStatus=1
        getReady.alpha = 0
    end

    if gameStatus==1 then
        vBird = wBird
        bird:play()
        audio.play( wingSound )
    end

    if gameStatus==3 then
        gameStatus=0
        initGame()
    end
end

local function  setupExplosion()
    local dx = 31
    local p = "Assets/habra.png"
    local emitterParams = {
            startParticleSizeVariance = dx/2,
            startColorAlpha = 0.61,
            startColorGreen = 0.3031555,
            startColorRed = 0.08373094,
            yCoordFlipped = 0,
            blendFuncSource = 770,
            blendFuncDestination = 1,
            rotatePerSecondVariance = 153.95,
            particleLifespan = 0.7237,
            tangentialAcceleration = -144.74,
            startParticleSize = dx,
            textureFileName = p,
            startColorVarianceAlpha = 1,
            maxParticles = 128,
            finishParticleSize = dx/3,
            duration = 0.75,
            finishColorRed = 0.078,
            finishColorAlpha = 0.75,
            finishColorBlue = 0.3699196,
            finishColorGreen = 0.5443883,
            maxRadiusVariance = 172.63,
            finishParticleSizeVariance = dx/2,
            gravityy = 220.0,
            speedVariance = 258.79,
            tangentialAccelVariance = -92.11,
            angleVariance = -300.0,
            angle = -900.11
        }
    emitter = display.newEmitter(emitterParams )
    emitter:stop()
end


local function explosion()
    emitter.x = bird.x
    emitter.y = bird.y
    emitter:start() -- sale una animacion de explosion
end




local function crash()
    gameStatus = 3
    audio.play( hitSound )

    -- muestra el texto de game over
    gameOver.y = 0
    gameOver.alpha = 1
    -- mueve el texto de game over
    transition.to( gameOver, { time=600, y=yReady, transition=easing.outBounce } )

    -- muestra el tablero de puntuacion
    board.y = 0
    board.alpha = 1

    -- saveScoreToVk()



    if score>bestScore then
        bestScore = score

        saveBestScore()
    end
    bestTitle.text = bestScore
    scoreTitle.text = score

    if score<10 then
        silver.alpha = 0
        gold.alpha = 0
    elseif score<50 then
        silver.alpha = 1
        gold.alpha = 0
    else
        silver.alpha = 0
        gold.alpha = 1
    end
    -- mueve el tablero de puntuacion hacia abajo
    transition.to( board, { time=600, y=yReady+100, transition=easing.outBounce } )
end

local function collision(i)
    -- print("------ collision 1 -----", i)
    -- print("------ collision 2 -----", i)
    local dx = 40 -- horizontal space of hole
    local dy = 50 -- vertical space of hole
    local boom = 0
    local x = pipes[i].x
    local y = pipes[i].y

    if xBird > (x-dx) and xBird < (x+dx) then
        if yBird > (y+dy) or yBird < (y-dy) then
            boom = 1
        end
    end
    return boom
end


local function gameLoop()
    -- local eps = 10
    local eps = 10
    local leftEdge = -60
    if gameStatus == 1 then
        xLand = xLand + dt * uBird
        if xLand<0 then
            xLand = display.contentCenterX*2+xLand -- mueve la parte de abajo y la repite
        end
        land.x = xLand -- aqui empueza a avanzar el escenario
        for i=1,3 do
            local xb = xBird-eps
            local xOld = pipes[i].x
            local x = xOld + dt * uBird
            -- print("------ xOld -----", xOld)
            -- print("------ x -----", x)

            if x<leftEdge then
                x = wPipe * 3 + x -- cada 3 pipes empieza de nuevo 
                -- x = wPipe
                pipes[i].y =  calcRandomHole()
                -- pipes[i].y = 10
            end
            if xOld > xb  and x <= xb then
                score = score + 1
                title.text = score
                if score==scoreStep then
                    scoreStep = scoreStep + 5
                    audio.play( pointSound )
                end
            end
            pipes[i].x = x
            -- print("------ collision -----", collision(i))
             -- collision(i) regresa un booleano si es 1 es que hubo colision si es 0 no hubo colision
            if collision(i) == 1 then
                explosion() -- si hay colision se activa la explosion
                audio.play( dieSound )
                gameStatus = 2 -- se cambia el estado del juego a 2 y termina el juego todo se pausa
            end
        end
    end
  
    if gameStatus == 1 or gameStatus == 2 then
        vBird = vBird + dt * g
        yBird = yBird + dt * vBird
        if yBird>yLand-eps then
            yBird = yLand-eps
            crash()
        end

        -- aqui se mueve el pajaro de arriva hacia abajo con el click
        bird.x = xBird
        bird.y = yBird

        -- este if es para que el pajaro se incline hacia abajo cuando cae o hacia arriba cuando sube
        if gameStatus==1 then
            bird.rotation =  -30*math.atan(vBird/uBird)
        else
            bird.rotation = vBird/8
        end
    end
end



local function setupLand()
    land = display.newImageRect( "Assets/land.png", display.actualContentWidth*2, hLand*2 )
    -- land = display.newImageRect( "Assets/FlappyBirdAssets/Tiles/Style1/TileStyle1.png", display.actualContentWidth*2, hLand*2 )
  
    land.x = xLand
    land.y = yLand+hLand
end


local function backgroundRandom ()
  local random = math.random(1, 10)
  local background = "Assets/FlappyBirdAssets/Background/Background" .. random .. ".png"
  return background
end



local function setupImages()
    
--   local ground = display.newImageRect( "Assets/ground.png", display.actualContentWidth, display.actualContentHeight )
    local ground = display.newImageRect( backgroundRandom() , display.actualContentWidth, display.actualContentHeight )

    ground.x = display.contentCenterX
    ground.y = display.contentCenterY
    ground:addEventListener("tap", wing)

    for i=1,3 do
        --   ToDo change image
        pipes[i] = display.newImageRect( "Assets/pipe.png", 80, 1000 )
        pipes[i].x = 440 + wPipe * (i-1)
        pipes[i].y = calcRandomHole()
    end

    getReady = display.newImageRect( "Assets/getready.png", 200, 60 )
    getReady.x = display.contentCenterX
    getReady.y = yReady
    getReady.alpha = 0

--   ToDo change image
    gameOver = display.newImageRect( "Assets/gameover.png", 200, 60 )
    gameOver.x = display.contentCenterX
    gameOver.y = 0
    gameOver.alpha = 0

    board = display.newGroup()
--   ToDo change image
    local img = display.newImageRect(board, "Assets/board.png", 240, 140 )

    scoreTitle = display.newText(board, score, 80, -18, "Assets/troika.otf", 21)
    scoreTitle:setFillColor( 0.75, 0, 0 )
    bestTitle = display.newText(board, bestScore, 80, 24, "Assets/troika.otf", 21)
    bestTitle:setFillColor( 0.75, 0, 0 )

    silver = display.newImageRect(board, "Assets/silver.png", 44, 44 )
    silver.x = -64
    -- silver.x = 0
    silver.y = 4

    gold = display.newImageRect(board, "Assets/gold.png", 44, 44 )
    gold.x = -64
    gold.y = 4

    board.x = display.contentCenterX
    board.y = 0
    board.alpha = 0

    local txt = {
        x=display.contentCenterX, y=60,
        text="",
        font="Assets/troika.otf",
        fontSize=35 }

    title = display.newText(txt)
    title:setFillColor( 1, 1, 1 )
end

display.setStatusBar( display.HiddenStatusBar )



local function adListener( event )
    local json = require( "json" )
    print('------------------------------------ adListener')
    print( json.prettify( event ) )

    if ( event.phase == "init" ) then  -- Successful initialization
        
        admob.load( "banner", { adUnitId = myBannerAdUnitIdBottom } )
        

        timer.performWithDelay( 8000, function()
           
            print('------------------------------------ show 2')
            admob.show( "banner", { y='bottom', bgColor = '#FFFFFF' } )
            print('------------------------------------ show 2')
        end )

    end
end



-- Start application point

setupImages()
setupBird()
setupExplosion()
setupLand()
initGame()
loadBestScore()
loadSounds()

gameLoopTimer = timer.performWithDelay( 25, gameLoop, 0 ) 
admob.init( adListener, { appId=myAppId } )


