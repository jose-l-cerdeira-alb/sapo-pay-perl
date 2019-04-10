#!/bin/sh
echo ""
echo "trying to disable current cache on dev and staging...."
echo ""
(echo "delete invalidate_controller_cache-https://dev.wallet.pt"; echo "quit") | nc vm-pay01.vmdev.bk.sapo.pt 11211
(echo "delete invalidate_controller_cache-https://dev.wallet.pt"; echo "quit") | nc vm-pay02.vmdev.bk.sapo.pt 11211
(echo "delete invalidate_controller_cache-https://wallet.pt.local"; echo "quit") | nc vm-pay01.vmdev.bk.sapo.pt 11211
(echo "delete invalidate_controller_cache-https://wallet.pt.local"; echo "quit") | nc vm-pay01.vmdev.bk.sapo.pt 11211
(echo "delete invalidate_controller_cache-https://www.pay.stg.sapo.pt"; echo "quit") | nc paystg-negocio01.paystg.bk.sapo.pt 11211
(echo "delete invalidate_controller_cache-https://www.pay.stg.sapo.pt"; echo "quit") | nc paystg-negocio02.paystg.bk.sapo.pt 11211

echo ""




