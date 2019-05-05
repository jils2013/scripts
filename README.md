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

lua/decryptDESede.lua  
follow: https://stackoverflow.com/questions/9038298/java-desede-encrypt-openssl-equivalent  
use luajit with openssl implementation for Java DESede decrypt  

vbs/multic.vbs  
login in multiple terminals,work on SecureCRT

python/dockeregistryfunc.py  
some functions for docker registry http api  
https://docs.docker.com/registry/spec/api/  

python/salt  
salt-sls scripts in py renderer,initialize the virtual-machine os configuration  
-- etc/salt/roster:an example roster in py renderer  
-- srv/aio/begin.sls:run sls in step directory(wildcard)  
-- srv/aio/step/archive.sls:unzip/tar packages in directory:archive to special path  
-- srv/aio/step/filesystem.sls:lvcreate,mkfs,mount  
  ...  
-- fileserver+/archive/:archive files here  
-- fileserver+/template/:config template here  
   #an template example  
-- fileserver+/template/pkg:loaded by srv/aio/step/pkg.sls  
-- fileserver+/template/pkg/base.json:default  
-- fileserver+/template/pkg/tomcat.json:for label:\*,tocmat  

    
