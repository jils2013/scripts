#!py
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
import datetime,os,logging

def run():
	log=logging.getLogger(__name__)
	ret={}
	globals().update(__pillar__)
	log.error((__name__,labels,fileserver))
	expect=__salt__['aio.expect'](__name__,labels,fileserver)
	for i in expect:
		i['source']=fileserver+i['source']
		i['skip_verify']=True
		if rendered_sls:
			i['require']=[{'sls':'aio.step.archive'}]
		ret['file:'+i['name']]={'file.managed':[i]}
	return ret
