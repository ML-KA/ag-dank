_ = require 'moses'--require 'dp' --TODO actually only need _
assert = require 'luassert'
require 'src.nnetwork.utils.utilsFunction'
require 'src.nnetwork.utils.extractVoc'
--inFile is path, voc is associated table, f function how to map: sum,avg,max and so on
function readTextBasedOnVoc(inFile,voc,f,vocSize,mappingFunc,ngramArgs,unknownRep)
  --[[
  there are unknown word in the text. what to do?
  https:///groups.google.com/forum/#!topic/word2vec-toolkit/TgMeiJJGDc0
  according to the author of word2vec, there are several possibilities:
  +skip unknown word 
  +random representation
  +more data       

  here we choose skipping
  --]] 
  print("Reading text from file based on vocabulary : "..inFile )

  --f = f or utils.foldMax --stardard folding function is max
  --print(2)
  local popen = io.popen
  local cmd =  'wc -l '..inFile..' | cut -d \" \" -f1'
  --print(cmd)
  local linesNumber = tonumber(popen(cmd):lines()())
  --print(linesNumber)
  local sizeSecondDim = vocSize or _.size(select(2,next(voc)))
  local docRepTensor = torch.Tensor(linesNumber,sizeSecondDim)
  --debug.debug()
  inFile = io.open(inFile,'r')
  local line = inFile:read('*line')
  local counterLine = 0
  while (line and line ~= "" and line ~= " ") do
    counterLine = counterLine +1
    local words = utils.splitStringToWordTable(line)
    words = (mappingFunc == nil) and words or mappingFunc(line,voc,ngramArgs)
    local mappedWords = _.map(words, function(i,word)
      if ( voc[word] or unknownRep) then return voc[word]  or unknownRep
      else
			local temp = word
        local _, count = string.gsub(word,' ','') --check which UNK is appropriate
        word = 'UNK'..  string.rep(' UNK', count)
		  --print(temp,word,voc[word])
        return voc[word]
      end
    end )

    local vector
    if not next(mappedWords) then  --W2V mode and nothing will come back
      print("this sentence is  completely not covered by current vocabulary, please check it")
      utils.printTable(words)
      vector = _.size(select(2,next(voc)))
    else
      --print(4.1)
      nLine= nLine or 0
      nLine = nLine +1
      if(nLine%50 ==0) then
        collectgarbage()
      end

      vector = f(mappedWords,vocSize)
    end
    local vectorTensor = torch.Tensor(vector)
	--print(vectorTensor[1],vectorTensor[2702],vectorTensor[2703])
    docRepTensor[{counterLine,{}}] = vectorTensor
    line = inFile:read('*line')
  end
  --print(6)
  --print("done")
	--print(docRepTensor:select(2,2703):sum())
	--print(docRepTensor:sum())
  return docRepTensor
end


function mappingFuncNGram(line,voc,ngramArgs)
  --print(line)
  --table.print(ngramArgs)
  --print(3)
  local wordsTable = extendsTableWithNgramm(line,ngramArgs)
  local words = utils.mergeAllTables(wordsTable)
	--utils.printTable(words)
	--debug.debug()
  --print('here')
  --here, we have to map them to numbers
  --  print('Before: ',table.tostring(words))
  --  words = _.map(words,function(word) return voc[word] or words['UNK']end)
  --  print('after:', table.tostring(words))

  return words
end
function readTextDirect(dataPath)
  print ('Reading text directly from file: '..dataPath)
  local inputFile = io.open(dataPath,'r')
  local line = inputFile:read('*line')
  local popen = io.popen
  local cmd =  'wc -l '..dataPath..' | cut -d \" \" -f1'
  local linesNumber = tonumber(popen(cmd):lines()())

  local cmd2 = 'head -n 1 '.. dataPath.. ' | wc -w'
  local sizeSecondDim = tonumber(popen(cmd2):lines()())
  local docRepTensor = torch.Tensor(linesNumber,sizeSecondDim)

  local counterLine = 0
  while (line and line ~= "" and line ~= " ")  do
    counterLine = counterLine+1
    local newRow =  table.fromString(line, ' ')
    docRepTensor[{counterLine,{}}] = torch.Tensor(newRow)
    line = inputFile:read('*line')
  end
  inputFile:close()
  return docRepTensor
end

--dataPath ='/home/ductam/testData/represent.32.test'


--local words = {'a a', 'b', 'c', 'c c c'}
--local voc = {['UNK']=0,['b'] = 1,['UNK UNK']=2,['UNK UNK UNK']=3}
--
--local mappedWords = _.map(words, function(i,word)
--  if ( voc[word] or unknownRep) then return voc[word]  or unknownRep
--  else
--    local _, count = string.gsub(word,' ','') --check which UNK is appropriate
--    word = 'UNK' ..  string.rep(' UNK', count)
--    print(word,count)
--    return voc[word]
--  end
--end )
--utils.printTable(mappedWords)
