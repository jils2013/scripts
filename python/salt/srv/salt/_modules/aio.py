'''
merge configuration from fileserver/sls/label(s).json.

salt tgt aio.expect sysctl tocmat example.com/aio

'''
import json,logging,os

log=logging.getLogger(__name__)

def __virtual__():
	return 'aio'

def expect(sls,labels,fileserver):
	if not labels or not fileserver:
		log.error('labels/fileserver not set in pillar.')
		return ret
	_labels=labels.split(',')+['base']
	ret={}
	while _labels:
		_label=_labels.pop()
		if not _label:
			continue
		try:
			#only supprt path start with http:// on salt-ssh;
			_cache=__salt__['cp.cache_file']('%s/template/%s/%s.json'%(fileserver,sls,_label))
			_load=json.load(open(_cache))
		except:
			log.error(('load %s:%s failed ...'%(_label,sls)))
			continue
		if not _load.has_key(sls):
			continue
		if isinstance(_load[sls],list):
			ret=(ret or [])+_load[sls]
		if isinstance(_load[sls],dict):
			ret.update(_load[sls])
	return ret
