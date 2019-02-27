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
import socket,os,logging

def run():
	log=logging.getLogger(__name__)
	globals().update(__pillar__)
	expect=__salt__['aio.expect'](__name__,labels,fileserver)
	ret={}

	if not expect.get('nameservers',''):
		return {'nonameservers':{'test.fail_without_changes':[{'name':'resolv:nameservers is null.'}]}}
	ret[grains['id']+':/etc/resolv.conf']={'file.managed':[{'source':fileserver+'/template/source/resolv.conf','name':'/etc/resolv.conf','template':'py','backup':'minion','skip_verify':True,'context':{'resolv':expect}}]}
	if grains['id']=='localhost':
		return {'nohostname':{'test.fail_without_changes':[{'name':'hostname not set.'}]}}
	ipaddr=grains['ip4_interfaces'][__salt__['network.default_route']('inet')[0]['interface']][0]
	ret[grains['id']+':/etc/hosts']={'host.only':[{'name':ipaddr,'hostnames':hostnames(expect)}]}
	ret[grains['id']+':/etc/hostname']={'file.managed':[{'source':fileserver+'/template/source/hostname_etc','skip_verify':True,'name':'/etc/hostname','template':'jinja','context':{'host':grains['host']}}]}
	#log.error((ret))
	return ret

def hostnames(expectresolv):
	log=logging.getLogger(__name__)
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
