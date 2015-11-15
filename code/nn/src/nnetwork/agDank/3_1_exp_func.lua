function forward(model,batch,crit,cuda,doBackward)
  local f = 0
  local inputs, targets = unpack(batch)
  if ( cuda) then
    inputs = inputs:cuda()
    targets = targets:cuda()
  end
  local inputToModel = inputs
  local outputs = model:forward(inputToModel)
  local err = crit:forward(outputs, targets)
  local _____= doBackward and model:backward(inputToModel, crit:backward(outputs, targets))
  f = f + err
  return f
end
