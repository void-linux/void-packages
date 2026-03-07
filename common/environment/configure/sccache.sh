# export SCCACHE_BASEDIRS="$wrksrc/$build_wrksrc"
export SCCACHE_BASEDIRS="$wrksrc"
export SCCACHE_ERROR_LOG="/tmp/sccache.log"
export SCCACHE_LOG="sccache::util=trace"
