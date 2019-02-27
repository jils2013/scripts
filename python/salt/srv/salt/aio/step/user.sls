#!py
'''
readable config should in template/user/*.json: 
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
import logging,os

def run():
	log=logging.getLogger(__name__)
	globals().update(__pillar__)
	expect=__salt__['aio.expect'](__name__,labels,fileserver)
	ret={}
	for _user,_attrs in expect.items():
		_workdir=_attrs.pop('workdir',[])
		for _dir in _workdir:
			ret['chown:%s#%s'%(_user,_dir)]={'file.directory':[{'name':_dir,'makedirs':True,'group':_user,'user':_user,'require':[{'user':_user}]}]}
		_initpwd=_attrs.pop('initial password','')
		if _initpwd:
			ret['chpasswd:%s#%s'%(_user,_initpwd)]={'cmd.run':[{'name':'echo %s:%s | chpasswd'%(_user,_initpwd)},{'onchanges':[{'user':_user}]}]}
		attrs=[_attrs]
		if _attrs.has_key('uid'):
			if _attrs.get('gid','')==_attrs['uid'] or _attrs.get('gid_from_name'):
				#ret['group:%s#%s'%(_user,str(_attrs['uid']))]={'group.present':[{'gid':_attrs['uid'],'name':_user,'require_in':[{'user':_user}]}]}
				ret['group:%s#%s'%(_user,str(_attrs['uid']))]={'group.present':[{'gid':_attrs['uid'],'name':_user}]}
				attrs.append({'require':[{'group':_user}]})
		ret[_user]={'user.present':attrs}
	#log.error((ret))
	return ret
