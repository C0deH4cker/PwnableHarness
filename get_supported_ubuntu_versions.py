#!/usr/bin/env python3
import os
import tempfile
import atexit
import shutil
from typing import Optional
from datetime import datetime, timedelta, timezone
from launchpadlib.launchpad import Launchpad

# launchpadlib loves to write a cache directory to the user's HOME directory.
# Tell to write in /tmp instead.
cachedir = tempfile.mkdtemp()
atexit.register(shutil.rmtree, cachedir)
os.environ["HOME"] = cachedir

ubus = []
exc = None
try:
	lp = Launchpad.login_anonymously(
		consumer_name="series-support-check",
		service_root="production",
		launchpadlib_dir=cachedir,
		timeout=15,
		version="devel")
	series = lp.distributions["ubuntu"].series
	for s in series:
		# We want more than just the supported versions
		dr: Optional[datetime] = s.datereleased
		if dr is None:
			# Seems to happen for upcoming versions, which won't have working
			# Docker images ready yet.
			continue
		
		days_old = (datetime.now(timezone.utc) - dr).days
		if s.supported or days_old < 365 * 4:
			ubus.append((s.version, s.name))
except Exception as e:
	# Now that this only runs during pwnmake image building, we don't need
	# to be nice when an error happens.
	raise

ubus.sort()


print(f'# Autogenerated by {os.path.basename(__file__)}')
if exc is not None:
	print(f'# Exception: {exc}')

print("UBUNTU_VERSIONS := \\")
for p in ubus:
	print(f"\t{p[0]} \\")
print("\n")

print("UBUNTU_ALIASES := \\")
for p in ubus:
	print(f"\t{p[1]} \\")
print("\n")

for p in ubus:
	print(f"UBUNTU_VERSION_TO_ALIAS[{p[0]}] := {p[1]}")
print("\n")

for p in ubus:
	print(f"UBUNTU_ALIAS_TO_VERSION[{p[1]}] := {p[0]}")
print("\n")
