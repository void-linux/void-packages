if [ -z "${TEXMFCNF}" ]; then
    export TEXMFCNF=/usr/share/tex/texmf-context/web2c
else
    export TEXMFCNF=/usr/share/tex/texmf-context/web2c:${TEXMFCNF}
fi
