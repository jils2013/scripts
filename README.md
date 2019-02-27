# scripts
[pj]ython/awk/vbs/lua  

jython/was-un.jy  
use jython/java-api to Installing an application on WebSphere.   
 
jython/hadr-reset.jy  
use jython/wsadmin/db2jcc to initialize db2-hadr ServerListCache with configuration(WebSphere).   

lua/redisinfo.lua  
get redis/sentinel info,work on openresty(ngx-lua)

lua/metrics.lua  
for prometheus metrics,work on openresty(ngx-lua)  
https://github.com/knyar/nginx-lua-prometheus  

lua/rsa.lua  
https://github.com/doujiang24/lua-resty-rsa  
add function:decrypt_with_public_key/encrypt_with_private_key/x509_get_pubkey  

vbs/multic.vbs  
login in multiple terminals,work on SecureCRT

python/dockeregistryfunc.py  
some functions for docker registry http api  
https://docs.docker.com/registry/spec/api/  

python/salt/aio  
salt-sls scripts in py renderer,initialize the virtual-machine os configuration  
-- srv/aio/begin.sls:run sls in step directory(wildcard)  
-- srv/aio/step/:sls scripts,py renderer  
-- srv/aio/step/archive.sls:unzip/tar packages in directory:archive to special path  
-- srv/aio/step/filesystem.sls			#lvcreate,mkfs,mount  
  ...  
-- fileserver+/archive/:archive files,used in step/archive.sls  
-- fileserver+/template/:config template here  
-- fileserver+/template/source:special one,for salt.state.file source  
   #an template example  
-- fileserver+/template/archive:loaded by step/archive.sls
-- fileserver+/template/archive/base.json:default  
-- fileserver+/template/archive/tomcat.json:for label:\*,tocmat  

    
