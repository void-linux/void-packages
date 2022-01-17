Don't forget to generate the Secret Key:

   You can create a secret key using a variety of methods:

   A. Wait around for some random data (recommended for the paranoid):
      $ dd if=/dev/random bs=1 count=1024 >/etc/munge/munge.key

   B. Grab some pseudorandom data (recommended for the impatient):
      $ dd if=/dev/urandom bs=1 count=1024 >/etc/munge/munge.key

   C. Enter the hash of a password:
      $ echo -n "foo" | sha1sum | cut -d' ' -f1 >/etc/munge/munge.key

The Key-File must owned by munge with the permission 600
