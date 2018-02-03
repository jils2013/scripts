#!/usr/bin/python
# -*- coding: utf-8 -*-

import json,urllib2,urllib,re,base64,threading,time

# Bearer realm...
user = {'http://youregistry.com/v2/token': ['user', 'password']}

# get running images from kubernetes deployments
def getrunimgs(url):
	images=[]
	for i in json.loads(urllib2.urlopen('http://%s/apis/extensions/v1beta1/deployments'%url).read())['items']:
		for c in i['spec']['template']['spec']['containers']:
			if c['image'] not in images:
				images.append(c['image'])
	return images

# get token from docker registry by scode/service/user
def getoken(authenticate):
	auth={}
	re.sub('([^,=]+)="([^"]+)"',lambda m:auth.update({m.group(1):m.group(2)}),authenticate)
	authurl=auth.pop('Bearer realm')
	return json.loads(urllib2.urlopen(urllib2.Request(authurl+'?'+urllib.urlencode(auth),None,{'Authorization':'Basic '+base64.urlsafe_b64encode(':'.join(user[authurl]))})).read())['token']

# parse response from docker registry
def urlopenrel(opener,request,response):
	method=request.get_method()
	if method=="DELETE":
		return {'result':response.code,'detail':response.msg}
	if method=="HEAD" or response.headers.get('Content-Length',1)=='0':
		return response.headers
	if not response.headers.has_key('link'):
		res=response.read()
		if response.headers['Content-Type']=='application/octet-stream':
			return res
		return json.loads(res)
	url=response.url
	while response.headers.has_key('link'):
		#request=urllib2.Request(request.type+'://'+request.host+response.headers['link'][1:-13])
		request=urllib2.Request(url+'?n='+urllib2.urlparse.parse_qs(response.headers['link'][1:-13])['n'][0]+'0')
		request.get_method=lambda: method
		response=opener.open(request)
	return json.loads(response.read())

# create request to docker registry
def apirequest(url,method,**reqdata):
	opener=urllib2.build_opener()
	opener.addheaders=[('Accept','application/vnd.docker.distribution.manifest.v2+json')] 
	request=urllib2.Request(url)
	if reqdata:
		request=urllib2.Request(url=url,data=reqdata.get('data',None),headers=reqdata.get('headers',{}))
	request.get_method=lambda: method or 'GET'
	try:
		response=opener.open(request)
		return urlopenrel(opener,request,response)
	except urllib2.URLError as err:
		if not hasattr(err, 'code'):
			return {'result':-1,'detail':err.reason}
		if err.code!=401:
			return {'result':err.code,'detail':err.msg}
		try:
			opener.addheaders.append(('Authorization','Bearer '+getoken(err.headers.getheader('www-authenticate'))))
			response=opener.open(request)
			return urlopenrel(opener,request,response)
		except urllib2.HTTPError as httperror:
			return {'result':httperror.code,'detail':httperror.msg}

# get all repositories from docker registry
def getrepositories(host):
	return apirequest('http://%s/v2/_catalog'%host,'')['repositories']

# get tags by repositorie
def getags(repo):
	r=apirequest('http://%s/v2/%s/tags/list'%tuple(repo),'')
	return sorted(r.get('tags',None) or [])

# delete images with image tag
def deleteimagewithtag(img):
	digest=apirequest('http://%s/v2/%s/manifests/%s'%tuple(img),'HEAD')
	if not digest.has_key('Docker-Content-Digest'):
		return False
	delete=apirequest('http://%s/v2/%s/manifests/%s'%tuple(img[0:2]+[digest['Docker-Content-Digest']]),'DELETE')
	if delete.get('result','')=='202':
		return False
	return True

def parallelrun(func,arg,n):
	ret=[]
	while arg:
		if threading.activeCount()>n:
			time.sleep(0.1)
			continue	
		thread=threading.Thread(target=lambda r:ret.append([r,func(r)]),args=(arg.pop(),))
		thread.start()
	while threading.activeCount()-1:
#		print threading.activeCount(),len(ret)
		time.sleep(1)
	return ret

#upload blob/layer
def uplayer(layerupload):
	#HEAD
	img,tgt,digest=layerupload[0][0],layerupload[0][1],layerupload[1]
	uploaded=apirequest('http://%s/v2/%s/blobs/%s'%(tgt,img[1],digest),'HEAD')
	if uploaded.has_key('Docker-Content-Digest'):
		return True
	#PUSH
	layer=apirequest('http://%s/v2/%s/blobs/%s'%(img[0],img[1],digest),'')
	if type(layer)!=type(''):
		return False
	#POST
	post=apirequest('http://%s/v2/%s/blobs/uploads/?%s'%(tgt,img[1],urllib.urlencode({'digest':digest})),'POST')
	if not post.has_key("Location"):
		return False
	#PATCH
	patch=apirequest(post["Location"],'PATCH',data=layer,headers={"Content-Type":"application/octet-stream"})
	if not post.has_key("Location"):
		return False
	#PUT
	put=apirequest(post["Location"]+'&'+urllib.urlencode({'digest':digest}),'PUT')
	if not put.has_key('Docker-Content-Digest'):
		return False
	return True

#move a image
def mvimg(imgpush):
	img=imgpush[0]
	manifests=apirequest('http://%s/v2/%s/manifests/%s'%(imgpush[1],img[1],img[2]),'HEAD')
	if manifests.has_key('Docker-Content-Digest'):
		print 'R:',img,manifests.get('Docker-Content-Digest','')
		return manifests['Docker-Content-Digest']
	manifests=apirequest('http://%s/v2/%s/manifests/%s'%tuple(img),'')
	if not manifests.has_key('layers'):
		return False	
	for i in manifests['layers']:
		_res=uplayer([imgpush,i['digest']])
		if not _res:
			return False
	#for i in parallelrun(uplayer,[[imgpush,i['digest']]for i in manifests['layers']],10):
	#	if not i[1]:
	#		return False
	uplayer([imgpush,manifests['config']['digest']])
	put=apirequest('http://%s/v2/%s/manifests/%s'%(imgpush[1],img[1],img[2]),'PUT',data=json.dumps(manifests),headers={"Content-Type":"application/vnd.docker.distribution.manifest.v2+json"})
	print 'P:',img,put.get('Docker-Content-Digest','')
	return put.get('Docker-Content-Digest',False)
