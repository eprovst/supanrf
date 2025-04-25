### Install requirements
- Server: git, rust, and make
- Client: racket

### Autodetection issues:
As detection works by sending out a broadcast and the servers each
replying to the client the involved UDP packets appear unrelated to
a firewall (outgoing is a broadcastadress, incomming is a specific IP).
If autodetection seems to fail, it could help to disable the firwall,
or add a rule to allow all UDP traffic. (On most Linux machines:
`systemctl stop firewalld`.)
