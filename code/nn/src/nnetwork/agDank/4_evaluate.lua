require 'torch'   -- torch
require 'optim'   -- an optimization package, for online and batch methods
require 'src.nnetwork.agDank.1_data'
require 'src.nnetwork.agDank.2_model'
require 'src.nnetwork.agDank.3_1_exp_func'

  require 'cunn'
local datasource
-------------------------------------------------------------
datasource = Data{}
local model = torch.load('./src/nnetwork/agDank/Data/Prod/model.th7')
local outputTensor = model:forward(datasource.test.src:cuda()):round()
utils.writeNNOutputToMatrixFormat(outputTensor,'./src/nnetwork/agDank/Data/Prod/output2.txt',0)
