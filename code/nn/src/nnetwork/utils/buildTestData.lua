require 'dp'
require 'src/nnetwork/utils/utilsFunction'


function reduceAndSave(oldFile,newFile)
  local oldTensor = torch.load(oldFile,'csr')
  local newSize = math.ceil(oldTensor:size(1) * opt.dataRatio)
  oldTensor  = oldTensor[{{1,newSize},{}}]
  torch.save(newFile,utils.toCSR(oldTensor))
  print(newFile)
  collectgarbage()
  return
end


--local cmd = torch.CmdLine()
--cmd:option('fileSrc','/home/ductam/testData/model/deenfr', 'path to files')
--cmd:option('fileTrg','/home/ductam/testData/model/reduced_deenfr', 'where  to save new files')
--cmd:option('dataRatio',0.01, 'ratio of data')
--opt  = cmd:parse(arg or {})
--popen = io.popen
--local cmd = 'ls -p '..opt.fileSrc..'/train*'
----print(cmd)
--
--for filePath in popen(cmd):lines() do
--  local fileName  = popen('basename '..filePath):lines()()
--  reduceAndSave(filePath,opt.fileTrg..'/'..fileName)
--end
opt  = {}
local oldFile  = '/home/ductam/testData/model/deenfr/train.de.th7'
for k,v in pairs{0.001} do --, 0.01, 0.001
opt.dataRatio = v
local newFile = '/home/ductam/testData/model/deenfr.varied/'..v..'.train.de.th7'
reduceAndSave(oldFile,newFile) 
end





