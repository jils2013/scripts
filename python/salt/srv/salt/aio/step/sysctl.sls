#!py
'''
readable config should in template/sysctl/*.json: 
{
	"sysctl": {
		"kernel.core_uses_pid": 1,
		"kernel.msgmax": 65536,
		"kernel.msgmnb": 65536,
		"vm.swappiness": 20
	}
}

'''
def run():
	ret={}
	globals().update(__pillar__)
	expect=__salt__['aio.expect'](__name__,labels,fileserver)
	
	for k,v in expect.items():
		ret[str(k)]={'sysctl.present':[{'value':v}]}
	return ret
