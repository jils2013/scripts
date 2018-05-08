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

vbs/multic.vbs  
login in multiple terminals,work on SecureCRT

python/dockeregistryfunc.py  
some functions for docker registry http api  
https://docs.docker.com/registry/spec/api/  

python/salt/aio  
salt-sls scripts in py renderer,initialize the virtual-machine os configuration  
-- begin.sls:run sls in step directory(wildcard)  
-- archive/:archive files,used in step/archive.sls  
  ...  
-- scripts/:scripts called in sls scripts  
-- scripts/expect.py:get the expected result from directory:template based on :label(s) in pillar;running-sls name  
-- scripts/pathinarchive.py:for sls:step/archive.sls,remove useless top-level directory in archive file  
  ...  
-- step/:sls scripts,py renderer  
-- step/archive.sls:unzip/tar packages in directory:archive to special path  
-- step/filesystem.sls			#lvcreate,mkfs,mount  
  ...  
-- template/:config template here  
-- template/source:special one,for salt.state.file source  
   #an template example  
-- template/archive:loaded by step/archive.sls,The directory name is the same as the sls-script(in directory:step) name  
-- template/archive/nginx.json:for label:\*,nginx(define in pillar)  
-- template/archive/base.json:default  
-- template/archive/tomcat.json:for label:\*,tocmat  

    
