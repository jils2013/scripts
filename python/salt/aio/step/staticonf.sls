#!py
import datetime,os
'''
readable config should in template/staticonf/*.json: 
{
	"staticonf": [{
			"name": "/opt/nginx/conf/nginx.conf",
			"source": "salt://aio/template/source/nginx.conf",
			"template": "jinja"
		}
	]
}
'''

def run():
	ret={}
	expect=salt.slsutil.renderer(path=salt.cp.cache_file('salt://aio/scripts/expect.py'),default_renderer='py',labels=pillar.get('labels',''),slsname=__name__,retemplate=[])
	for i in expect:
		ret['file:'+i['name']]={'file.managed':[i]}
	return ret
