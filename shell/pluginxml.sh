awk 'BEGIN{RS="<|>|/>|</";inComment=0;}
     RT=="<"\
      {getline;
       if($1~/^!--/){inComment=1;print "inComment";while(inComment){if(RT==">"&&$NF~/--$/){inComment=0;next}else{if(!getline)exit}}}
       l++;
       if(RT==">"){path=path"."$1;tag=$1;$1="";element=$0}
       if(RT=="/>"){l--;tag=$1;$1="";element=$0}
      }
     RT=="</"\
      {getline;
       tag="";element=""
       split(path,p,".");if(p[l+1]==$1)gsub(/\.[^\.]+$/,"",path)
       l--;
      }
      {if(path==".?xml.Config.VirtualHostGroup"&&tag=="VirtualHostGroup")VirtualHostGroup=gensub(/.*Name="([^"]+).+/,"\\1","",element)
       if(path==".?xml.Config.VirtualHostGroup"&&tag=="VirtualHost")VirtualHost[VirtualHostGroup]=VirtualHost[VirtualHostGroup]","gensub(/.*Name="([^"]+).+/,"\\1","",element)
       if(path==".?xml.Config.ServerCluster"&&tag=="ServerCluster")ServerClusterName=gensub(/.*Name="([^"]+).+/,"\\1","",element)
       if(path==".?xml.Config.ServerCluster.Server"&&tag=="Transport")Transportlist[ServerClusterName]=Transportlist[ServerClusterName]","gensub(/.*Hostname="([^"]+).+Port="([^"]+).+/,"\\1:\\2","",element)
       if(path==".?xml.Config.UriGroup"&&tag=="UriGroup")UriGroupName=gensub(/.*Name="([^"]+).+/,"\\1","",element)
       if(path==".?xml.Config.UriGroup"&&tag=="Uri")Uri[UriGroupName]=Uri[UriGroupName]","gensub(/.*Name="([^"]+).+/,"\\1","",element)
       if(path==".?xml.Config"&&tag=="Route")print VirtualHost[gensub(/.*VirtualHostGroup="([^"]+).+/,"\\1","",element)],Uri[gensub(/.*UriGroup="([^"]+).+/,"\\1","",element)],Transportlist[gensub(/.*ServerCluster="([^"]+).+/,"\\1","",element)]
      }
    ' plugin-cfg.xml
