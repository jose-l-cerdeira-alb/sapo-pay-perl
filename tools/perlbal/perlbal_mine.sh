#!/bin/bash
ulimit -n 4096

PERLBAL_DEBUG=0

perlbal -c /home/bruno/sapo/trunk/pesquisa_3.0/backend/perlbal/rp-balancer_mine.conf
