local redis = require "resty.redis"
redis.add_commands("info")

local _M = {_VERSION = "0.01"}

local function infot(info)
  local t = {}
  ngx.re.gsub(info,"([^\r\n:]+):([^\r\n]+)",function(m)
  local _, b, _ = ngx.re.gsub(m[2], "([^=,]+)=([^=,]+)", function(n) t[m[1].."_"..n[1]] = n[2] return "" end)
  if b == 0 then t[m[1]] = m[2] end
  return ""
  end)
  return t
end

local function conn(host,port)
  local r = redis:new()
  local ok, err = r:connect(host, port)
  if not ok then return err else return r end
end

function _M.info()
  local red,err = conn("127.0.0.1",6379)
  local redisinfo = err or infot(red:info())
  if red then red:close() end

  local m = {slave = {redisinfo["master_host"], redisinfo["master_port"]}, master = {"127.0.0.1", 6379}}

  local sen,err = conn(m[redisinfo["role"]][1],26379)
  local sentinelinfo = err or infot(sen:info())
  if sen then sen:close() end
  return {redisinfo,sentinelinfo}
end

return _M

