require 'torch'   -- torch
require 'optim'   -- an optimization package, for online and batch methods
require 'src.nnetwork.agDank.1_data'
require 'src.nnetwork.agDank.2_model'
require 'src.nnetwork.agDank.3_1_exp_func'

cmd = torch.CmdLine()
cmd:option('--maxEpoch',6000,'maximum number of epochs')
cmd:option('--dropout',false,'dropout in all layers')
cmd:option('--shuffle',true,'shuffle every epoch')
cmd:option('--cuda', false, 'use CUDA')
cmd:option('--optimization', 'SGD', 'optimization method: SGD | ASGD | CG | LBFGS')
cmd:option('--learningRate', 2, 'learning rate at t=0')
cmd:option('--batchSize', 10, 'mini-batch size (1 = pure stochastic)')
cmd:option('--weightDecay', 0, 'weight decay (SGD only)')
cmd:option('--momentum', 0.3, 'momentum (SGD only)')
cmd:text()
opt  = cmd:parse(arg or {})
print('******************************')
print('Parameters for given file: ')
table.print(opt)


if ( opt.cuda) then
  require 'cunn'
end
local datasource
-------------------------------------------------------------
datasource = Data{}



local model = modelType.model2()
local criterion = nn.BCECriterion()
--utils.printTable(model.modules)
-----------------------------------------------------------------
----------------------------------------------------------------
--Do the experiment
if (opt.cuda) then
  model:cuda()
  criterion:cuda()
end
local parameters,gradParameters = model:getParameters() 
----------------------------------------------------------------------
print '==> configuring optimizer'
optimState = {
  momentum = opt.momentum,
  learningRate = opt.learningRate,
}
print '==> defining training procedure'
function train()
  -- epoch tracker
  local shuffelSchema = torch.randperm( datasource.train.src:size(1)) :long()
  datasource.train.src =  datasource.train.src:index(1, shuffelSchema)
  datasource.train.trg =  datasource.train.trg:index(1, shuffelSchema)
  epoch = epoch or 1
  local fTable = {}
  model:training()
  ------------------------------------------------------------------------
  print('==> doing epoch on training data:')
  print("==> online epoch # " .. epoch .. ' [batchSize = ' .. opt.batchSize .. ']')

  local time = sys.clock()
  local nSamples = datasource.train.trg:size(1)
  for t = 1,nSamples,opt.batchSize do
    local batchSize = math.min(opt.batchSize, nSamples-t+1)
    local batch = {datasource.train.src:sub(t,t+batchSize-1),datasource.train.trg:sub(t,t+batchSize-1)}
    local feval = function(x)
      if x ~= parameters then
        parameters:copy(x)
      end
      gradParameters:zero()
      local f = forward(model,batch,criterion,opt.cuda,'do backprop')
      gradParameters:div(batchSize)
      return f,gradParameters
    end
    local ____,currentF = optim.sgd(feval, parameters, optimState)
    fTable = _.append(fTable,currentF)
    if(opt.testMode)then
      print('current batch error:', currentF[1])
    end
  end --End of for loop
  time = sys.clock() - time
  print("\n==>speed: " .. nSamples/time .. 'sample/sec')
  local loss = _.reduce(fTable,function(memo,v)  return memo+v*10 end  )/nSamples
  print("optimizer:loss avgError "..loss*100)
  epoch = epoch + 1
end
function evalData(batch,nSamples,valid)
  model:evaluate()
  local f = forward(model,batch,criterion,opt.cuda)
--  f = f/nSamples
  if ( valid )then
    optimalF = optimalF or math.huge
    print('validator:loss avgError '..f*100)
    -- /log current net
    if ( f< optimalF ) then
      optimalF =f
      local filename = './src/nnetwork/agDank/Data/Prod/model.th7'
      os.execute('mkdir -p ' .. sys.dirname(filename))
      print('==>Found mimimum, saving model to '..filename)
      torch.save(filename, model)
    end
  else
    print('tester:loss avgError '..f*100)
  end
end
function valid()
  local nSamples = datasource.valid.trg:size(1)
  local batch = {datasource.valid.src,datasource.valid.trg}--datasource.valid:sub(nSamples, 1)
  evalData(batch, nSamples, 'valid')
end
function test()
  local nSamples = datasource.test.trg:size(1)
  local batch = {datasource.test.src,datasource.test.trg}
  evalData(batch, nSamples)
end

for i = 1,opt.maxEpoch do
  train()
  valid()
  test()
end
