#!py
'''
readable config should in template/rclocal/*.json: 
{"rclocal": ["sh /opt/tomcat/bin/start.sh"]}
'''
import os

def run():
	globals().update(__pillar__)
	expect=__salt__['aio.expect'](__name__,labels,fileserver)
	ret={}
	for i in expect:
		ret['append:{%s}'%i]={'file.append':[{'name':'/etc/rc.d/rc.local','text':i}]}
	return ret
