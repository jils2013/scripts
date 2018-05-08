#!py
'''
readable config should in template/rclocal/*.json: 
{"rclocal": ["sh /opt/tomcat/bin/start.sh"]}
'''
def run():
	expect=salt.slsutil.renderer(path=salt.cp.cache_file('salt://aio/scripts/expect.py'),default_renderer='py',labels=pillar.get('labels',''),slsname=__name__,retemplate=[])
	ret={}
	for i in expect:
		ret['append:{%s}'%i]={'file.append':[{'name':'/etc/rc.d/rc.local','text':i}]}
	return ret
