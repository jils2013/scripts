#!py
import datetime,os,logging
'''
archive files should be in aio/archive like follows:
tomcat.zip
tomcat.zip.md5
jdk1.7.zip
jdk1.7.zip.md5
readable config should be in template/archive/*.json: 
{
	"archive": [{
			"name": "tomcat.zip",--filename in path $fileserver
			"path": "/opt/tomcat",--path to extract
			"exclude": ["webapp/", "logs/", "bin/"],--rsync exclude files,files not in new archive will be delete;
			"recurse": {--all files will be chown ...
				"user": "tomcat",
				"group": "tomcat"
			}
		}, {
			"name": "jdk1.7.zip",
			"path": "/usr/java/jdk1.7"
		}
	]
}
'''

def run():
	log=logging.getLogger(__name__)
	ret={}
	globals().update(__pillar__)
	expect=__salt__['aio.expect'](__name__,labels,fileserver)

	tmpath,_cleans='/tmp/%s/'%datetime.datetime.now().strftime('%Y%m%d%H%M%S%f'),[]
	ids={
	'path':'path:%s','verify':'verify:%s','extracted':'extracted:%s',
	'rsync':'rsync:%s','rsynclean':'rsynclean:%s','exclude':'exclude:%s','recurse':'recurse:%s',
	'clean':'clean:%s','failed':'failed:%s'
	}
	for i in expect:
		_name,_source=i['name'].replace('.','_'),'%s/archive/%s'%(fileserver,i['name'])
		_ids,_sourcehash,_tmpath,_verify=ids.copy(),_source+'.md5','%s%s/'%(tmpath,_name),'/.%s.md5'%i['name']
		_ids.update({
		'path':ids['path']%_name,'verify':ids['verify']%_name,'extracted':ids['extracted']%_name,
		'rsync':ids['rsync']%_name,'exclude':ids['exclude']%_name,'rsynclean':ids['rsynclean']%_name,'recurse':ids['recurse']%_name,
		'clean':ids['clean']%_name,'failed':ids['failed']%_name
		})
		if not pathcheck(str(i['path'])):
			return {'invalidpath':{'test.fail_without_changes':[{'name':'invalid or sensitive path:%s'%i['path']}]}}
		ret.update({
			_ids['path']:{'file.directory':[{'name':i['path'],'makedirs':True}]},
			_ids['verify']:{'file.managed':[{'backup':'minion','source':_sourcehash,'name':_verify,'skip_verify':True,'require':[{'id':_ids['path']}]}]},
			_ids['extracted']:{'archive.extracted':[{'source':_source,'name':_tmpath,'source_hash':_sourcehash,'enforce_toplevel':False,'trim_output':10},{'onchanges':[{'id':_ids['verify']}]}]},
			_ids['rsynclean']:{'arc_rsync.synchronized':[{'name':i['path'],'source':_tmpath,'delete':True,'additional_opts':['--quiet']},{'onchanges':[{'id':_ids['extracted']}]}]},
			_ids['clean']:{'file.absent':[{'name':_tmpath},{'require':[{'id':_ids['rsynclean']}]}]},
			_ids['failed']:{'file.absent':[{'name':'/.%s.md5'%i['name']},{'onfail':[{'id':_ids['rsynclean']}]}]}
		})
		if rendered_sls:
			ret[_ids['path']]['file.directory'].append({'require':[{'sls':'aio.step.filesystem'}]})
		if i.get('exclude',''):
			excludefrom='%s%s.exclude'%(tmpath,i['name'])
			ret[_ids['rsynclean']]['arc_rsync.synchronized'][0]['excludefrom']=excludefrom
			ret[_ids['rsynclean']]['arc_rsync.synchronized'][1]['onchanges']=[{'file':excludefrom}]
			ret[_ids['clean']]['file.absent'][1]['require'].append({'id':_ids['rsync']})
			ret[_ids['failed']]['file.absent'][1]['onfail'].append({'id':_ids['rsync']})
			ret.update({
				_ids['rsync']:{'arc_rsync.synchronized':[{'name':i['path'],'source':_tmpath,'additional_opts':['--quiet']},{'onchanges':[{'id':_ids['extracted']}]}]},
				_ids['exclude']:{'file.managed':[{'source':fileserver+'/template/source/rsyncexclude.py','name':excludefrom,'skip_verify':True,'context':{'exclude':i['exclude']},'template':'py'},{'onchanges':[{'id':_ids['extracted']}]}]}
			})
		if i.has_key('recurse'):
			_recurse=i['recurse']
			_recurse.update({'name':i['path'],'recurse':_recurse.keys(),'require':[{'arc_rsync':i['path']}]})
			if rendered_sls:
				_recurse['require'].append({'sls':'aio.step.user'})
			ret[_ids['recurse']]={'file.directory':[_recurse]}
			ret[_ids['failed']]['file.absent'][1]['onfail'].append({'id':_ids['recurse']})
		_cleans.append(_ids['clean'])
	if _cleans:
		ret['cleanall']={'file.absent':[{'name':tmpath},{'require':_cleans}]}
	#log.error((ret))
	return ret

def pathcheck(path):
	DANGER=['','bin','boot','cgroup','dev','etc','home','lib','lib64','net','proc','root','sbin','selinux','srv','sys','tmp']
	WARN=['opt','usr','var']

	if not os.path.isabs(path):
		return False
	_p=str.strip(path).split('/')
	if _p[1] in DANGER:
		return False
	if _p[1] in WARN:
		for i in _p[:]:
			if i in WARN+DANGER:
				_p.remove(i)
	if not _p:
		return False
	return True
