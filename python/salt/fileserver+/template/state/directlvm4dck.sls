#!py
'''
state for device initialization with direct-lvm on docker
'''
import logging

def run():
	log=logging.getLogger(__name__)
	ret={}
	device,reserved='','/data02'
	pvs=__salt__['lvm.pvdisplay']()
	if __salt__['lvm.lvdisplay']().has_key('/dev/docker/thinpool'):
		device=[i for i,j in pvs.items()if j['Volume Group Name']=='docker'][0]
		ret['created']={'test.succeed_without_changes':[{'name':'docker/thinpool created'}]}
	else:
		for _disk in __salt__['partition.get_block_device']():
			disk='/dev/'+_disk
			partitions=__salt__['partition.list'](disk,unit="kB")
			if partitions['partitions'] or pvs.get(disk,{}).get('Volume Group Name',''):
				continue
			device=disk
			ret[disk]='lvm.pv_absent'
		if not device and __salt__['mount.is_mounted'](reserved):
				_vgname,_lvname=__salt__['lvm.lvdisplay'](__salt__['mount.active']()[reserved]['device']).keys()[0][5:].split('/')
				device=[i for i,j in pvs.items()if j['Volume Group Name']==_vgname][0]
				ret.update({
					'unmount.%s'%reserved:{'mount.unmounted':[{'name':reserved,'persist':True}]},
					'lvremove.%s'%reserved:{'lvm.lv_absent':[{'name':_lvname,'vgname':_vgname,'require':[{'id':'unmount.%s'%reserved}]}]},
					'vgremove.%s'%reserved:{'lvm.vg_absent':[{'name':_vgname},{'require':[{'id':'lvremove.%s'%reserved}]}]},
					'pvremove.%s'%reserved:{'lvm.pv_absent':[{'name':device},{'require':[{'id':'vgremove.%s'%reserved}]}]}
				})
	#log.error((device))
	if not device:
		return {'nodisk':{'test.fail_without_changes':[{'name':'No reserved disk found'}]}}
	else:
		ret['/etc/docker/daemon.json']={'file.managed':[{'source':fileserver+'/template/source/docker_daemon_json','skip_verify':True,'context':{'device':device},'template':'jinja','makedirs':True}]}
	return ret
