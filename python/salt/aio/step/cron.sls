#!py
'''
readable config should in template/cron/*.json: 
{
	"cron": [{
			"name": "13 0 * * * do.sh",
			"user": "root"
		}
	]
}

'''
import logging,os

def run():
	log=logging.getLogger(__name__)
	globals().update(__pillar__)
	expect=__salt__['aio.expect'](__name__,labels,fileserver)
	ret={}
	for i in expect:
		pres=__salt__['cron.ls'](i['user'])['pre']
		_id='job:%s#%s'%(i['user'],i['name'])
		if i['name'] in pres:
			ret[_id]={'test.succeed_without_changes':[{'name':'Job:{%s} is already in %s\'s crontab'%(i['user'],i['name'])}]}
			continue
		_cron=cronset(i['name'])
		if not _cron:
			return {'notinstall':{'test.fail_without_changes':[{'name':'Job:%s can\'t install'%i['name']}]}}
		_cron['user']=i['user']
		ret[_id]={'cron.present':[_cron]}
	#log.error((ret))
	return ret

def cronset(job):
	_job=job.split(' ')
	while '' in _job:
		_job.remove('')
	if _job[0] in ['@reboot','@yearly','@annually','@monthly','@weekly','@daily','@hourly']:
		return {'special':_job[0],'name':' '.join(_job[1:])}
	if len(job)<5:
		return None
	_ind=['minute','hour','daymonth','month','dayweek']
	_ret={}
	for i in range(0,5):
		if _job[i]!='*':
			_ret[_ind[i]]=_job[i]
	_ret['name']=' '.join(_job[5:])	
	return _ret
