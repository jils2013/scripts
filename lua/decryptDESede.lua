local ngx_log = ngx.log
local ngx_ERR = ngx.ERR
local decode_base64 = ngx.decode_base64
local gsub = ngx.re.gsub

local ffi = require "ffi"
local ffi_new = ffi.new
local ffi_gc = ffi.gc
local ffi_copy = ffi.copy
local ffi_str = ffi.string
local C = ffi.C

ffi.cdef[[
typedef unsigned char DES_cblock;
typedef unsigned char const_DES_cblock;
typedef struct DES_key_schedule
{
  uint32_t ks[32];
}DES_key_schedule;
int DES_set_key(const_DES_cblock *key, DES_key_schedule *schedule);
void DES_ecb3_encrypt(const_DES_cblock *input, DES_cblock *output, DES_key_schedule *ks1, DES_key_schedule *ks2, DES_key_schedule *ks3, int enc);
]]

-- openssl base64 -d <<< $str | openssl enc -des-ede3 -K $key -d
-- Java DESede encrypt , OpenSSL equivalent

local function decryptDESede(key, str)
    if not key or not str then return nil end

    local key1 = sub(key, 1, 8)
    local key2 = sub(key, 9, 16)
    local key3 = sub(key, 17, 24)
    local cdc1 = ffi_new("unsigned char [?]", 8)
    local cdc2 = ffi_new("unsigned char [?]", 8)
    local cdc3 = ffi_new("unsigned char [?]", 8)
    ffi_copy(cdc1, key1)
    ffi_copy(cdc2, key2)
    ffi_copy(cdc3, key3)
    local ks1 = ffi_new("DES_key_schedule")
    local ks2 = ffi_new("DES_key_schedule")
    local ks3 = ffi_new("DES_key_schedule")
    C.DES_set_key(cdc1, ks1)
    C.DES_set_key(cdc2, ks2)
    C.DES_set_key(cdc3, ks3) 

    local ret = ""
    for i = 0,#str/8-1 do
        local stri = sub(str, i*8+1, (i+1)*8)
        local output = ffi_new("unsigned char [?]", 8)
        local input = ffi_new("unsigned char [?]", 8)
        ffi_copy(input, stri)
        C.DES_ecb3_encrypt(input, output, ks1, ks2, ks3, 0)
        ret = ret .. ffi_str(output, 8)
    end
    ret = gsub(ret, "\\W*$", "")
    return ret
end
