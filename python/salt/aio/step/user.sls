#!py
#import logging
'''
readable config template: 
{
	"user": {
		"app1": {
			"uid": 205,
			"workdir": ["/app1", "/log", "/path1"]
		},
		"use1": {
			"uid": 206
		}
	}
}
'''
def run():
	#log=logging.getLogger(__name__)
	expect=salt.slsutil.renderer(path=salt.cp.cache_file('salt://aio/scripts/expect.py'),default_renderer='py',labels=pillar.get('labels',''),slsname=__name__,retemplate={})
	ret={}
	for _user,_attrs in expect.items():
		_workdir=_attrs.pop('workdir',[])
		for _dir in _workdir:
			ret['chown:%s#%s'%(_user,_dir)]={'file.directory':[{'name':_dir,'makedirs':True,'group':_user,'user':_user,'require':[{'id':_user}]}]}
		ret[_user]={'user.present':[_attrs]}
	return ret
