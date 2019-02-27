#!py
'''
readable config should in template/pkg/*.json: 
{"pkg": ["telnet","vi"]}
'''
import os,logging

def run():
	log=logging.getLogger(__name__)
	globals().update(__pillar__)
	expect=__salt__['aio.expect'](__name__,labels,fileserver)
	pkgs,sources=[],[]
	for i in expect:
		if isinstance(i,(unicode,str)):
			pkgs.append(i)
		if isinstance(i,dict):
			k,v=i.items()[0]
			sources.append({k:'%s/archive/%s'%(fileserver,v)})
	ret={}
	if pkgs:
		ret['rpm(s):pkgs']={'pkg.installed':[{'names':pkgs}]}
	if sources:
		ret['rpm(s):sources']={'pkg.installed':[{'sources':sources}]}
	log.error((ret))
	return ret
