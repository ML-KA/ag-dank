require 'nn'
require 'dp'
require 'src.nnetwork.utils.utilsFunction'

------------------------------------------------------------------------
--[[ Data ]]--
--used for a combined architecture
------------------------------------------------------------------------

--
local Data = torch.class('Data')
function Data:__init(config)
 self:loadTrain()
end
function Data:loadTrain()
  --todo change 
  local  size  = 10000
    self.inputSize = 112  
  local saveSrc = './src/nnetwork/agDank/Data/Prod/src.th7.f'
  local saveTrg = './src/nnetwork/agDank/Data/Prod/trg.th7.f'
  local tensorSrc, tensorTrg =  torch.load(saveSrc,'binary'),torch.load(saveTrg,'binary')
  local nSample = tensorSrc:size(1)
  self.test = {["src"] = tensorSrc:narrow(1,nSample-size+1,size),  ["trg"] = tensorTrg:narrow(1,nSample-size+1,size)}
  self.valid = {["src"] = tensorSrc:narrow(1,nSample-2*size+1,size),  ["trg"] = tensorTrg:narrow(1,nSample-2*size+1,size)}
  self.train = {["src"] = tensorSrc:narrow(1,1,nSample-2*size),  ["trg"] = tensorTrg:narrow(1,1,nSample-2*size)}
  
  self._output_feature_size =1
end
function Data:loadDataFromFile  (file_name)
  local dataTensor = torch.load(file_name,'binary')
end
function Data:outputFeatureSize()
  return self._output_feature_size
end
function Data:inputFeatureSize()
  return self.inputSize
end




