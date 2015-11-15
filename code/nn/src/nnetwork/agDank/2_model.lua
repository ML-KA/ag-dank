require 'nn'
modelType= {}
function modelType.model1()
  local model = nn.Sequential()

  nHiddenLayer = {500}
  local ninputs,noutputs = 112,1
--  model:add(nn.Reshape(ninputs))
  nn.Dropout(0.2)
  model:add(nn.Linear(ninputs,nHiddenLayer[1]))
  model:add(nn.Tanh())
  ---nn.Dropout(0.5)
  model:add(nn.Linear(nHiddenLayer[1],noutputs))
  model:add(nn.Sigmoid())
  print(model)
  return model
end
function modelType.model2()
  local model = nn.Sequential()

  nHiddenLayer = {500,100,500}
  local ninputs,noutputs = 112,1
--  model:add(nn.Reshape(ninputs))
  nn.Dropout(0.2)
  model:add(nn.Linear(ninputs,nHiddenLayer[1]))
  model:add(nn.Tanh())
  model:add(nn.Linear(nHiddenLayer[1],nHiddenLayer[2]))
  model:add(nn.Tanh())
    
  model:add(nn.Dropout(0.5))
  model:add(nn.Linear(nHiddenLayer[2],nHiddenLayer[3]))
  model:add(nn.Tanh())
  model:add(nn.Dropout(0.5))
  model:add(nn.Linear(nHiddenLayer[3],noutputs))
  model:add(nn.Sigmoid())
  print(model)
  return model
end

--modelType.model1()
--modelType.model2()




