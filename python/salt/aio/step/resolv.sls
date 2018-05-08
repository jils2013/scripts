#!py
import socket
#import logging
'''
readable config should in template/resolv/*.json: 
{
	"resolv": {
		"search": ["a.com", "b.a.com", "d.a.com", "c.a.com"],
		"nameservers": ["10.1.1.2", "10.1.1.3", "10.1.2.3"]
	}
}

'''
def run():
	#log=logging.getLogger(__name__)
	expect=salt.slsutil.renderer(path=salt.cp.cache_file('salt://aio/scripts/expect.py'),default_renderer='py',labels=pillar.get('labels',''),slsname=__name__,retemplate={})
	ret={}

	if not expect.get('nameservers',''):
		return {'nonameservers':{'test.fail_without_changes':[{'name':'resolv:nameservers is null.'}]}}
	ret['etc']={'file.managed':[{'source':'salt://aio/template/source/resolv.py','name':'/etc/resolv.conf','template':'py','backup':'minion','context':{'resolv':expect}}]}
	if grains['id']=='localhost':
		return {'nohostname':{'test.fail_without_changes':[{'name':'hostname not set.'}]}}
	ret[grains['id']]={'host.only':[{'name':grains['fqdn_ip4'].pop(),'hostnames':hostnames(expect)}]}
	return ret

def hostnames(expectresolv):
	#log=logging.getLogger(__name__)
	if pillar.has_key('domain'):
		return [grains['host'],'%s.%s'%(grains['host'],pillar['domain'])]
	if grains['host']==grains['fqdn'] or not grains['fqdn']:
		_search=expectresolv.get('search',grains['dns']['search'])
		while _search:
			_fqdn='%s.%s'%(grains['host'],_search.pop())
			try:
				_ipaddr=socket.gethostbyname(_fqdn)
			except:
				continue
			if _ipaddr in grains['ipv4']:
				return [grains['host'],_fqdn]
	else:
			return [grains['host'],grains['fqdn']]
	return [grains['host']]
