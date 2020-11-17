This project heavily borrows from this link:

* https://serverfault.com/questions/696747/routing-from-docker-containers-using-a-different-physical-network-interface-and

It is very simple and just sets a new "default host gateway" for `docker0` bridge.

### TO-DOs
 
* The script does **NOT** clean-up previous resources, nor check for existing ones, and so it's not idempotent (at least for now).