The default cgroup mode has changed from "hybrid" to "unified". Users
should update CGROUP_MODE to "unified" (recommended) or "hybrid" in
rc.conf.

Note that some container runtimes and images may not work optimally or
at all with the "hybrid" cgroup mode due to ongoing deprecation of
cgroup1 support.
