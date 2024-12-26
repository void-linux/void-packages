In a future release of the runit-void package, the default cgroup mode
will change from "hybrid" to "unified". Users should explicitly specify
"unified" (recommended) or "hybrid" CGROUP_MODE in rc.conf.

Note that some container runtimes and images may not work optimally or
at all with the "hybrid" cgroup mode due to ongoing deprecation of
cgroup1 support.
