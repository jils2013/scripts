dir="/log /applog /heapdump /appfile"
now=$(date +%s)
mtimeinuse=$(($now-60*60*24*${1:-20}))
mtimeunused=$(($now-60*60*24*${2:-10}))

gawk 'BEGIN\
       {d="docker inspect -f \x27{{range .Mounts}}{{.Source}},{{end}}\x27 $(docker ps -q -f volume=/etc/resolv.conf)|grep -oE \"(,|^)(/[^,/]+)+\"";
        while(d|getline D){gsub(/^,/,"",D);exclude[D]=1};close(d);FS=":"}
      function isexclude(absolutepath)\
       {p=absolutepath;while(p){if(p in exclude)return 1;gsub(/\/[^\/]+$/,"",p)};return 0}
      function ignorefailurermdir(workdir,relativepath)\
       {return system("cd "workdir" && rmdir --ignore-fail-on-non-empty -p \""relativepath"\"")}
      $1=="f"\
       {e=isexclude($4);
        if(e&&($3<"'"${mtimeinuse}"'"))print "unlink:"$4"("system("unlink \""$4"\"")")";
        if(!e&&($3<"'"${mtimeunused}"'"))
         {print "unlink:"$4"("system("unlink \""$4"\"")")\nrmdir:"gensub(/\/[^\/]+$/,"","",$4)"("ignorefailurermdir($5,gensub(/\/[^\/]+$/,"","",$6))")"}
       }
      $1=="d"\
       {if(!(isexclude($4)))print "rmdir:"$4"("ignorefailurermdir($5,$6)")"}
     ' <<< "$(for i in $dir;do find $i -mindepth 1 \( -type f -o \( -type d -a -empty \) \) -printf "%y:%d:%T@:%p:%H:%P\n";done)"
