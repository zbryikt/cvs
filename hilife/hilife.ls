require! <[request cheerio fs]>

get-token = ($) -> do
  __VIEWSTATE: $("input[name=__VIEWSTATE]").attr("value")
  __EVENTVALIDATION: $("input[name=__EVENTVALIDATION]").attr("value")
  __VIEWSTATEGENERATOR: $("input[name=__VIEWSTATEGENERATOR]").attr("value")

get-city = (cb) ->
  (e,r,b) <- request { url: \http://www.hilife.com.tw/storeInquiry_street.aspx }
  $ = cheerio.load b
  token = get-token $
  city = []
  $("select[name=CITY] option").map (i,e) -> city.push $(e).attr("value")
  cb token, city

get-town = (cb, token, c) ->
  (e,r,b) <- request {
    url: \http://www.hilife.com.tw/storeInquiry_street.aspx
    method: \POST
    form: {CITY: c} <<< token
  }, _
  $ = cheerio.load b
  token = get-token $
  town = []
  $("select[name=AREA] option").map (i,e) -> town.push $(e).attr("value")
  cb token, town

get-list = (cb, token, c, t) ->
  (e,r,b) <- request {
    url: \http://www.hilife.com.tw/storeInquiry_street.aspx
    method: \POST
    form: {CITY: c, AREA: t} <<< token
  }, _
  $ = cheerio.load b
  token = get-token $
  store = []
  $(".searchResults tr").map (i,e) ->
    store.push {name: $(e).find("th").text!, addr: $(e).find("td:first-of-type").text!}
  cb token,store

cthash = {}
all-city = (token) ->
  while true
    cities = [c for c of cthash]
    if !cities.length => return
    city = cities.0
    town = cthash[city].splice(0,1).0
    if cthash[city].length == 0 => delete cthash[city]
    if not fs.exists-sync("raw/#city.#town.json") => break
  (token, _c) <- get-town _, token, city
  cb = (token, store) ->
    fs.write-file-sync "raw/#city.#town.json", JSON.stringify(store)
    setTimeout (-> all-city token), 100
  console.log "get: #city / #town"
  get-list cb, token, city, town


next-city = (token, city) ->
  if !city.length =>
    fs.write-file-sync "cthash.json", JSON.stringify(cthash)
    return all-city token
  c = city.splice(0,1).0
  cb = (token, town) -> 
    cthash[c] = town
    console.log "#c : #{town.length}"
    setTimeout -> next-city token, city, 100
  get-town cb, token, c

if fs.exists-sync "cthash.json" =>
  cthash = JSON.parse(fs.read-file-sync "cthash.json" .toString!)
  (token, city) <- get-city
  all-city token
else 
  (token, city) <- get-city
  next-city token, city
