Please note that go-ipfs 0.4.0 introduces a change that breaks compatibility
with earlier versions at the networking layer.  Thus, it will be unable to
communicate with peers running versions of go-ipfs older than 0.4.0.
If you are upgrading from version 0.3.x, you should install
the fs-repo-migrations package and run the fs-repo-migrations tool
to upgrade your IPFS filesystem repository.
