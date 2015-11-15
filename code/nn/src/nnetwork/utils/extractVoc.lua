assert = require 'luassert'
utf8 = require 'lua-utf8'
require 'src/nnetwork/utils/utilsFunction'

--- provides different strategies to read voc
-- Quick & extremly dirty. Better: strategy pattern
-- Reading possibilities:
-- read from word2vec
-- read from mappedDict
-- extract from text
--    + normal
--    + ngramms
--        + upto
--        + only-mode
-- For RBM-results from Jan, no vocabulary has to be read
function read_voc_word2vec(dataPath)
  --print(dataPath)
  utils.not_nil_empty_all(1,dataPath)
  local inputFile = io.open(dataPath,'r')
  local line = inputFile:read('*line')
  local params = _.split(line,' ')
  params = _.difference(params,{''})
  local vocSize = tonumber(params[1])
  local vectorSize = tonumber(params[2])
  line = inputFile:read('*line') --ignore the first line
  local vocab = {}
  while (line and line ~= "" and line ~= " ")  do
    local splittedLine = _.split(line,' ')
    splittedLine = _.difference(splittedLine,{''})
    --    local splittedLine = utils.splitStringToWordTable(line)
    local word = splittedLine[1]
    vocab [word] = table.getSub(splittedLine,2) -- starts at index 2
    line = inputFile:read('*line')
  end
  return vocab, vocSize, vectorSize
end

function extendsTableWithNgramm(line,ngramArgs)
  --  local tableOneGram = _.split(line,' ')
  --  tableOneGram = _.difference(tableOneGram,{'',' '})
  --print(line)
  local tableOneGram = utils.splitStringToWordTable(line)
  tableOneGram = next(tableOneGram) and tableOneGram or {'UNK_thisSentenceIsCompletelyEmpty_UNK'}
  --utils.printTable(tableOneGram)
  --print(tostring(line))
  utils.not_nil_empty_all(2,tableOneGram,ngramArgs)
  local tableNgram,beginNGram = {}
  local fullTables = {}
  --utils.printTable(ngramArgs)
  if( ngramArgs.mode  == 'upto')then
    table.insert(fullTables,utils.copyTable(tableOneGram))
    beginNGram = 2
  elseif (ngramArgs.mode  == 'only') then
    beginNGram = ngramArgs.number
  else
    error ('mode provided'..(ngramArgs.mode)..'the only accepted modes are: upto|only')
  end

  -- creates n-gram here (Upto -Mode):
  --debug.debug()
  for ngramNumber = beginNGram,ngramArgs.number do
    tableNgram = {}
    for i, var in pairs(tableOneGram) do
      if(i>= ngramNumber) then
        local word = var
        for j= 1, math.min(ngramNumber-1,i-1),1 do
          --print(i,j)
          word = tableOneGram[i-j] .. " " .. word
        end
        table.insert(tableNgram,word)
      end
   end
    table.insert(fullTables,tableNgram)
  end
  --utils.printTable(fullTables)
  return fullTables
end
local function addUnknownWords(voc,ngramArgs) 
--add additonal UNKs
  local counter = _.size(voc)
  for j= 2, #ngramArgs.num_of_most_table do
    local word = 'UNK'
    word = 'UNK'..  string.rep(' UNK', j-1)
    voc[word]  = counter
    counter  = counter +1
  end
  return voc
end

function read_voc_ngramms(inFile,ngramArgs)
  utils.not_nil_empty_all(2,inFile,ngramArgs)
  -- ************************Read file + read all words into a table****************
  local tempVoc,vocWithFreqNgrams = {},{}
  --print(inFile)
  local inFile,line = io.open(inFile,"r")

  line = inFile:read('*line')
  while (line and line ~= "" and line ~= " ")  do
    local wordsTables =  extendsTableWithNgramm(line,ngramArgs) -- each column is one n-Gramm f.e. 1,2,3-gram
    for j, wordsTable in pairs(wordsTables)do
      wordsTable= _.difference(wordsTable,{''})
      for __, word in pairs(wordsTable) do
        vocWithFreqNgrams[j] = vocWithFreqNgrams[j] or {}
        vocWithFreqNgrams[j][word] = vocWithFreqNgrams[j][word] or 0
        vocWithFreqNgrams[j][word] = vocWithFreqNgrams[j][word] + 1
      end
    end
    line = inFile:read('*line')
  end
  inFile:close()
  local voc = {}
  voc['UNK'] = 0

  for i, vocWithFreq in pairs(vocWithFreqNgrams)do
    local vocCurrent = utils.FilterVocUsingWordFrequencies(vocWithFreq,ngramArgs.num_of_most_table[i])
    voc = utils.mergeTable(voc,vocCurrent)
  end
  voc = utils.getUniqueMappingForVoc(voc)
  voc =  addUnknownWords(voc,ngramArgs) 
  

  return voc
end



-- f describes how to calculate tfidf from tf,idf,N
function read_voc_tfidf_ngramm(inFile,ngramArgs,f,tfidfmode)
  local f = f or utils.tfidfNormal
  utils.not_nil_empty_all(3,inFile,ngramArgs,f)
  -- ************************Read file + read all words into a table****************
  local vocWithFreqNgrams = {},{}
  --print(inFile)
  local inFile,line = io.open(inFile,"r")
  local nLines = 0
  line = inFile:read('*line')
  --debug.debug()

  while (line and line ~= "" and line ~= " ")  do
    nLines = nLines+1
    local wordsTables =  extendsTableWithNgramm(line,ngramArgs) -- each column is one n-Gramm f.e. 1,2,3-gram
    for j, wordsTable in pairs(wordsTables)do
      wordsTable= _.difference(wordsTable,{''})
      --utils.printTable(wordsTable) debug.debug()
      local numberWordsOcc = {}
      for i, word in pairs(wordsTable) do
        numberWordsOcc[word] = getTn(word,wordsTable) -- returns a table with: absolute tf.
      end
      local maxOcc = _.max(numberWordsOcc)
      --print(maxOcc)
      --if maxOcc == 7 then utils.printTable(wordsTable)  debug.debug() end
      --      utils.printTable(wordsTable)
      local uniqueWords = _.unique(wordsTable)
      --utils.printTable(uniqueWords) --debug.debug()
      for i, word in pairs(uniqueWords) do
        vocWithFreqNgrams[j] = vocWithFreqNgrams[j] or {}
        vocWithFreqNgrams[j][word] = vocWithFreqNgrams[j][word] or {}
        vocWithFreqNgrams[j][word][1] = vocWithFreqNgrams[j][word][1] and vocWithFreqNgrams[j][word][1] +1  or 1
        vocWithFreqNgrams[j][word][2] = vocWithFreqNgrams[j][word][2] or 0
        vocWithFreqNgrams[j][word][2] = vocWithFreqNgrams[j][word][2] + numberWordsOcc[word]/maxOcc -- <---tf
      end
    end
    line = inFile:read('*line')
  end
  inFile:close()

  assert.not_nil(vocWithFreqNgrams)
  --assert(nLines ==500)
  for i, vocWithFreq in pairs(vocWithFreqNgrams)do
    assert.not_nil(vocWithFreq)
    --utils.printTable(vocWithFreqNgrams[1])

    for word, valueTable in pairs(vocWithFreq) do
      --utils.printTable(vocWithFreq)
      assert.not_nil(vocWithFreq[word])
      print(word, valueTable[2],valueTable[1],nLines)
      vocWithFreq[word] = f(valueTable[2],valueTable[1],nLines,tfidfmode)
    end
  end

  local voc = {}
  voc['UNK'] = 0
  for i, vocWithFreq in pairs(vocWithFreqNgrams)do
    local vocCurrent = utils.FilterVocUsingWordFrequencies(vocWithFreq,ngramArgs.num_of_most_table[i])
    voc = utils.mergeTable(voc,vocCurrent)
  end
  voc = utils.getUniqueMappingForVoc(voc)
  return voc
end

function getTn(word,wordsTable)
  utils.not_nil_empty_all(2,word,wordsTable)
  return  _.countf(wordsTable, function(__,v) return v == word end)
end




--[[
--This solution includes <S> and </S>, not used at the moment
 function extendsTableWithNgramm(tableOneGram,ngramArgs)
  utils.not_nil_empty_all(2,tableOneGram,ngramArgs)
  local tableNgram,beginNGram = {}
  local fullTables = {}
  --utils.printTable(ngramArgs)
  if( ngramArgs.mode  == 'upto')then
    table.insert(fullTables,utils.copyTable(tableOneGram))
    beginNGram = 2
  elseif (ngramArgs.mode  == 'only') then
    beginNGram = ngramArgs.number
  else
    error ('mode provided'..(ngramArgs.mode)..'the only accepted modes are: upto|only')
  end
  if (ngramArgs.number>1 )then
    table.insert(tableOneGram,"</S>") --prepare for 2,3,4-grams
  end
  -- creates n-gram here (Upto -Mode):
  for ngramNumber = beginNGram,ngramArgs.number do
    tableNgram = {}
    for i, var in pairs(tableOneGram) do
      local currentWord,word = "",var
      for j= 1, ngramNumber-1 do
        if (i-j) < 1 then
          currentWord = "<S> "
        else
          currentWord = tableOneGram[i-j] .. " "
        end
        word = currentWord .. word
      end
      table.insert(tableNgram,word)
    end
    table.insert(fullTables,tableNgram)
  end
  --utils.printTable(fullTables)
  return fullTables
end
--]]
