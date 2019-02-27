#!py
'''
merge pillar from __master_opts__['pillar'](rest api with salt-ssh)
'''

def run():
	return __opts__.get('__master_opts__',{}).get('pillar',{})
