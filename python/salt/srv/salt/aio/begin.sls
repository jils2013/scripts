#!py
import os

def run():
	home=__file__.split(os.sep)[-2]
	return {'include':['%s.step.*'%home]}
