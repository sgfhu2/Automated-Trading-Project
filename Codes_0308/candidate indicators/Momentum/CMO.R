# parameters for CMO
params = list(series=c(1,2,3,4,5,6,7,8,9,10),
              lookback=15,
              lookback_sig=7,
              threshold=50,
              iniDay=22)

# CMO: Chande Momentum Oscillator

getOrders = function(store, newRowList, currentPos, params) {
  # initialize vectors
  allzero = rep(0, length(newRowList))
  
  # creat a list to store all the information of orders
  if (is.null(store))
    store = initStore(newRowList)
  else
    store = updateStore(store, newRowList, currentPos)
  
  # initialize the position and all orders
  pos = allzero
  marketOrders = allzero
  limitOrders1 = allzero
  limitPrices1 = allzero
  limitOrders2 = allzero
  limitPrices2 = allzero
  
  # Use the mean absolute difference for position sizing
  if(store$iter >= params$iniDay) {
    for (i in params$series) {
      store$meanDiff[i] = mean(abs(diff(store$op[[i]][(store$iter-params$iniDay+1):store$iter])[-1]))
    }
    for (i in params$series) {
      store$posSize[i] = round(max(store$meanDiff)/store$meanDiff[i])
    }
  }
  
  if(store$iter >= params$iniDay) {
    for (i in params$series) {
      dataIndex = (store$iter-params$iniDay+1):store$iter
      
      close = store$cl[[i]][dataIndex]
      
      Cmo = CMO(close, n=params$lookback)
      
      Cmo_signal = SMA(Cmo, n=params$lookback_sig)

      if(last(Cmo)>last(Cmo_signal) && last(Cmo)>params$threshold) {
        pos[i] = 1 * store$posSize[i] # Long
      }
      else if(last(Cmo)<last(Cmo_signal) && last(Cmo)<(-params$threshold)) {
        pos[i] = -1 * store$posSize[i] # Short
      }
      else {
        #if(currentPos[i]==1 && last(Cmo_signal)<0)
        #  pos[i] = 0
        #else if(currentPos[i]==(-1) && last(Cmo_signal)>0)
        #  pos[i] = 0
        #else
          pos[i] = currentPos[i]
      }
    }
    marketOrders = -currentPos + pos
  }
  return(list(store = store,
              marketOrders = marketOrders,
              limitOrders1 = limitOrders1,
              limitPrices1 = limitPrices1,
              limitOrders2 = limitOrders2,
              limitPrices2 = limitPrices2))
}

initOpStore  = function(newRowList) {
  opStore = lapply(newRowList, function(x) x$Open)
  return(opStore)
}
updateOpStore = function(opStore, newRowList) {
  opStore = mapply(function(x, y) rbind(x, y$Open), opStore, newRowList, SIMPLIFY=FALSE)
  return(opStore)
}

initHiStore  = function(newRowList) {
  hiStore = lapply(newRowList, function(x) x$High)
  return(hiStore)
}
updateHiStore = function(hiStore, newRowList) {
  hiStore = mapply(function(x, y) rbind(x, y$High), hiStore, newRowList, SIMPLIFY=FALSE)
  return(hiStore)
}

initLoStore  = function(newRowList) {
  loStore = lapply(newRowList, function(x) x$Low)
  return(loStore)
}
updateLoStore = function(loStore, newRowList) {
  loStore = mapply(function(x, y) rbind(x, y$Low), loStore, newRowList, SIMPLIFY=FALSE)
  return(loStore)
}

initClStore  = function(newRowList) {
  clStore = lapply(newRowList, function(x) x$Close)
  return(clStore)
}
updateClStore = function(clStore, newRowList) {
  clStore = mapply(function(x, y) rbind(x, y$Close), clStore, newRowList, SIMPLIFY=FALSE)
  return(clStore)
}

initVoStore  = function(newRowList) {
  voStore = lapply(newRowList, function(x) x$Volume)
  return(voStore)
}
updateVoStore = function(voStore, newRowList) {
  voStore = mapply(function(x, y) rbind(x, y$Volume), voStore, newRowList, SIMPLIFY=FALSE)
  return(voStore)
}

initStore = function(newRowList) {
  return(list(iter = 1,
              op = initOpStore(newRowList),
              hi = initHiStore(newRowList),
              lo = initLoStore(newRowList),
              cl = initClStore(newRowList),
              vo = initVoStore(newRowList),
              meanDiff = rep(0,10),
              posSize=rep(1,10)))
}
updateStore = function(store, newRowList, currentPos) {
  store$iter = store$iter + 1
  store$op = updateOpStore(store$op, newRowList) 
  store$hi = updateHiStore(store$hi, newRowList)
  store$lo = updateLoStore(store$lo, newRowList)
  store$cl = updateClStore(store$cl, newRowList)
  store$vo = updateVoStore(store$vo, newRowList)
  return(store)
}