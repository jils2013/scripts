#!/usr/bin/python
import os,sys
path=sys.argv[1]

for _p,_d,_f in os.walk(path):
	if len(_d)!=1 or len(_f)!=0:
		break
if _p!=path:
	print 'mv %s/* %s && rmdir --ignore-fail-on-non-empty -p %s'%(_p,path,_p)
	os.system('mv %s/* %s && rmdir --ignore-fail-on-non-empty -p %s'%(_p,path,_p))
