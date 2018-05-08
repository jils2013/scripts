#!py
import datetime,os
#import logging
'''
archive files should be in aio/archive like follows:
...
tomcat.zip
tomcat.zip.md5
tomcat.zip.md5.md5
jdk1.7.zip
jdk1.7.zip.md5
jdk1.7.zip.md5.md5
...
readable config template: 
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
	#log=logging.getLogger(__name__)
	ret={}
	expect=salt.slsutil.renderer(path=salt.cp.cache_file('salt://aio/scripts/expect.py'),default_renderer='py',labels=pillar.get('labels',''),slsname=__name__,retemplate=[])
	#fileserver='http://xxx.com/packages/'
	fileserver='salt://aio/'

	tmpath,_cleans='/tmp/%s/'%datetime.datetime.now().strftime('%Y%m%d%H%M%S%f'),[]
	ids={
	'path':'path:%s','verify':'verify:%s','extracted':'extracted:%s','resetpath':'resetpath:%s',
	'rsync':'rsync:%s','rsynclean':'rsynclean:%s','exclude':'exclude:%s','recurse':'recurse:%s',
	'clean':'clean:%s','failed':'failed:%s','pull':'pull:%s'
	}
	for i in expect:
		#https://github.com/saltstack/salt/issues/38472,skip_verify:True not work in Salt 2016.11.3
		_name,_source=i['name'].replace('.','_'),'%s/archive/%s'%(fileserver,i['name'])
		_ids,_sourcehash,_tmpath,_verify=ids.copy(),_source+'.md5','%s%s/'%(tmpath,_name),'/.%s.md5'%i['name']
		_ids.update({
		'path':ids['path']%_name,'verify':ids['verify']%_name,'extracted':ids['extracted']%_name,'resetpath':ids['resetpath']%_name,
		'rsync':ids['rsync']%_name,'exclude':ids['exclude']%_name,'rsynclean':ids['rsynclean']%_name,'recurse':ids['recurse']%_name,
		'clean':ids['clean']%_name,'failed':ids['failed']%_name
		})
		if not pathcheck(str(i['path'])):
			return {'invalidpath':{'test.fail_without_changes':[{'name':'invalid or sensitive path:%s'%i['path']}]}}
		if not salt.file.get_diff(_verify,_sourcehash):
			ret[_ids['verify']]={'test.succeed_without_changes':[{'name':'no diffs from '+_sourcehash}]}
			continue
		#_ids['resetpath']:{'cmd.run':[{'name':'p=%s;_p=$p;while true;do p=$p$i;i=$(ls -p $p);[ $(grep -c /$ <<<"$i") != 1 -o $(grep -vc /$ <<<"$i") != 0 ]&&break;done;[ $p == $_p ]||(mv $p/* $_p&&rmdir --ignore-fail-on-non-empty -p $p);echo $p'%_tmpath},{'onchanges':[{'id':_ids['extracted']}]}]},
		ret.update({
			_ids['path']:{'file.directory':[{'name':i['path'],'makedirs':True}]},
			_ids['verify']:{'file.managed':[{'backup':'minion','source':_sourcehash,'name':_verify,'source_hash':_sourcehash+'.md5','require':[{'id':_ids['path']}]}]},
			_ids['extracted']:{'archive.extracted':[{'source':_source,'name':_tmpath,'source_hash':_sourcehash,'onchanges':[{'id':_ids['verify']}]}]},
			_ids['resetpath']:{'cmd.script':[{'name':'salt://aio/scripts/pathinarchive.py','args':_tmpath},{'onchanges':[{'id':_ids['extracted']}]}]},
			_ids['rsynclean']:{'rsync.synchronized':[{'name':i['path'],'source':_tmpath,'delete':True,'onchanges':[{'id':_ids['resetpath']}]}]},
			_ids['clean']:{'file.absent':[{'name':_tmpath},{'require':[{'rsync':i['path']}]}]},
			_ids['failed']:{'file.absent':[{'name':'/.%s.md5'%i['name']},{'onfail':[{'rsync':i['path']}]}]}
		})
		if rendered_sls:
			ret[_ids['path']]['require']=[{'sls':'aio.step.filesystem'}]
		if i.get('exclude',''):
			excludefrom='%s%s.exclude'%(tmpath,i['name'])
			ret[_ids['rsynclean']]['rsync.synchronized'][0].update({'excludefrom':excludefrom,'onchanges':[{'file':excludefrom}]})
			ret.update({
				_ids['rsync']:{'rsync.synchronized':[{'name':i['path'],'source':_tmpath,'onchanges':[{'id':_ids['resetpath']}]}]},
				_ids['exclude']:{'file.managed':[{'source':'salt://aio/template/source/rsyncexclude.py','name':excludefrom,'context':{'exclude':i['exclude']},'template':'py','onchanges':[{'id':_ids['resetpath']}]}]}
			})
		if i.has_key('recurse'):
			_recurse=i['recurse']
			_recurse.update({'name':i['path'],'recurse':_recurse.keys(),'require':[{'rsync':i['path']}]})
			if rendered_sls:
				_recurse['require'].append({'sls':'aio.step.user'})
			ret[_ids['recurse']]={'file.directory':[_recurse]}
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
