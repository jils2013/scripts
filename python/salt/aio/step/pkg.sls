#!py
'''
readable config template: 
{"pkg": ["telnet","vi"]}
'''
def run():
	return {'rpm(s)':{'pkg.installed':[{'names':salt.slsutil.renderer(path=salt.cp.cache_file('salt://aio/scripts/expect.py'),default_renderer='py',labels=pillar.get('labels',''),slsname=__name__,retemplate=[])}]}}
