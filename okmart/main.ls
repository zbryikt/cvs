require! <[request fs]>
counties = <[基隆市 台北市 新北市 澎湖縣 金門縣 桃園縣 新竹市 新竹縣 宜蘭縣 苗栗縣 台中市 彰化縣 花蓮縣 南投縣 雲林縣 嘉義市 台南市 台東縣 高雄市 屏東縣]>
county = counties.0
stores = []

finish = ->
  console.log "completed. saving store list..."
  fs.write-file-sync "stores.json", JSON.stringify(stores)
  console.log "done. bye bye!"

fetchstores = ->
  if !counties.length => return finish!
  county = counties.0
  console.log "retrieve county: #county"
  (e,r,b) <- request do
    url: "http://www.okmart.com.tw/convenient_shopSearch_Result.asp?_=1415688251000&city=#{county}&zipcode=&key=&service=undefined"
    method: \GET
  if e or !b => return setTimeout fetchstores, 1000
  counties.splice 0,1
  b = b.split \\n .map -> it.trim!
  b = b.map -> /<li><h2> *([^<]+) *<\/h2><span> *([^<]+) *<\/span>/.exec it
  b = b.filter -> it
  b = b.map -> [it.1.trim!, it.2.trim!]
  stores := stores ++ b
  setTimeout fetchstores, 100

fetchstores!
