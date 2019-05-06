local ngx_log = ngx.log
local ngx_ERR = ngx.ERR
local decode_base64 = ngx.decode_base64
local gsub = ngx.re.gsub
local sub = string.sub

local ffi = require "ffi"
local ffi_new = ffi.new
local ffi_gc = ffi.gc
local ffi_copy = ffi.copy
local ffi_str = ffi.string
local C = ffi.C

ffi.cdef[[
typedef unsigned long DES_LONG;
typedef unsigned char DES_cblock;
typedef unsigned char const_DES_cblock;
typedef struct DES_ks {
    union {
        DES_cblock cblock;
        DES_LONG deslong[2];
    } ks[16];
} DES_key_schedule;
int DES_set_key(const_DES_cblock *key, DES_key_schedule *schedule);
void DES_ecb3_encrypt(const_DES_cblock *input, DES_cblock *output, DES_key_schedule *ks1, DES_key_schedule *ks2, DES_key_schedule *ks3, int enc);
]]

-- openssl base64 -d <<< $str | openssl enc -des-ede3 -K $key -d
-- Java DESede encrypt , OpenSSL equivalent
-- follow: https://stackoverflow.com/questions/9038298/java-desede-encrypt-openssl-equivalent

local function decryptDESede(key, str)
    if not key or not str then return nil end

    local key1 = sub(key, 1, 8)
    local key2 = sub(key, 9, 16)
    local key3 = sub(key, 17, 24)
    local cdc1 = ffi_new("DES_cblock [8]", key1)
    local cdc2 = ffi_new("DES_cblock [8]", key2)
    local cdc3 = ffi_new("DES_cblock [8]", key3)
    local ks1 = ffi_new("DES_key_schedule")
    local ks2 = ffi_new("DES_key_schedule")
    local ks3 = ffi_new("DES_key_schedule")
    C.DES_set_key(cdc1, ks1)
    C.DES_set_key(cdc2, ks2)
    C.DES_set_key(cdc3, ks3) 

    local ret = ""
    for i = 0,#str/8-1 do
        local stri = sub(str, i*8+1, (i+1)*8)
        local output = ffi_new("DES_cblock [8]")
        local input = ffi_new("DES_cblock [8]", stri)
        C.DES_ecb3_encrypt(input, output, ks1, ks2, ks3, 0)
        ret = ret .. ffi_str(output, 8)
    end
    ret = gsub(ret, "[[:cntrl:]]*$", "")
    return ret
end
