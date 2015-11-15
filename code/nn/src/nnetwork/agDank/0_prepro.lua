_= require 'src/nnetwork/utils/moses'
allen = require 'src/nnetwork/utils/allen'
require 'src/nnetwork/utils/utilsFunction'
require 'src/nnetwork/utils/underscore'

local function readNetWorkOutput(filePath)
  print(filePath)
  local content = allen.lines(io.open(filePath,'r'):read('*all'))
  local counter = 0
  content =  _.map(content,function (k,v) local splitLine = allen.chars(v) 
  counter = counter +1
  print(counter/935053 *100)
  if ( counter %100000 == 0 ) then collectgarbage() end
  return splitLine end)
  return torch.Tensor(content)
end
local filePathSrc = './src/nnetwork/agDank/Data/Given/src'
local filePathTrg = './src/nnetwork/agDank/Data/Given/trg'
local saveSrc = './src/nnetwork/agDank/Data/Prod/src.th7'
local saveTrg = './src/nnetwork/agDank/Data/Prod/trg.th7'
x = readNetWorkOutput(filePathSrc):narrow(1,1,30000):clone()
torch.save(saveSrc,x)
x = readNetWorkOutput(filePathTrg):narrow(1,1,30000):clone()
torch.save(saveTrg,x)



