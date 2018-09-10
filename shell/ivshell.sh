#[root@localhost workdir]# grep -R "" .
#./source/b/t2:${c}
#./source/b/t2:${b} ${a}
#./source/a/t1:${a}
#./source/a/t1:${b}
#./source/c/t3:${c} ${c} ....
#./source/c/t3:${b} ${a} ....
#[root@localhost workdir]# cd 
#[root@localhost ~]# cat c.json 
#{
#"a":"VAR-A",
#"b":"VAR-B",
#"c":"VAR-C"
#}
#[root@localhost ~]# jq -r '. | keys[] as $k | "\($k)=\(.[$k])"' c.json
#a=VAR-A
#b=VAR-B
#c=VAR-C
#[root@localhost ~]#eval `jq -r '. | keys[] as $k | "\($k)=\(.[$k])"' c.json`
#[root@localhost ~]# cd workdir/source/
#
#[root@localhost source]# find . -mindepth 1 -type d -exec mkdir -p ../dest/{} \;
#[root@localhost source]# for i in `find . -type f`;do eval echo "\"$(<$i)\"">../dest/$i;done
#[root@localhost source]# grep -R "" ..
#../dest/b/t2:VAR-C
#../dest/b/t2:VAR-B VAR-A
#../dest/a/t1:VAR-A
#../dest/a/t1:VAR-B
#../dest/c/t3:VAR-C VAR-C ....
#../dest/c/t3:VAR-B VAR-A ....
#../source/b/t2:${c}
#../source/b/t2:${b} ${a}
#../source/a/t1:${a}
#../source/a/t1:${b}
#../source/c/t3:${c} ${c} ....
#../source/c/t3:${b} ${a} ....

#解析json，并作为环境变量赋值
eval `jq -r '. | keys[] as $k | "\($k)=\(.[$k])"' c.json`

cd workdir/source/
#创建目录
find . -mindepth 1 -type d -exec mkdir -p ../dest/{} \;
#替换文件
for i in `find . -type f`;do eval echo "\"$(<$i)\"">../dest/$i;done
