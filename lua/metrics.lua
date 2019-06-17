local metric_prometheus = require "lib.resty.metrics.prometheus"
local new_tab = require "table.new"
local ngx_var = ngx.var

local _M = {_VERSION = "0.01"}

local prometheus, err = metric_prometheus.init("router_shm_metric","nginx_metrics_")
if not prometheus then
  return error("fail to new prometheus "..tostring(err))
end

local alert_40x = {r400 = 1, r404 = 1}
local alert_50x = {r500 = 1, r502 = 1, r504=1}
local noruntimeset = {router_redis_info = true,router_sentinel_info = true}
local metrics = {
  {"http_request_total_host", {"key"}, "Number of HTTP requests on each host", "counter"},
  {"http_request_size_host", {"key"}, "Total size of HTTP requests on each host", "counter"},
  {"http_response_size_host", {"key"}, "Total size of HTTP response on each host", "counter"},
  {"http_request_total_route", {"key"}, "Number of HTTP requests on each route", "counter"},
  {"http_request_size_route", {"key"}, "Total size of HTTP requests on each route", "counter"},
  {"http_response_size_route", {"key"}, "Total size of HTTP response on each route", "counter"},
  {"http_request_duration_route", {"key"}, "HTTP request latency on each route", "histogram"},
  {"http_request_alert_40x_route", {"key"}, "Number of HTTP requests on each route with http code 400/404", "counter"},
  {"http_request_alert_50x_route", {"key"}, "Number of HTTP requests on each route with http code 500/502/504", "counter"},
  {"lua_memory_total_worker", {"worker"}, "Memory size used by Lua on each worker(in mbytes)", "gauge"},
}
local setrunner = {
  counter = function(name, desc, labels) return prometheus:counter(name, desc, labels) end,
  gauge = function(name, desc, labels) return prometheus:gauge(name, desc, labels) end,
  histogram = function(name, desc, labels) return prometheus:histogram(name, desc, labels) end,
}
local setvalue = {
  counter = function(item) item.runner:inc(item.value, item.label_values) end,
  gauge = function(item) item.runner:set(item.value, item.label_values) end,
  histogram = function(item) item.runner:observe(item.value, item.label_values) end,
}

local metric_ctx_idx = new_tab(0, #metrics)
local metric_ctx = new_tab(#metrics, 0)
for i,v in ipairs(metrics) do
  local ctx = new_tab(0, 6)
  ctx["name"] = v[1]
  ctx["label_names"] = v[2]
  ctx["type"] = v[4]
  ctx["runner"] = setrunner[ctx.type](ctx.name, v[3], ctx.label_names)
  metric_ctx[i] = ctx
  metric_ctx_idx[ctx.name] = i
end

local function _do_metric(premature, ctx)
  if premature then
    return
  end

  for _, item in ipairs(ctx) do
    if not noruntimeset[item["name"]] then setvalue[item.type](item) end
  end
end

--ctx contain route_key(host+location)
function _M.run(ctx)
  local ctx = ctx or {}
  local router_key = ctx.route_key or ngx_var.host

  metric_ctx[metric_ctx_idx["http_request_total_host"]]["value"] = 1
  metric_ctx[metric_ctx_idx["http_request_total_host"]]["label_values"] = {ngx_var.host}
  metric_ctx[metric_ctx_idx["http_request_size_host"]]["value"] = tonumber(ngx_var.request_length)
  metric_ctx[metric_ctx_idx["http_request_size_host"]]["label_values"] = {ngx_var.host}
  metric_ctx[metric_ctx_idx["http_response_size_host"]]["value"] = tonumber(ngx_var.bytes_sent)
  metric_ctx[metric_ctx_idx["http_response_size_host"]]["label_values"] = {ngx_var.host}
  metric_ctx[metric_ctx_idx["http_request_total_route"]]["value"] = 1
  metric_ctx[metric_ctx_idx["http_request_total_route"]]["label_values"] = {router_key}
  metric_ctx[metric_ctx_idx["http_request_size_route"]]["value"] = tonumber(ngx_var.request_length)
  metric_ctx[metric_ctx_idx["http_request_size_route"]]["label_values"] = {router_key}
  metric_ctx[metric_ctx_idx["http_response_size_route"]]["value"] = tonumber(ngx_var.bytes_sent)
  metric_ctx[metric_ctx_idx["http_response_size_route"]]["label_values"] = {router_key}
  metric_ctx[metric_ctx_idx["http_request_alert_40x_route"]]["value"] = alert_40x["r"..tostring(ngx_var.status)] or 0
  metric_ctx[metric_ctx_idx["http_request_alert_40x_route"]]["label_values"] = {router_key}
  metric_ctx[metric_ctx_idx["http_request_alert_50x_route"]]["value"] = alert_50x["r"..tostring(ngx_var.status)] or 0
  metric_ctx[metric_ctx_idx["http_request_alert_50x_route"]]["label_values"] = {router_key}
  metric_ctx[metric_ctx_idx["http_request_duration_route"]]["value"] = tonumber(ngx_var.request_time)
  metric_ctx[metric_ctx_idx["http_request_duration_route"]]["label_values"] = {router_key}
  metric_ctx[metric_ctx_idx["lua_memory_total_worker"]]["value"] = collectgarbage("count")/1024
  metric_ctx[metric_ctx_idx["lua_memory_total_worker"]]["label_values"] = {ngx.worker.id()}

  local ok, err = ngx.timer.at(0, _do_metric, metric_ctx)
  if not ok then
    if err ~= "process exiting" then
      ngx.log(ngx.ERR,"[ROUTER_METRICS]failed to create timer: ", err)
    end
  end
end

--redisinfo from lua/router_redisinfo.lua
function _M.collect(redisinfo)
  return prometheus:collect()
end

return _M
