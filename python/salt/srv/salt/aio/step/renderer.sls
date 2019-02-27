#!py

def run():
	globals().update(__pillar__)
	expect=__salt__['aio.expect'](__name__,labels,fileserver)
	ret={}
	for i in expect:
		ret.update(__salt__['slsutil.renderer'](path='%s/%s'%(fileserver,i),fileserver=fileserver))
	return ret
