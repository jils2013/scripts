#!py

def run():
	expect,line,search=context['resolv'],[],[]
	for i in expect.get('search',[])+grains['dns']['search']:
		if i in search or not i:
			continue
		search.append(i)
	if search:
		line.append(' '.join(['search']+search))
	line+=['nameserver '+i for i in expect['nameservers']]
	line.append('')
	return '\n'.join(line)
