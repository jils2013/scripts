#!py
import re
import logging
'''
readable config template: 
{
	"filesystem": {
		"tctHome": {
			"path": "/opt/tomcat",
			"size": "30G"
		},
		"applogs": {
			"path": "/data",
			"size": "30G"
		}
}
'''
def run():
	log=logging.getLogger(__name__)
	ret={}
	expect=salt.slsutil.renderer(path=salt.cp.cache_file('salt://aio/scripts/expect.py'),default_renderer='py',labels=pillar.get('labels',''),slsname=__name__,retemplate={})

	blkids,mounts,vgs=salt.disk.blkid(),salt.mount.active(),salt.lvm.vgdisplay()
	fstype,lables=mounts['/']['fstype'],[i.get('LABEL','')for i in blkids.values()]
	#labcmd,lablen={'ext3':'tune2fs','ext4':'tune2fs','xfs':'xfs_admin'},{'ext3':16,'ext4':16,'xfs':12}
	needkb,reserved,vgname=0,'/data01',''
	ids={
	'unmount':'unmount.reserved','lvremove':'lvremove.reserved',
	'lv':'lv:%s#%s','mount':'mount:%s','mkfs':'mkfs:%s',
	'label':'label:%s','blockdev':'blockdev:%s'
	}

	#Correct expected based on current status
	#1, input check,duplicate or length > 12.
	#2, skip mounted filesystem/created lv.
	#3, calculate the space needed(kb).
	_labels=[]
	for _label,_attrs in expect.items():
		_path,_size=_attrs['path'],_attrs['size']
		if len(_label)>12 or _label in _labels:
			return {'invalidlabel':{'test.fail_without_changes':[{'name':'label:%s duplicate or length > 12'%_label}]}}
		_labels.append(_label)
		if mounts.has_key(_path):
			del expect[_label]
			continue
		if _label in lables:
			del expect[_label]
			ret[ids['mount']%_label]={'mount.mounted':[{'name':_path,'device':'LABEL='+_label,'fstype':fstype,'mkmnt':True,'dump':'1','pass_num':'2'}]}
			continue
		needkb+=float(re.sub('^([0-9][0-9\.]*)([kKmMgGtT]).*$',lambda m:str(float(m.group(1))*2**({'k':0,'m':1,'g':2,'t':3}[m.group(2).lower()]*10)),_size))
	if not expect:
		return ret or {'mounted':{'test.succeed_without_changes':[{'name':'filesystem(s) all mounted'}]}}

	#Determine which volume group to use
	#1, high priority to using volume groups with enough free space
	#2, no volume group exist to meet the 1 conditions, use the reserved volume group
	for i in vgs.keys():
		if int(vgs[i]['Free Physical Extents'])*int(vgs[i]['Physical Extent Size (kB)'])>needkb:
			vgname=i
			break
	if not vgname:
		_erret={'nospace':{'test.fail_without_changes':[{'name':'No volume group available'}]}}
		if not reserved:
			return _erret
		if not mounts.has_key(reserved):
			return _erret
		_reserved=salt.lvm.lvdisplay(mounts[reserved]['device'])
		if not _reserved:
			return _erret
		_lv,_lvinf=_reserved.popitem()
		_vgname,_name=_lv[5:].split('/') #len('/dev/')=5
		_free=int(vgs[_vgname]['Free Physical Extents'])*int(vgs[_vgname]['Physical Extent Size (kB)'])
		_unused=_free+int(_lvinf['Logical Volume Size'])
		if needkb<_unused:
			vgname=_vgname
			if _free<needkb:
				ret.update({
					ids['unmount']:{'mount.unmounted':[{'name':reserved,'device':_lv,'persist':True}]},
					ids['lvremove']:{'lvm.lv_absent':[{'name':_name,'vgname':_vgname,'require':[{'id':ids['unmount']}]}]}
				})
		else:
			return _erret

	#Generate the final result
	for _label,_attrs in expect.items():
		_lvname,_path,_size='/dev/%s/%s'%(vgname,_label),_attrs['path'],_attrs['size']
		_ids=ids.copy()
		_ids.update({'lv':ids['lv']%(_label,vgname),'mkfs':ids['mkfs']%_label,'mount':ids['mount']%_label,'label':ids['label']%_label,'blockdev':ids['blockdev']%_label})

		ret.update({
			_ids['lv']:{'lvm.lv_present':[{'name':_label,'size':_size,'vgname':vgname}]},
			_ids['mkfs']:{'cmd.run':[{'name':'mkfs.%s -L %s %s'%(fstype,_label,_lvname)},{'onchanges':[{'id':_ids['lv']}]}]},
			_ids['mount']:{'mount.mounted':[{'name':_path,'device':'LABEL='+_label,'fstype':fstype,'mkmnt':True,'dump':'1','pass_num':'2'},{'require':[{'id':_ids['mkfs']}]}]}
		})
		if ret.has_key(_ids['lvremove']):
			ret[_ids['lv']]['lvm.lv_present'][0]['require']=[{'id':_ids['lvremove']}]
		#lsblk not work on rhel/centos 5;blockdev canot support fs-label 
		#ret[_ids['blockdev']]={'blockdev.formatted':[{'name':_lvname,'fs_type':fstype},{'require':[{'id':_ids['lv']}]}]}
		#create label and filesystem together,mount will get expected failure when logical volume has no label(not created by salt)
		#creating label in a separate step will reuse logical volume not created by salt,sometimes is a better choice
		#_ids['mkfs']:{'cmd.run':[{'name':'mkfs -t %s %s'%(fstype,_lvname)},{'onchanges':[{'id':_ids['lv']}]}]}
		#_ids['label']:{'cmd.run':[{'name':'%s -L %s %s'%(labcmd[fstype],_label,_lvname)},{'require':[{'id':_ids['mkfs']}]}]}
	return ret
