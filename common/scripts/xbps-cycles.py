#!/usr/bin/env python3

import os
import sys
import glob
import subprocess
import multiprocessing

from argparse import ArgumentParser

import networkx as nx


def enum_depends(pkg, xbpsdir, cachedir):
	'''
	Return a pair (pkg, [dependencies]), where [dependencies] is the list
	of dependencies for the given package pkg. The argument xbpsdir should
	be a path to a void-packages repository. Dependencies will be
	determined by invoking

		<xbpsdir>/xbps-src show-build-deps <pkg>

	unless <cachedir>/deps-<pkg> file exist, in that case it is read.

	If the return code of this call nonzero, a message will be printed but
	the package will treated as if it has no dependencies.
	'''
	if cachedir:
		cachepath = os.path.join(cachedir, 'deps-' + pkg)
		try:
			with open(cachepath) as f:
				return pkg, [l.strip() for l in f]
		except FileNotFoundError:
			pass

	cmd = [os.path.join(xbpsdir, 'xbps-src'), 'show-build-deps', pkg]

	try:
		deps = subprocess.check_output(cmd)
	except subprocess.CalledProcessError as err:
		print('xbps-src failed to find dependencies for package', pkg)
		deps = [ ]
	else:
		deps = [d for d in deps.decode('utf-8').split('\n') if d]
		if cachedir:
			with open(cachepath, 'w') as f:
				for d in deps:
					print(d, file=f)

	return pkg, deps


def find_cycles(depmap, xbpsdir):
	'''
	For a map depmap: package -> [dependencies], construct a directed graph
	and identify any cycles therein.

	The argument xbpsdir should be a path to the root of a void-packages
	repository. All package names in depmap will be appended to the path
	<xbpsdir>/srcpkgs and reduced with os.path.realpath to coalesce
	subpackages.
	'''
	G = nx.DiGraph()

	for i, deps in depmap.items():
		path = os.path.join(xbpsdir, 'srcpkgs', i)
		i = os.path.basename(os.path.realpath(path))

		for j in deps:
			path = os.path.join(xbpsdir, 'srcpkgs', j.strip())
			j = os.path.basename(os.path.realpath(path))
			G.add_edge(i, j)

	for c in nx.strongly_connected_components(G):
		if len(c) < 2: continue
		pkgs = nx.to_dict_of_lists(G, c)

		p = min(pkgs.keys())
		cycles = [ ]
		while True:
			cycles.append(p)

			# Cycle is complete when package is not in map
			try: deps = pkgs.pop(p)
			except KeyError: break

			# Any of the dependencies here contributes to a cycle
			p = min(deps)
			if len(deps) > 1:
				print('Multipath: {} -> {}, choosing first'.format(p, deps))

		if cycles:
			print('Cycle: ' + ' -> '.join(cycles) + '\n')


if __name__ == '__main__':
	parser = ArgumentParser(description='Cycle detector for xbps-src')
	parser.add_argument('-j', '--jobs', default=None,
			type=int, help='Number of parallel jobs')
	parser.add_argument('-c', '--cachedir', default=None,
			help='Directory used to cache build dependencies (must exist)')
	parser.add_argument('-d', '--directory',
			default=None, help='Path to void-packages repo')
	parser.add_argument('-Q', dest='check_pkgs', action='store_const',
			const='yes', help='Use build dependencies for check -Q')
	parser.add_argument('-K', dest='check_pkgs', action='store_const',
			const='full', help='Use build dependencies for check -K')

	args = parser.parse_args()

	if not args.directory:
		try: args.directory = os.environ['XBPS_DISTDIR']
		except KeyError: args.directory = '.'

	if args.check_pkgs:
		os.environ['XBPS_CHECK_PKGS'] = args.check_pkgs

	pool = multiprocessing.Pool(processes = args.jobs)

	pattern = os.path.join(args.directory, 'srcpkgs', '*')
	pkgs = {os.path.realpath(p) for p in glob.iglob(pattern)}

	depargs = ((os.path.basename(g), args.directory, args.cachedir) for g in pkgs)
	depmap = dict(pool.starmap(enum_depends, depargs))

	find_cycles(depmap, args.directory)
