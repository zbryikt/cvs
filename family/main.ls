require! <[request fs]>
counties = <[基隆市 台北市 新北市 澎湖縣 金門縣 桃園縣 新竹市 新竹縣 宜蘭縣 苗栗縣 台中市 彰化縣 花蓮縣 南投縣 雲林縣 嘉義市 台南市 台東縣 高雄市 屏東縣]>
county = counties.0
townlist = {}
towns = []
stores = []

complete = ->
  console.log "completed. saving store list..."
  fs.write-file-sync "stores.json", JSON.stringify(stores)
  console.log "done. bye bye!"
  
_fetchstore = ->
  if !towns.length => return complete!
  item = towns.0
  console.log "retrieve: #{item.city} / #{item.town}"
  (e,r,b) <- request do
    url: "http://api.map.com.tw/net/familyShop.aspx?searchType=ShopList&type=&city=#{item.city}&area=#{item.town}&road=&fun=showStoreList"
    method: \GET
  if e or !b => return setTimeout _fetchstore, 1000
  towns.splice 0,1
  b = b.replace /^showStoreList\(/, ""
  b = b.replace /\)$/, ""
  stores := stores ++ JSON.parse(b)
  setTimeout _fetchstore, 100

fetchstore = ->
  _towns = []
  for c of townlist => _towns ++= townlist[c]
  towns := _towns
  _fetchstore!


finish = ->
  console.log "save townlist..."
  fs.write-file-sync "townlist.json", JSON.stringify(townlist)
  console.log "done. now fetch stores... "
  fetchstore!

fetchtowns = ->
  if !counties.length => return finish!
  county = counties.0
  console.log "retrieve county: #county"
  (e,r,b) <- request do
    url: "http://api.map.com.tw/net/familyShop.aspx?searchType=ShowTownList&type=&city=#{county}&fun=storeTownList"
    method: \GET
  if e or !b => return setTimeout fetchtowns, 1000
  counties.splice 0,1
  b = b.replace /\)$/, ""
  b = b.replace /^storeTownList\(/, ""
  townlist[county] = JSON.parse b
  setTimeout fetchtowns, 100

if fs.exists-sync "townlist.json" =>
  console.log "previous townlist found. use it instead..."
  townlist = JSON.parse(fs.read-file-sync "townlist.json" .toString!)
  fetchstore!
else => fetchtowns!
