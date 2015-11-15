require 'torch'
utils = {}--torch.class('utils')



function utils.gaussianPDF(mu, sigma, x)
  local y = 1/(math.pi* math.sqrt(sigma*2)) * math.exp(-1/2*(mu-x /sigma)^2)
  return y 
end  
function utils.gaussianSampling(mu, sigma)
-- math.randomseed(os.clock())
--  local x = math.sqrt(-2 * math.log(math.random())) * math.cos(2 * math.pi * math.random())*sigma +mu
--  return x
return torch.normal(mu,sigma) 
end
--this function is extremly expensive
--function utils.writeNNOutputToMatrixFormat(outputTensor,outFile,precision)
--  timer = torch.Timer()
--  local nLines = outputTensor:size(1)
--  local vocSize = outputTensor:size(2)
--  local oneLine = ''
--  precision = precision or 6 -- 6 numbers after . should be enough
--  --print(outputTensor)
--  local factor = math.pow(10,precision)
--  outFile = io.open(outFile,'w+')
--  for i = 1,nLines do
--    oneLine = ''
--    for j = 1,vocSize do
--      local number = math.ceil(outputTensor[{i,j}]*factor) / factor
--      oneLine = oneLine.. ' ' .. number
--    end
--    --print(oneLine)
--    outFile:write( oneLine.. '\n')
--
--  end
--  outFile:close()
--  print(timer:time().real)
--end
--TODO test this function
function utils.writeNNOutputToMatrixFormat(outputTensor,outFile,precision, append )
  local oneLine = ''
  precision = precision or 6 -- 6 numbers after . should be enough
  local mode = append and 'a+' or 'w+'
  --print(outputTensor)
  local factor = math.pow(10,precision)
  local number = 0
  local counter = 0
  local line = ""
  outFile = io.open(outFile,mode)
  outputTensor:apply(function (v)
    counter = counter + 1
    number = math.ceil(v * factor) / factor 
	outFile:write(number,' ')
    if(counter == outputTensor:size(2) ) then
      counter = 0
      outFile:write('\n')
    end
	--print(v, number)
   -- assert(number ~=0,'number = 0,thats not possible')
  end)

  outFile:close()
end


------------------------------------------------
--save Voc in dictionary format
--for example:
--  Unk   0
--  House 2
--  Dog   1
--No strict order required
--@param #string outputFile path+name of file, which should be used to save
--@param #table vocTensor Tensor which contains vocabulary
--@param #string format currently only 'ascii' is supported
function utils.saveVoc(pathToFile,vocTensor)
  print('Save vocabulary to given file at: '..pathToFile)
  outputFile = io.open(pathToFile,'w+')
  assert(outputFile,'file could not be opened to write. Make sure that this path is accessable, and there is no file here: '..pathToFile)
  for key, var in pairs(vocTensor) do
    local oneLine = key.. ' ' .. var..'\n'
    outputFile:write(oneLine)
  end
  outputFile:close()
end
--utils.saveVoc('/home/ductam/testData/testVoc.en',{1,2,3})

function utils.readVoc(vocFile)
  local inFile = io.open(vocFile,'r')
  local line = inFile:read('*line')
  local voc = {}
  while line do
    --local str = _.split(line,' ')
    local i, j = line:find(' ')
    while j do
      i = j
      j = j+1 -- look for the last space
      j = line:find('%s',j)
    end
    --assert.equal(2,size(str))
    voc[line:sub(1,i-1)] = line:sub(i+1)
    line = inFile:read('*line')

  end
  return voc
end

--split str into a table of words (in utf8-format)
function utils.splitStringToWordTable(str)
  lua_utf8 = require 'lua-utf8'
  local result = {}
  for word in lua_utf8.gmatch(str,"%w+") do
    table.insert(result,word)
  end
  return result
end
function table.fromString(str,splitter, f)
   f = f or  function(k,c) return tonumber(c) end
   if torch.type(str) == 'table' then
      return str
   end
   splitter = splitter or '[,]'
   return _.map(_.split(str:sub(2,-2),splitter), f)
end


------------------------------------------------
--Format required for vocWithFreq is: associated table
-- vocWithFreq['that'] = 4 -- if 'that' occures 4 times in our text
--creates a Voc without 'UNK'
function utils.FilterVocUsingWordFrequencies(vocWithFreq,num_of_most)

  --Sort it first
  local sortAbleVoc = {}
  for k,v in pairs(vocWithFreq)do
    local value = {k,v}
    table.insert(sortAbleVoc,value)
  end
  local function compareFunc (a,b)
    return a[2] > b[2]
  end
  table.sort(sortAbleVoc,compareFunc)
  --print ("Number of different Words: ", #sortAbleVoc)

  ---Create voc like in a dictionary
  local voc,counter = {},1
  for i = 1, math.min(num_of_most,#sortAbleVoc), 1 do
    local key = sortAbleVoc[i][1] --  1 = Value, 2= key
    --print(utils.printTable(sortAbleVoc[i]))

    voc[key] = i
  end
  --debug.debug()
  return voc
end
-- From http://stackoverflow.com/questions/1283388/lua-merge-tables
-- values in table 1 have precedence
function utils.mergeTable(t1, t2)
  for k, v in pairs(t2) do
    if (torch.type(v) == "table") and (torch.type(t1[k] or false) == "table") then
      utils.mergeTable(t1[k], t2[k])
    else
      t1[k] = v
    end
  end
  return t1
end
function utils.printTable(tableExample)
  if not tableExample or not(next(tableExample)) then print "table is empty or nil" return end
  for i, v in pairs(tableExample) do print(i,v) end
end

--http://stackoverflow.com/questions/640642/how-do-you-copy-a-lua-table-by-value
function utils.copyTable(t)
  if t == nil then
    return {}
  end
  local u = {}
  for k, v in pairs(t) do u[k] = v end
  return setmetatable(u, getmetatable(t))
end
function utils.mergeAllTables(tables)
  local buffer = {}
  for k,v in pairs(tables) do
    buffer = _.append(buffer,v)
  end
  --    local buffer ={}
  --    for k, v in pairs(tables) do
  --
  --      buffer = utils.mergeTableNotAssociated(buffer,v)
  --    end
  --  utils.printTable(buffer)
  --print ('************')
  return buffer
end
function utils.mergeTableNotAssociated(t1,t2)
  for k, v in pairs(t2) do
    table.insert(t1,v)
  end
  return t1
end
function utils.getUniqueMappingForVoc(voc)
  local counter = 1
  for k,v in pairs(voc) do
    if ( k == 'UNK') then
      voc[k] = 0
    else
      voc[k] = counter
      counter = counter +1
    end
  end
  return voc
end

function utils.addNumbersInTable(t)
  local result = 0
  for __,var in pairs(t) do
    result = result + var
  end
  return result
end

function utils.lengthTable(T)
  return _.size(T)
end
---From dp.Utils
function utils.tableFromString(str,splitter, f)
  --_ = require 'moses'
  f = f or  function(k,c) return tonumber(c) end
  if torch.type(str) == 'table' then
    return str
  end
  splitter = splitter or '[,]'
  return _.map(_.split(str:sub(2,-2),splitter), f)
end-- Check that a data directory exists, and create it if not.
function utils.mkdirIfNeeded(dir)
  if not paths.dirp(dir) then
    print("Directory does not exist. It will be created")
    os.execute('mkdir -p '..dir)
  end
end

function table.fromString(str,splitter, f)
  f = f or  function(k,c) return tonumber(c) end
  if torch.type(str) == 'table' then
    return str
  end
  splitter = splitter or '[,]'
  return _.map(_.split(str,splitter), f)
end

function table.getSub(tableToSeparate, startIndex)
  local tablePuffer ={}
  for key, var in pairs(tableToSeparate) do
    if key >= startIndex then
      table.insert(tablePuffer,var)
    end
  end
  return tablePuffer

end


function utils.foldSum(mappedWords)
  --  assert(torch.type(vector) =='table' and torch.type(currentResult) =='table', 'tables required')
  --  assert(utils.lengthTable(vector) == utils.lengthTable(currentResult), 'same vector length required'
  --assert(torch.type())
  local buffer
  --table.print(mappedWords)
  for key,var in pairs(mappedWords) do
    if not (buffer) then
      buffer = utils.copyTable(var)
    else
      for k, v in pairs(var) do
        buffer[k]  = tonumber(v) + buffer[k]
      end
    end
  end
  return buffer
end

function utils.foldAvg(mappedWords)
  local summedVector = utils.foldSum(mappedWords)
  local size = utils.lengthTable(mappedWords)
  --utils.printTable(mappedWords)
  --utils.printTable(summedVector)
  count = count or 0
  if size == 0 then
    print ("************************************************")
    count = count+ 1
    print('Warning :size of  summed vector is : '..size)
    print('Warning :we are having : '..count .. " empty lines")
    --utils.printTable(mappedWords)

  end
  local buffer = {}
  if size == 0 then return {} end
  for k, v in pairs(summedVector) do
    buffer[k]  = v /size
  end
  --utils.printTable(buffer)
  return buffer
end
--Max over all dims
--MAPPEDWord :table of words
function utils.foldMax(mappedWords)
  local maxVector
  for k, v in pairs(mappedWords) do
    maxVector = maxVector or v --if still empty
    maxVector = _.map(maxVector,function (i,j)  return math.max(j,v[i]) end)
  end
--  table.print(maxVector)
  return maxVector
  --x = {{1.4, -1.2, 0.65},
--  {-0.93, 1.4, 0.4},
--  {1.5, -2.4, 0.65}}
--utils.printTable(utils.foldMax(x))
--debug.debug()
end


function utils.foldMaxOverWord(mappedWords)
  local currentMaxNorm = -math.huge
  local maxVector = nil
  for k, v in pairs(mappedWords) do
    local norm = utils.getEuclidNorm(v)
    if ( norm > currentMaxNorm) then
      currentMaxNorm = norm
      maxVector = v
    end
  end
  return maxVector
end

function utils.getEuclidNorm(vector)
  assert(torch.type(vector) == "table", 'vector has to be a table')
  local value = 0
  for k,v in pairs(vector) do
    value  = value + v
  end
  value = math.sqrt(value)
  return value
end
--input: Mapped words are expected to be numbers
--output: line representation, vector form, length = vocSize
function utils.foldBinaryVector(mappedWords,vocSize)
  local buffer = {}
  for index=1,vocSize do
    buffer[index] = 0
  end
  for key, var in pairs(mappedWords) do
    var = var +1 -- <--because torch expects table to start from 0
    buffer[var] = 1
  end
  return buffer
end
function utils.foldTFVector(mappedWords,vocSize)
  --print('Folding line to form TF vector from text')
  local buffer =  {}
  for index=1,vocSize do
    buffer[index] = 0
  end
  for key, var in pairs(mappedWords) do
    var = var +1 -- <--because torch expects table to start from 0

    buffer[var] = buffer[var] +1
  end
  return buffer
end



---http://stackoverflow.com/questions/5303174/get-list-of-directory-in-a-lua
--extended to get files/directory list
--alternatively, lfs.dir(sampleDir) can be used
--scan dir for files/
--mode = 0 -> return all files
--mode = 1 -> return all directory
function utils.scandir(directory,mode)
  local i, t, popen = 0, {}, io.popen
  mode = mode or 0
  local cmd = (mode == 0) and 'ls -p "'..directory..'" | grep -v /'  or 'ls -p "'..directory..'" | grep /'
  print ("************************")
  print("Scanning directory: ".. directory)
  for filename in popen(cmd):lines() do
    i = i + 1
    t[i] = filename
    print("Found file/dir: " ..filename)
  end

  return t
end

function utils.printMetaInfTensor(dataRef,tensorName)
  local data = torch.ne(dataRef,0)
  tensorName = tensorName or ""
  print('************************************************************')
  print('Meta information about given Tensor:' .. tensorName)
  print('Size of Tensor: ', dataRef:size())
  print('Number Elements: '.. dataRef:numel())
  print('Number Elements ~= 0: '.. data:sum())
  print('Sum of all Elements: '.. dataRef:sum())
  print('Euclide-Norm of Elements: '.. dataRef:norm(2))

  local dataSize = data:size()
  local dataOcc = data:sum()
  for i =1,dataSize:size() do
    local nElems = dataOcc/ dataSize[i]
    print('Absolute numbers elements ~= 0 in '..i..'-th Dim: '.. nElems)
  end
end
function utils.tensorBetweenRange(t,min,max)
  local data1 = torch.lt(t,min)
  local data2 = torch.gt(t,max)
  local data = data1+data2
  local sum = data:sum()
  return sum == 0
end

--dataTable[1] = tf
--dataTable[2] = N
function utils.tfidfNormal(tf,nDocRelevant,nDocTotal)
  assert.not_nil(tf)
  assert.not_nil(nDocRelevant)
  assert.not_nil(nDocTotal)
  --print(nDocRelevant,nDocTotal)

  assert.True(nDocRelevant<nDocTotal)
  local tfidf = tf * math.log10(nDocTotal/nDocRelevant)
  return tfidf
end
function utils.myWeightedtfidf(tf,nDocRelevant,nDocTotal,mode)
  assert.not_nil(tf)
  assert.not_nil(nDocRelevant)
  assert.not_nil(nDocTotal)
  --print(nDocRelevant,nDocTotal)

  assert.True(nDocRelevant<nDocTotal)
  local tfidf
  if (mode == 'tflogidf') then
    tfidf = tf * math.log(nDocTotal/nDocRelevant)
  elseif (mode == 'logtfidf') then
    tfidf = math.log(tf) *nDocTotal/nDocRelevant
  elseif (mode == 'tfidf') then
    tfidf = tf * nDocTotal/nDocRelevant
  else
    error('unknown mode')
  end
  return tfidf
end
function utils.not_nil_all(nArgs,...)
  arg = {...}
  assert = require 'luassert'
  for i = 1,nArgs do
    assert.not_nil(arg[i])
  end
end
---
--Check if aEnything is nil, '',or {}
function utils.not_nil_empty_all(nArgs,...)
  local arg = {...}
  local assert = require 'luassert'
  for i = 1,nArgs do
    assert.not_nil(arg[i])
    --print('checking argnumber:'..i)
    if (type(arg[i]) == 'table') then
      assert.not_same(arg[i],{})
    elseif (type(arg[i])  == 'string') then
      assert.not_same(arg[i],'')
    end
  end
end
function debug.printLocals()
  error 'not implemented'
end
function reduceData(fileName,ratio)
  x = torch.load(fileName)
  y = x:narrow(1,1,math.ceil(x:size(1)*ratio)):clone()
  torch.save("tiny."..fileName,y)
end

function copyIntoConsole()
  reduceData("train.en.th7",0.01)
  reduceData("train.de.th7",0.01)
  reduceData("test.en.th7",0.1)
  reduceData("test.de.th7",0.1)
  reduceData("dev.en.th7",0.1)
  reduceData("dev.de.th7",0.1)
end
--utils.not_nil_empty_all(3,2,2,3)
--local t = torch.DoubleTensor({1,2,3})
--assert(utils.tensorBetweenRange(t,0,1))
--voc = utils.readVoc("/home/ductam/testData/voc.test")
--utils.printTable(voc)
--debug.debug()
function utils.getLinesNumber(inFile)
  local popen = io.popen
  local cmd =  'wc -l '..inFile..' | cut -d \" \" -f1'
  --print(cmd)
  return tonumber(popen(cmd):lines()())
end
function utils.reverseKV(t)
  local newT ={}
  for k,v in pairs(t) do
    newT[tonumber(v)] = k
  end
  return newT
end

--debug.debug()
function utils.initTab(size,value)
  value = value or 0
  local t= {}
  for i = 1,size do
    t[i] = value
  end
  return t
end

--input: a sparse Tensor
--output: a tensor in CSR-format
function utils.toCSR(tensor)
  local nElement
  local sizeTen= tensor:size()
  do
    local data = torch.ne(tensor,0)
    nElement =data:sum()
  end
  collectgarbage()

  local csrTensor = torch.zeros(nElement+1,2) --#1 for position,2 value
  csrTensor[1][1] = sizeTen[1]
  csrTensor[1][2] = sizeTen[2]
  local counterTensor = 0
  local counterResult = 1
  tensor:apply(function(x)
    counterTensor = counterTensor + 1;
    if (x ~=0) then
      counterResult = counterResult+ 2
      csrTensor:storage()[counterResult] = counterTensor
      csrTensor:storage()[counterResult+1] = x

    end
    return  end) -- fill-up x

  return csrTensor
end
function utils.fromCSR(csrTensor)
  local resultTensor  = torch.zeros(csrTensor[1][1],csrTensor[1][2])
  local counterResult = 0
  local counterCSRTensor = 0

  --print(csrTensor)
  csrTensor:apply(function(x)
    counterCSRTensor = counterCSRTensor+1
    if (counterCSRTensor <= 2 ) then
      return
    end
    if ( counterCSRTensor % 2 == 1) then
      --      print(counterCSRTensor)
      --      print(csrTensor)
      resultTensor:storage()[x] = csrTensor:storage()[counterCSRTensor+1]
    end
  end
  ) -- fill-up x

  return resultTensor
end

load = torch.load
function torch.load(path,mode)
  local result =  load(path)--load(path,'binary')
 
  if (mode == 'csr') then
	--print(result)
    if (result:size(2) ==2) then
	   return  utils.fromCSR(result) 
	 else 
		print('warning, loading matrix in ColumnnStretchedMode not possible. Loading in bineary mode instead')
	 end
  elseif (mode == 'ascii') then
   return load(path,'ascii')	
  end
  return result 
  
end
--x = torch.ones(4,4) /3
--x[3][2] =0
--x[2][3] =0
--y = utils.toCSR(x)
--print(x)
--print(y)
--print(utils.fromCSR(y))

function torch.compareTensor(t1,t2)
  local x = t1:eq(t2)
  if (x:sum() == x:nElement() ) then
    return true
  else
    return false
  end
end
