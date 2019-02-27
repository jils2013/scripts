#!py
import logging

def run():
	log=logging.getLogger(__name__)
	#log.error((context['exclude']))
	return '\n'.join(context['exclude'])
