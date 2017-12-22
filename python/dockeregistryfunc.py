#!/usr/bin/python
# -*- coding: utf-8 -*-

import json
import urllib2
import urllib
import re
import base64
import threading
import time

# Bearer realm...
user = {'http://youregistry.com/v2/token': ['user', 'password']}

# get running images from kubernetes deployments
def getrunimgs(url):
    images = []
    for i in json.loads(urllib2.urlopen('http://' + url
                        + '/apis/extensions/v1beta1/deployments'
                        ).read())['items']:
        for c in i['spec']['template']['spec']['containers']:
            if c['image'] not in images:
                images.append(c['image'])
    return images

# get token from docker registry by scode/service/user
def getoken(authenticate):
    auth = {}
    re.sub('([^,=]+)="([^"]+)"', lambda m: \
           auth.update({m.group(1): m.group(2)}), authenticate)
    authurl = auth.pop('Bearer realm')
    return json.loads(urllib2.urlopen(urllib2.Request(authurl + '?'
                      + urllib.urlencode(auth), None,
                      {'Authorization': 'Basic '
                      + base64.urlsafe_b64encode(':'.join(user[authurl]))})).read())['token'
            ]

# parse response from docker registry
def urlopenrel(opener, request, response):
    method = request.get_method()
    if method == 'DELETE':
        return response.code
    if method == 'HEAD':
        return response.headers
    if not response.headers.has_key('link'):
        return json.loads(response.read())
    url = response.url
    while response.headers.has_key('link'):
    # Link: <<url>?n=<n from the request>&last=<last tag value from previous response>>; rel="next"
        request = urllib2.Request(url + '?n='
                                  + urllib2.urlparse.parse_qs((response.headers['link'
                                  ])[1:-13])['n'][0] + '0')
        request.get_method = lambda : method
        response = opener.open(request)
    return json.loads(response.read())

# create request to docker registry
def apirequest(url, method):
    opener = urllib2.build_opener()
    opener.addheaders = [('Accept',
                         'application/vnd.docker.distribution.manifest.v2+json'
                         )]
    request = urllib2.Request(url)
    request.get_method = lambda : method or 'GET'
    try:
        response = opener.open(request)
        return urlopenrel(opener, request, response)
    except urllib2.URLError, err:
        if not hasattr(err, 'code'):
            return err.reason
        if err.code != 401:
            return err.msg
        try:
            opener.addheaders.append(('Authorization', 'Bearer '
                    + getoken(err.headers.getheader('www-authenticate'
                    ))))
            response = opener.open(request)
            return urlopenrel(opener, request, response)
        except urllib2.HTTPError, httperror:
            return httperror

# get all repositories from docker registry
def getrepositories(host):
    return apirequest('http://' + host + '/v2/_catalog', ''
                      )['repositories']

# get tags by repositorie
def getags(repo):
    r = apirequest('http://' + repo[0] + '/v2/' + repo[1] + '/tags/list'
                   , '')
    if type(r) != type({}):
        return r
    else:
        return sorted(r['tags'] or [])

# delete images with image tag
def deleteimagewithtag(img):
    digest = apirequest('http://' + img[0] + '/v2/' + img[1]
                        + '/manifests/' + img[2], 'HEAD')
    if type(digest) == type(''):
        return False
    delete = apirequest('http://' + img[0] + '/v2/' + img[1]
                        + '/manifests/' + digest['Docker-Content-Digest'
                        ], 'DELETE')
    if delete != 202:
        return False
    return True

def parallelrun(func, arg, n):
    ret = []
    while arg:
        if threading.activeCount() > n:
            time.sleep(0.1)
            continue
        thread = threading.Thread(target=lambda r: ret.append([r,
                                  func(r)]), args=(arg.pop(), ))
        thread.start()
    while threading.activeCount() - 1:
# ........print threading.activeCount(),len(ret)
        time.sleep(1)
    return ret
			
