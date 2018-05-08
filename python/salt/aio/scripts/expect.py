#!py
import os,json

def run():
	fileserver='salt://aio/template'
	#fileserver='http://xxx.com/packages/template'
	ret=retemplate
	_labels=labels.split(',')+['base']
        while _labels:
		_label=_labels.pop()
		if not _label:
			continue
		try:
			_cache=salt.cp.cache_file('%s/%s/%s.json'%(fileserver,slsname,_label))
			_load=json.load(open(_cache))
		except:
			continue
		if not _load.has_key(slsname):
			continue
		if type(_load[slsname])!=type(ret):
			continue
		if type(_load[slsname])==type([]):
			ret+=_load[slsname]
		if type(_load[slsname])==type({}):
			ret.update(_load[slsname])
        return ret
