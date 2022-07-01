#!/usr/bin/python3

from lib2to3.pgen2.token import LESSEQUAL
import sys
import re
import math
import argparse
import tempfile
import shutil
import os

# parser = argparse.ArgumentParser(description='Beautify m68k assembly')
# parser.add_argument('--inplace')
#                     help='an integer for the accumulator')
# parser.add_argument('--sum', dest='accumulate', action='store_const',
#                     const=sum, default=max,
#                     help='sum the integers (default: find the max)')

# args = parser.parse_args()

tabsize : int = 4
directiveColumn : int = 16
operandColumn : int = 24
commentColumn : int = 48


def fillTabs(line: str, column : int):
	expanded = line.expandtabs(tabsize)
	length = len(expanded)
	if length >= column:
		line = line + ' '
	else:
		numTabs : int = int(math.ceil(float(column - length) / float(tabsize)))
		line = line + ('\t' * numTabs)
	return line


if __name__ == "__main__":

	# tempfile.NamedTemporaryFile(mode='w+b', buffering=- 1, encoding=None, newline=None, suffix=None, prefix=None, dir=None, delete=True, *, errors=None)

	# print(f"Arguments count: {len(sys.argv)}")

	if len(sys.argv) < 2 or not sys.argv[1]:
     	# FIXME: print to std::err instead
		print("need filename")
		quit()

	# for i, arg in enumerate(sys.argv):
	# 	print(f"Argument {i:>6}: {arg}")

	# Using readlines()
	file1 = open(sys.argv[1], 'r')
	Lines = file1.readlines()

	count = 0
	asmline = re.compile(
		r"""(?P<startcomment>\s*[;*]+.*?)$|((?P<label>\S*:?)?(\s+(?P<directive>\S+))?(\s+(?P<operands>(((".*?")|('.*?')|(\S+?)),?)*))?\s+(?P<endcomment>.*?)?$)""")

	for line in Lines:
		match = asmline.match(line)
		count += 1
		if not match:
			print("NO MATCH: '" + line + "'")
			continue

		startcomment = match.group('startcomment')
		label = match.group('label')
		directive = match.group('directive')
		operands = match.group('operands')
		endcomment = match.group('endcomment')
		out = ""

		if match:
			pass
			# print("{}: startcomment '{}' label '{}' directive '{}' operands '{}' endcomment '{}'".format(
			#  	count, startcomment, label, directive, operands, endcomment))
		else:
			print("No match line Line{}:".format(line))
			assert False


		if startcomment:
			assert not label and not directive and not operands and not endcomment
			out = startcomment.strip()
		else:
			column = 0
			if label:
				out = out + label
			if directive:
				out = fillTabs(out, directiveColumn)
				out = out + directive 		
				if operands:
					out = fillTabs(out, operandColumn)
					out = out + operands
			if endcomment:
				out = fillTabs(out, commentColumn)
				out = out + endcomment.strip()
		print(out)
    
