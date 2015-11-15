require 'dp'
require 'src.nnetwork.utils.utilsFunction'
require 'gnuplot'
--TODO DELETE
require 'src.nnetwork.dpExtension.data.ParallelData'
require 'torch'   -- torch
--require 'xlua'    -- xlua provides useful tools, like progress bars
require 'optim'   -- an optimization package, for online and batch methods
require 'src.nnetwork.nnExtension.NoAvgBCECriterion1D'
require 'src.nnetwork.nnExtension.LinearInitFunction'
require 'src.nnetwork.nnExtension.DropableLayer'

require 'src.nnetwork.dpExtension.data.combinedDataWoDP'
require 'src.nnetwork.dpExtension.data.combinedDataChoiceWoDP'


cbFunc ={}
function cbFunc.createModel(opt,nLang,ninputs,nOutputs)
  --1.Layer of the network
  local model = nn.Sequential()
  local linLayer, concatModel,seqModel, dropoutLayer,actFunc

  concatModel = nn.Concat(2)
  seqModel = nn.Sequential()
  dropoutLayer = nn.DropableLayer(1)
  seqModel:add(dropoutLayer:clone())
  seqModel:add(nn.Linear(ninputs,opt.nHiddenLayer[1]))
  normalizedReset(seqModel.modules[2].weight,seqModel.modules[2],opt.nInit,opt.jInit)
  seqModel:add(nn[opt.actFunc[1]]())
  ----change initialization
  -----end here
  seqModel:add(dropoutLayer:clone())
  concatModel:add(seqModel)
  for i = 2,nLang do
    concatModel:add(seqModel:clone())
  end
  model:add(concatModel)
  concatModel,seqModel = nil,nil

  --  ----middle part
  --------  model:add(nn.View(nLang*opt.nHiddenLayer[1]))
  seqModel = nn.Sequential()
  linLayer = nn.Linear(opt.nHiddenLayer[1]*nLang, opt.nHiddenLayer[2])
  actFunc = nn[opt.actFunc[2]]()
  __ = opt.dropout and seqModel:add(nn.Dropout()) 
  seqModel:add(linLayer)
  normalizedReset(linLayer.weight,actFunc,opt.nInit,opt.jInit)
  seqModel:add(actFunc)
  __ = opt.dropout and seqModel:add(nn.Dropout()) 
  model:add(seqModel)
  ----change initialization
  ---end here
  --  --------3.Layer
  concatModel = nn.Concat(2)
  seqModel = nn.Sequential()
  seqModel:add(dropoutLayer:clone())
  seqModel:add(nn.Linear(opt.nHiddenLayer[2],opt.nHiddenLayer[3]))
  normalizedReset(seqModel.modules[2].weight,seqModel.modules[2],opt.nInit,opt.jInit)

  -----end here
  --  --
  seqModel:add(nn[opt.actFunc[3]]())
  seqModel:add(dropoutLayer:clone())
  concatModel:add(seqModel)
  --the more languages, the more models we need:
  for i = 2,nLang do
    concatModel:add(seqModel:clone())
  end
  model:add(concatModel)
  ------
  --  --------4.layer part
  --------  model:add(nn.View(nLang*opt.nHiddenLayer[3]))  --TODO Check possible error, and +1 for later layers
  linLayer = nn.Linear(opt.nHiddenLayer[3]*nLang, nOutputs)
  actFunc = nn.Sigmoid()
  model:add(linLayer)
  model:add(actFunc)
  normalizedReset(linLayer.weight,actFunc,opt.nInit,opt.jInit)

  return model
end
function cbFunc.createDeepModel(opt,nLang,ninputs,nOutputs)
  --1.Layer of the network
  local model = nn.Sequential()
  local linLayer, concatModel,seqModel, dropoutLayer,actFunc

  concatModel = nn.Concat(2)
  seqModel = nn.Sequential()
  dropoutLayer = nn.DropableLayer(1)
  seqModel:add(dropoutLayer:clone())
  seqModel:add(nn.Linear(ninputs,opt.nHiddenLayer[1]))
  seqModel:add(nn[opt.actFunc[1]]())
  normalizedReset(seqModel.modules[2].weight,seqModel.modules[2],opt.nInit,opt.jInit)
  -----end here
  seqModel:add(dropoutLayer:clone())
  concatModel:add(seqModel)
  for i = 2,nLang do
    concatModel:add(seqModel:clone())
  end
  model:add(concatModel)

  --  ----middle part
  --------  model:add(nn.View(nLang*opt.nHiddenLayer[1]))
  local seqModel = nn.Sequential()
  linLayer = nn.Linear(opt.nHiddenLayer[1]*nLang, opt.nHiddenLayer[1])
  actFunc = nn[opt.actFunc[2]]()
  __ = opt.dropout and seqModel:add(nn.Dropout()) 
  seqModel:add(linLayer)
  seqModel:add(actFunc)
  normalizedReset(linLayer.weight,actFunc,opt.nInit,opt.jInit)
  --ADDITIONAL MIDDLE layers---------------------------------------
  linLayer = nn.Linear(opt.nHiddenLayer[1], opt.nHiddenLayer[2])
  actFunc = nn[opt.actFunc[2]]()
  __ = opt.dropout and seqModel:add(nn.Dropout()) 
  seqModel:add(linLayer)
  seqModel:add(actFunc)
  normalizedReset(linLayer.weight,actFunc,opt.nInit,opt.jInit)
  --next Layer
  linLayer = nn.Linear(opt.nHiddenLayer[2], opt.nHiddenLayer[1])
  actFunc = nn[opt.actFunc[2]]()
  __ = opt.dropout and seqModel:add(nn.Dropout()) 
  seqModel:add(linLayer)
  seqModel:add(actFunc)
  normalizedReset(linLayer.weight,actFunc,opt.nInit,opt.jInit)
  __ = opt.dropout and seqModel:add(nn.Dropout()) 
  model:add(seqModel)

  ------------------------------------------------------------------
  ---end here
  --  --------3.Layer
  concatModel = nn.Concat(2)
  seqModel = nn.Sequential()
  seqModel:add(dropoutLayer:clone())
  seqModel:add(nn.Linear(opt.nHiddenLayer[1],opt.nHiddenLayer[3]))
  ----change initialization
  normalizedReset(seqModel.modules[2].weight,seqModel.modules[2],opt.nInit,opt.jInit)
  -----end here
  --  --
  seqModel:add(nn[opt.actFunc[3]]())
  seqModel:add(dropoutLayer:clone())
  concatModel:add(seqModel)
  --the more languages, the more models we need:
  for i = 2,nLang do
    concatModel:add(seqModel:clone())
  end
  model:add(concatModel)
  ------
  --  --------4.layer part
  linLayer = nn.Linear(opt.nHiddenLayer[3]*nLang, nOutputs)
  actFunc = nn.Sigmoid()
  model:add(linLayer)
  model:add(nn[opt.actFunc[4]]())
  ----change initialization
  normalizedReset(linLayer.weight,actFunc,opt.nInit,opt.jInit)
  return model
end

function cbFunc.createCombinedModelDP(opt,nLang,ninputs,nOutputs)
  --1.Layer of the network
  --  nOutputs = 5001
  useDPModel = true
  local model = nn.Sequential()
  local linLayer, concatModel,seqModel, dropoutLayer,actFunc

  concatModel = nn.Concat(3)
  seqModel = nn.Sequential()
  linLayer = nn.Linear(ninputs, opt.nHiddenLayer[1])
  seqModel:add(linLayer)
  seqModel:add(nn.Reshape(opt.nHiddenLayer[1],1,true))
  concatModel:add(seqModel)
  normalizedReset(linLayer.weight,actFunc,opt.nInit,opt.jInit)
  for i = 2,nLang do
    concatModel:add(seqModel:clone())
  end
  model:add(concatModel)
  model:add(nn.Select(3,1))
  --  ----middle part
  seqModel = nn.Sequential()

  actFunc = nn[opt.actFunc[1]]()
  seqModel:add(actFunc)

  linLayer = nn.Linear(opt.nHiddenLayer[1], opt.nHiddenLayer[2])
  actFunc = nn[opt.actFunc[2]]()
  __ = opt.dropout and seqModel:add(nn.Dropout()) 
  seqModel:add(linLayer)
  seqModel:add(actFunc)
  normalizedReset(linLayer.weight,actFunc,opt.nInit,opt.jInit)

  linLayer = nn.Linear(opt.nHiddenLayer[2], opt.nHiddenLayer[1])
  actFunc = nn[opt.actFunc[2]]()
  __ = opt.dropout and seqModel:add(nn.Dropout()) 
  seqModel:add(linLayer)
  seqModel:add(actFunc)
  model:add(seqModel)
  ----change initialization
  normalizedReset(linLayer.weight,actFunc,opt.nInit,opt.jInit)
  --
  --
  --  ------------------------------------------------------------------
  --  ---end here
  --  --  --------3.Layer
  concatModel = nn.Concat(3)
  seqModel = nn.Sequential()

  linLayer = nn.Linear(opt.nHiddenLayer[3], nOutputs)
  seqModel:add(linLayer)
  seqModel:add(nn.Reshape(nOutputs,1,true))
  ----change initialization
  normalizedReset(linLayer.weight,actFunc,opt.nInit,opt.jInit)
  concatModel:add(seqModel)
  --the more languages, the more models we need:
  for i = 2,nLang do
    concatModel:add(seqModel:clone())
  end
  model:add(concatModel)

  ------
  --  --------4.layer part
  model:add(nn.Select(3,1))
  model:add(nn[opt.actFunc[4]]())

  return model

end


--Check if one batch contains different kinds of datas
function cbFunc.homogenData(labelTensor)
  local lastElem
  for i = 1,labelTensor:size(1)  do
    x = labelTensor[i]
    lastElem = lastElem or x
    if (lastElem ~=x) then
      return false
    end
  end
  return true
end

--Shuffle only in batch-sized chunks, so the numbr of model forwards can be dramatically reduced
function cbFunc.reverseScheme(scheme)
  indices = torch.LongTensor():resizeAs(scheme)
  counter = 1
  scheme:apply(function(x) indices[x]= counter;counter = counter +1; return end)
  return indices
end
-- shuffle ignores the last ones (number = inputSize mod batchSize)
function cbFunc.shuffleSchemeBatch(batchSize,dataSize)

  local  maxIndex= math.floor(dataSize/batchSize)
  local shuffledIndex = torch.randperm(maxIndex)
  local startIndex = 1
  local indexTensor = torch.LongTensor(dataSize)
  local startLastBatch  =dataSize-(dataSize % batchSize) +1
  if (startLastBatch <=  dataSize) then
    indexTensor[{{startLastBatch,dataSize}}] = torch.range(startLastBatch,dataSize):index(1,torch.randperm(dataSize % batchSize):long())
  end
  shuffledIndex:apply(function(x)
    --modify indexTensor
    local startVal = (x-1) *batchSize +1
    local endVal = startVal+ batchSize -1
    local endIndex =startIndex + (endVal-startVal)
    --    print(startVal,endVal,startIndex,endIndex)
    indexTensor[{{startIndex,endIndex} }] =torch.range(startVal,endVal)
    startIndex = endIndex+1
    return end )
  --assert no duplicate
  --assert sum = gausformula
  assert(indexTensor:max()==dataSize)
  assert(indexTensor:min()== 1)
  assert(indexTensor:sum() == (dataSize*(dataSize+1)/2),indexTensor:sum()..' '..(dataSize*(dataSize+1)/2))
  return indexTensor

end
--Just some tests here
--cbFunc.shuffleSchemeBatch(10,840)

--print ('==> preparing switch/resetGater function')
function cbFunc.switchGater(model,srcLangID,trgLangID)
  if ( useDPModel) then
    assert (model.modules[2].index and model.modules[5].index )
    model.modules[2].index = srcLangID
    model.modules[5].index = trgLangID
  else
    --print(srcLangID,trgLangID)
    model.modules[1].modules[srcLangID].modules[1]:setp(0)
    model.modules[1].modules[srcLangID].modules[4]:setp(0)
    model.modules[3].modules[trgLangID].modules[1]:setp(0)
    model.modules[3].modules[trgLangID].modules[4]:setp(0)
  end
end
function cbFunc.resetGater(model,srcLangID,trgLangID)
  if ( useDPModel) then
  else
    model.modules[1].modules[srcLangID].modules[1]:setp(1)
    model.modules[1].modules[srcLangID].modules[4]:setp(1)
    model.modules[3].modules[trgLangID].modules[1]:setp(1)
    model.modules[3].modules[trgLangID].modules[4]:setp(1)
  end
end

function cbFunc.reorganizeData(inputs,targets,srcLabel,trgLabel)
  --get indices
  --reorganzize data into chunks of homogeneous data
  --?forward batch
  -- return a table of data to forward homogeneously
  local labelSwitchPos,lastSrcLabel,lastTrgLabel = {}
  for i = 1, srcLabel:size(1) do
    lastSrcLabel =lastSrcLabel or srcLabel[i]
    lastTrgLabel =lastTrgLabel or trgLabel[i]
    if ( srcLabel[i] ~= lastSrcLabel or trgLabel[i] ~=lastTrgLabel) then
      lastSrcLabel =srcLabel[i]
      lastTrgLabel =trgLabel[i]
      table.insert(labelSwitchPos,i-1)
    end
  end
  table.insert(labelSwitchPos,srcLabel:size(1))
  --------preparation done here. Start constructing resultTable
  local resultTable = {}
  _.map(labelSwitchPos,
    function (k,v)
      local input,target,srcSingleLabel,trgSingleLabel
      local startIndex = (k==1 and 1) or labelSwitchPos[k-1]+1
      local endIndex  = v
      --      print(startIndex,endIndex)
      local schema = torch.range(startIndex,endIndex):long()
      --            print(inputs)
      input = inputs:index(1, schema)
      target = targets:index(1, schema)
      srcSingleLabel = srcLabel[schema[1]]
      trgSingleLabel = trgLabel[schema[1]]
      table.insert(resultTable,{input,target,srcSingleLabel,trgSingleLabel})
      --      print(startIndex,endIndex,srcSingleLabel,trgSingleLabel)
      return
    end )
  --    table.print(resultTable)
  --        utils.printTable(resultTable)
  return resultTable --{input,output,srcLabel,trgLabel}
    --srcLabel = torch.ones(10)
    --srcLabel[3] = 2
    --srcLabel[4] = 3
    --srcLabel[7] = 4
    --trgLabel = torch.ones(10):mul(5)
    --trgLabel [6] = 6
    --local x = cbFunc.reorganizeData(torch.range(1,10),torch.range(11,20),srcLabel,trgLabel)
    --print()
    ----debug.debug()
end


function cbFunc.forwardHomogenBatch(model,crit,inputs,targets,srcLabel,trgLabel)
  cbFunc.switchGater(model,srcLabel,trgLabel)
  local outputs = model:forward(inputs)
  --  print('haee',outputs:size())
  ----    gnuplot.imagesc(outputs)
  --
  local err = crit:forward(outputs, targets) --ERR is divided by batch-Size
  cbFunc.resetGater(model,srcLabel,trgLabel)
  return err
end

function cbFunc.forBackwardHomogenBatch(model,crit,inputs,targets,srcLabel,trgLabel)
  cbFunc.switchGater(model,srcLabel,trgLabel)
  local outputs = model:forward(inputs)
  --  print('haee',outputs:size())
  ----    gnuplot.imagesc(outputs)
  --  debug.debug()
  local err = crit:forward(outputs, targets) --ERR is divided by batch-Size
  --        print(err)
  -- estimate df/dW
  local df_do = crit:backward(outputs, targets)
  --  print(df_do:size())
  --  print(outputs:size())
  --  gnuplot.imagesc(targets)
  --debug.debug()
  model:backward(inputs, df_do)
  --  reset model'gater (set Droptout = 100%)
  cbFunc.resetGater(model,srcLabel,trgLabel)
  return err
end

---- Gradients and error rates are not divided by Batchsize
function cbFunc.forBackwardBatch(gradParameter,model,crit,inputs,targets,srcLabel,trgLabel)
  --collectgarbage()

  --  assert(inputs:size(1) == targets:size(1))
  --  assert(inputs:size(1) == srcLabel:size(1))
  --  assert(srcLabel:size(1) == trgLabel:size(1))
  --check if batch homogen
  gradParameter:zero() --this is too dangerous, to be done somewhere else
  local fGradTable = {}
  if ( cbFunc.homogenData(srcLabel) and cbFunc.homogenData(trgLabel) )then
    --  if (not a) then-- cbFunc.homogenData(srcLabel) and cbFunc.homogenData(trgLabel) )then
    error = cbFunc.forBackwardHomogenBatch(model,crit,inputs,targets,srcLabel[1],trgLabel[1])
    table.insert(fGradTable,error)
  else
    --  print(srcLabel+trgLabel)
    --  debug.deug()
    local resultTable = cbFunc.reorganizeData(inputs,targets,srcLabel,trgLabel)
    for i = 1, #resultTable do
      error = cbFunc.forBackwardHomogenBatch(model,crit,unpack(resultTable[i]))
      table.insert(fGradTable,error)
    end
  end
  --    fGradTable = _.map(fGradTable,function(k,v) return {torch.sum(v[1],1),torch.sum(v[2],1)} end )
  --  local result = _.reduce(fGradTable,function(memo,v) return {memo[1]+v[1],memo[2]+v[2]}end)
  local fScore = _.reduce(fGradTable,function(memo,v) return memo+v end )
  return fScore --return f, gradParam --normalize  outside.
end
function cbFunc.testModel()
  local nLang = 3
  local ninputs = 5001
  local nOutputs = 5001
  --opt.nHiddenLayer = {12,6,12}
  opt={}
  opt.dropout =false
  opt.nHiddenLayer  = {1000,500,1000}
  opt.actFunc = {'Tanh','Tanh','Tanh','Sigmoid'}
  opt.jInit = true
  opt.nInit = true
  --  --1.Layer of the network
  --1.Layer of the network
  local model = nn.Sequential()
  local linLayer, concatModel,seqModel, dropoutLayer,actFunc

  concatModel = nn.Concat(2)
  seqModel = nn.Sequential()
  dropoutLayer = nn.DropableLayer(1)
  seqModel:add(dropoutLayer:clone())
  seqModel:add(nn.Linear(ninputs,opt.nHiddenLayer[1]))
  seqModel:add(nn[opt.actFunc[1]]())
  normalizedReset(seqModel.modules[2].weight,seqModel.modules[2],opt.nInit,opt.jInit)
  -----end here
  seqModel:add(dropoutLayer:clone())
  concatModel:add(seqModel)
  for i = 2,nLang do
    concatModel:add(seqModel:clone())
  end
  model:add(concatModel)

  --  ----middle part
  --------  model:add(nn.View(nLang*opt.nHiddenLayer[1]))
  local seqModel = nn.Sequential()
  linLayer = nn.Linear(opt.nHiddenLayer[1]*nLang, opt.nHiddenLayer[1])
  actFunc = nn[opt.actFunc[2]]()
  __ = opt.dropout and seqModel:add(nn.Dropout()) 
  seqModel:add(linLayer)
  seqModel:add(actFunc)
  normalizedReset(linLayer.weight,actFunc,opt.nInit,opt.jInit)
  --ADDITIONAL MIDDLE layers---------------------------------------
  linLayer = nn.Linear(opt.nHiddenLayer[1], opt.nHiddenLayer[2])
  actFunc = nn[opt.actFunc[2]]()
  __ = opt.dropout and seqModel:add(nn.Dropout()) 
  seqModel:add(linLayer)
  seqModel:add(actFunc)
  normalizedReset(linLayer.weight,actFunc,opt.nInit,opt.jInit)
  --next Layer
  linLayer = nn.Linear(opt.nHiddenLayer[2], opt.nHiddenLayer[1])
  actFunc = nn[opt.actFunc[2]]()
  __ = opt.dropout and seqModel:add(nn.Dropout()) 
  seqModel:add(linLayer)
  seqModel:add(actFunc)
  normalizedReset(linLayer.weight,actFunc,opt.nInit,opt.jInit)
  __ = opt.dropout and seqModel:add(nn.Dropout()) 
  model:add(seqModel)

  ------------------------------------------------------------------
  ---end here
  --  --------3.Layer
  concatModel = nn.Concat(2)
  seqModel = nn.Sequential()
  seqModel:add(dropoutLayer:clone())
  seqModel:add(nn.Linear(opt.nHiddenLayer[1],opt.nHiddenLayer[3]))
  ----change initialization
  normalizedReset(seqModel.modules[2].weight,seqModel.modules[2],opt.nInit,opt.jInit)
  -----end here
  --  --
  seqModel:add(nn[opt.actFunc[3]]())
  seqModel:add(dropoutLayer:clone())
  concatModel:add(seqModel)
  --the more languages, the more models we need:
  for i = 2,nLang do
    concatModel:add(seqModel:clone())
  end
  model:add(concatModel)
  ------
  --  --------4.layer part
  linLayer = nn.Linear(opt.nHiddenLayer[3]*nLang, nOutputs)
  actFunc = nn.Sigmoid()
  model:add(linLayer)
  model:add(nn[opt.actFunc[4]]())
  ----change initialization
  normalizedReset(linLayer.weight,actFunc,opt.nInit,opt.jInit)
  return model
end
--model = cbFunc.testModel()
--print(model)
--local srcLangLabel,trg  = 2,3
--cbFunc.switchGater(model,srcLangLabel,trg)
--inputs = torch.ones(30,5001)
--targets = torch.ones(30,5001)
----output =model:forward(inputs)
--local moduleOutput, moduleInput
--moduleInput = inputs
--for k,v in pairs(model.modules) do
--  moduleOutput = v:forward(moduleInput)
----  print(moduleOutput:size())
--  if ( k == 4) then 
--  gnuplot.imagesc(moduleOutput,'color')
--  gnuplot.plotflush()
--  print(moduleInput:size())
--  print(moduleOutput:size())
--  end
--  moduleInput = moduleOutput
--end
--local tabInput = {}
--for k,v in pairs(model.modules) do
--  table.insert(tabInput,moduleInput)
--  moduleOutput = v:forward(moduleInput)
--  print(moduleOutput:size())
--  if ( k == 4) then 
--  gnuplot.imagesc(moduleOutput,'color')
--  gnuplot.plotflush()
--  print(moduleInput:size())
--  print(moduleOutput:size())
--  end
--  moduleInput = moduleOutput
--end
----model:backward(output,targets)
--crit = nn.NoAvgBCECriterion1D()
--crit:forward(moduleOutput,targets)
--local df_do = crit:backward(moduleOutput,targets)
--  gnuplot.imagesc(df_do,'color')

--for k = 5,1,-1 do
--  print(k)
--  local v = model.modules[k]
--  moduleInput = tabInput[k]
----  print(v)
--  print(moduleInput:size())
--  df_do = v:backward(moduleInput,df_do)
----  print(moduleOutput:size())
--  if ( k == 4) then 
--  gnuplot.imagesc(df_do,'color')
--  gnuplot.plotflush()
----  print(moduleInput:size())
----  print(df_do:size())
--  end
--  moduleInput = moduleOutput
--end
--moduleInput = torch.randn(30,5001)
--df_do = torch.randn(30,1000)
--
--for k = 4,2,-1 do
--  local v = model.modules[1].modules[2].modules[k] --model.modules[3].modules[1].modules[4]
--  df_do = v:backward(moduleInput,df_do)
----  print(df_do:size())
--  if ( k ==2 ) then 
--  gnuplot.imagesc(df_do,'color')
--  gnuplot.plotflush()
----  print(moduleInput:size())
----  print(df_do:size())
--  end
--end
--srcLabel = torch.ones(30)
--trgLabel = torch.ones(30)
--srcLabel[10] =2
--err = cbFunc.forwardBatch(model,crit,inputs,targets,srcLabel,trgLabel) 
--print(err)
--p,g = model:getParameters()
--print(g:sum())
--gnuplot.imagesc(g,'color') 
--gnuplot.plot(df_do,'-')
--gnuplot.imagesc(df_do,'color') 