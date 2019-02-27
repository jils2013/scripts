#!py
'''
readable config should in template/sysctl/*.json: 
{
	"sysctl": {
		"kernel.core_uses_pid": 1,
		"kernel.msgmax": 65536,
		"kernel.msgmnb": 65536,
		"kernel.pid_max": 131072,
		"kernel.sem": "250 256000 100 1024",
		"kernel.shmall": 4294967296,
		"kernel.shmmax": 68719476736,
		"kernel.sysrq": 1,
		"net.core.netdev_max_backlog": 4096,
		"net.core.rmem_default": 262144,
		"net.core.rmem_max": 8388608,
		"net.core.wmem_default": 262144,
		"net.core.wmem_max": 8388608,
		"net.ipv4.conf.all.accept_redirects": 0,
		"net.ipv4.conf.default.accept_source_route": 0,
		"net.ipv4.conf.default.rp_filter": 1,
		"net.ipv4.icmp_echo_ignore_broadcasts": 1,
		"net.ipv4.ip_forward": 0,
		"net.ipv4.ip_local_port_range": "10240 65000",
		"net.ipv4.tcp_fin_timeout": 10,
		"net.ipv4.tcp_max_syn_backlog": 4096,
		"net.ipv4.tcp_mem": "8388608 12582912 16777216",
		"net.ipv4.tcp_rmem": "8192 87380 8388608",
		"net.ipv4.tcp_syncookies": 1,
		"net.ipv4.tcp_tw_reuse": 0,
		"net.ipv4.tcp_wmem": "8192 65536 8388608",
		"net.ipv4.udp_mem": "8388608 12582912 16777216",
		"net.ipv4.udp_rmem_min": 16384,
		"net.ipv4.udp_wmem_min": 16384,
		"vm.swappiness": 20
	}
}

'''
def run():
	ret={}
	for k,v in salt.slsutil.renderer(path=salt.cp.cache_file('salt://aio/scripts/expect.py'),default_renderer='py',labels=pillar.get('labels',''),slsname=__name__,retemplate={}).items():
		ret[str(k)]={'sysctl.present':[{'value':v}]}
	return ret