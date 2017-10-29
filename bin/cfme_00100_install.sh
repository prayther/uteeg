#!/bin/bash

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root
cd "${BASH_SOURCE%/*}"

# bsfl are bash libs used in scripts in uteeg
ls -d ~/bsfl || git clone https://github.com/SkypLabs/bsfl.git /root/bsfl

# read configuration (needs to be adopted!)
#source etc/virt-inst.cfg
source ../etc/virt-inst.cfg
source ../etc/virthost.cfg
source ../etc/rhel.cfg
source ~/bsfl/lib/bsfl.sh || exit 1
DEBUG=no
LOG_ENABLED="yes"
SYSLOG_ENABLED="yes"

#runs or not based on hostname; ceph-?? gfs-??? sat-???
if [[ $(hostname -s | awk -F"0" '{print $1}') -ne "ans" ]];then
 echo ""
 echo "Need to run this on the 'gfs' node"
 echo ""
 exit 1
fi

if [[ $(hostname -s | awk -F"0" '{print $2}') -ne "tower" ]];then
 echo ""
 echo "Need to run this on the 'tower' node"
 echo ""
 exit 1
fi

if [[ $(id -u) != "0" ]];then
        echo "Must run as root"
        echo
        exit 1
fi

#when setting up rhev as Infrastructure provider. Take the pem cert, second one listed in results
#https://access.redhat.com/documentation/en-us/red_hat_virtualization/4.0/html-single/rest_api_guide/
[root@cfme ~]# openssl s_client -connect virt-engine.prayther.org:443 -showcerts < /dev/null
: <<'END'
CONNECTED(00000003)
depth=1 C = US, O = prayther.org, CN = virt-engine.prayther.org.86486
verify error:num=19:self signed certificate in certificate chain
---
Certificate chain
 0 s:/C=US/O=prayther.org/CN=virt-engine.prayther.org
   i:/C=US/O=prayther.org/CN=virt-engine.prayther.org.86486
-----BEGIN CERTIFICATE-----
MIIEnzCCA4egAwIBAgICEAQwDQYJKoZIhvcNAQELBQAwTTELMAkGA1UEBhMCVVMx
FTATBgNVBAoMDHByYXl0aGVyLm9yZzEnMCUGA1UEAwwedmlydC1lbmdpbmUucHJh
eXRoZXIub3JnLjg2NDg2MB4XDTE3MTAxNjE2MDQyM1oXDTIyMDkyMTE2MDQyM1ow
RzELMAkGA1UEBhMCVVMxFTATBgNVBAoMDHByYXl0aGVyLm9yZzEhMB8GA1UEAwwY
dmlydC1lbmdpbmUucHJheXRoZXIub3JnMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A
MIIBCgKCAQEArFB6GPAM/JJtdX0c1VWJMgo5yaraog884EJnVAqwUUE/jff+1gZk
Daj2GasVnySavA60JYGI+7DV3hMkfRKY45FUQuwAjzCJvokyCXYUuctGhU8IIb6q
DbBEN0fRESdR/ai0Fn6qma4vf9PIg+zGeZWkmRhjQbqb2Q1lTUQmUCQfsuhjHOK0
kR9qaBDo31rSGyKzjphV4Tnt+MoD5kuOi8ZEDv/phk48bX6Mj24+DN1r1nWwHMT6
9v/QmSR++Z9kYxWq1qDmtprbrB6j1E2SjI5rpf7JOPraDQF4SOr4QdpsII4MM4Py
lQCHAgo0Imy3jU7jXoeL2VnF3YycDN4tNQIDAQABo4IBjTCCAYkwHQYDVR0OBBYE
FHIn66aLL5OZ5TX+hWKjcpuNu/RUMIGNBggrBgEFBQcBAQSBgDB+MHwGCCsGAQUF
BzAChnBodHRwOi8vdmlydC1lbmdpbmUucHJheXRoZXIub3JnOjgwL292aXJ0LWVu
Z2luZS9zZXJ2aWNlcy9wa2ktcmVzb3VyY2U/cmVzb3VyY2U9Y2EtY2VydGlmaWNh
dGUmZm9ybWF0PVg1MDktUEVNLUNBMHYGA1UdIwRvMG2AFD+0D6UxoXG3Oynas1rC
41CvD1q4oVGkTzBNMQswCQYDVQQGEwJVUzEVMBMGA1UECgwMcHJheXRoZXIub3Jn
MScwJQYDVQQDDB52aXJ0LWVuZ2luZS5wcmF5dGhlci5vcmcuODY0ODaCAhAAMAkG
A1UdEwQCMAAwDgYDVR0PAQH/BAQDAgWgMCAGA1UdJQEB/wQWMBQGCCsGAQUFBwMB
BggrBgEFBQcDAjAjBgNVHREEHDAaghh2aXJ0LWVuZ2luZS5wcmF5dGhlci5vcmcw
DQYJKoZIhvcNAQELBQADggEBAKur2o/9awHFcj1mq1e6qWVHMWMw+1C3BOfOhjNP
7y3vUVCtuuDStk2Vvqtc9epI4vDoXK7Nb4BeRXMcauV9d/OeSp8Pj6FpvKVEqNMo
90rozSuoV+qrbYKRU1zbInDu5UJ0zYDMd5gl1DhZLEeuHetHUu2HA3GNhuc9mtYK
JvX8OQakbVtogaPEhmeGmmS2kLesSLkDCD/lxn4F34p5sa+ummvkKYy95PlwpLTs
WxbEL9aSfxbl+7ct89d+cp5GIlMkixT7R3wgQh3RAJR0KYnrlwY62dH8F8yzDs1L
vdTWwqWBoynC4n0KFLF3a5b01/7fOMg8zgwKwA8lrdSzTvE=
-----END CERTIFICATE-----
 1 s:/C=US/O=prayther.org/CN=virt-engine.prayther.org.86486
   i:/C=US/O=prayther.org/CN=virt-engine.prayther.org.86486

#This SECTION... Second certificate. AJP
-----BEGIN CERTIFICATE-----
MIID0jCCArqgAwIBAgICEAAwDQYJKoZIhvcNAQELBQAwTTELMAkGA1UEBhMCVVMx
FTATBgNVBAoMDHByYXl0aGVyLm9yZzEnMCUGA1UEAwwedmlydC1lbmdpbmUucHJh
eXRoZXIub3JnLjg2NDg2MB4XDTE3MTAxNjE2MDQxNVoXDTI3MTAxNTE2MDQxNVow
TTELMAkGA1UEBhMCVVMxFTATBgNVBAoMDHByYXl0aGVyLm9yZzEnMCUGA1UEAwwe
dmlydC1lbmdpbmUucHJheXRoZXIub3JnLjg2NDg2MIIBIjANBgkqhkiG9w0BAQEF
AAOCAQ8AMIIBCgKCAQEAzQGFGl53QWyfiVtflXYrDcrzMJQsYFFSGIeA2/32eer/
ZIUy1yoZXZNBcjFZtJEurx0t3KF1wUCqLKXmJTsb/ZGl/k+jvDJrHpAUBigovPua
6/BKjlBcU/JV/69thKxBZ24TUur8GkJZMaK+vDzoS3NJ4fO4eXSkFs+nzH7xUWlw
Tsp7E8e4nGa+czzOZLt3MjsjwCWO1axY2vW3rTuaKviKYmhgbGnFO54I0UBt29kD
tAn1IAQCObGRriLCUieO4E+1jukTn6K2GWAJ1GPSZpixchoaKNAJzsJZRcLQ3vN8
yRssQS4W4rqpazHozJUS9OOZQwKrIuqDV7ROsDeerQIDAQABo4G7MIG4MB0GA1Ud
DgQWBBQ/tA+lMaFxtzsp2rNawuNQrw9auDB2BgNVHSMEbzBtgBQ/tA+lMaFxtzsp
2rNawuNQrw9auKFRpE8wTTELMAkGA1UEBhMCVVMxFTATBgNVBAoMDHByYXl0aGVy
Lm9yZzEnMCUGA1UEAwwedmlydC1lbmdpbmUucHJheXRoZXIub3JnLjg2NDg2ggIQ
ADAPBgNVHRMBAf8EBTADAQH/MA4GA1UdDwEB/wQEAwIBBjANBgkqhkiG9w0BAQsF
AAOCAQEAMy2Jgy2BkH2ZyWd3sPj7cRUWmcveobIvUIr3NrLjrmw64+Hi9HvhYlE8
+gLEMbyP/lyOVD96bfo5hijUAP1OIpjEP/RxKC+LGFVrPFPr5NdcU73UZEmz9sgm
Xp7h3XdzpKJgsBJ00lGMnUuh2GWYX0YGvV0mZL+oeyHwURe41CgNJlfdQsCg6puT
Gv6ChsXFoqi3vHGt0p5SIDu22Q+EHdsmpXhTh2/w+Uscg12m5uEA3nz6OMW8SNlc
RsgqGrRV4DnWwQ/LNrEbCCWqHUKT/EPLr34OauwlCSzjP53t/dqiJlOerI4ZHeMg
TAIj5qvOBlim14gdjVxXID/QvbjGTw==
-----END CERTIFICATE-----
---
Server certificate
subject=/C=US/O=prayther.org/CN=virt-engine.prayther.org
issuer=/C=US/O=prayther.org/CN=virt-engine.prayther.org.86486
---
No client certificate CA names sent
Peer signing digest: SHA512
Server Temp Key: ECDH, P-256, 256 bits
---
SSL handshake has read 2863 bytes and written 415 bytes
---
New, TLSv1/SSLv3, Cipher is ECDHE-RSA-AES256-GCM-SHA384
Server public key is 2048 bit
Secure Renegotiation IS supported
Compression: NONE
Expansion: NONE
No ALPN negotiated
SSL-Session:
    Protocol  : TLSv1.2
    Cipher    : ECDHE-RSA-AES256-GCM-SHA384
    Session-ID: D38808537CC60E16EEBC8907456B8A86877BF723079483A2477C2014B05E15DD
    Session-ID-ctx:
    Master-Key: 658D94762B542366DA98156B4E9F7A5B20B0EBBCF7EB9B1F265506292EC0467AD356FE35DCBEA4B04658B4FB78C11D81
    Key-Arg   : None
    Krb5 Principal: None
    PSK identity: None
    PSK identity hint: None
    TLS session ticket lifetime hint: 300 (seconds)
    TLS session ticket:
    0000 - f4 32 ad 37 cf aa 91 79-b6 52 59 26 61 19 41 a3   .2.7...y.RY&a.A.
    0010 - 30 84 c0 7c 0c ac e6 5b-cc f6 19 f9 c3 f4 89 f2   0..|...[........
    0020 - 8f 79 75 8b ea b1 0d 9e-f2 e0 22 e3 5c 81 73 7b   .yu.......".\.s{
    0030 - a8 a0 db df 91 b6 8a 29-11 17 5b b3 36 1c 8c 45   .......)..[.6..E
    0040 - d5 23 3d e2 db 16 d8 3e-33 a6 ca 1d db 6b 30 5d   .#=....>3....k0]
    0050 - 08 53 cd b5 b0 5f 07 25-16 bf 85 c2 49 0a 52 c1   .S..._.%....I.R.
    0060 - f0 ff 59 f2 fc aa 39 5e-ca c2 ee 14 18 f4 5a 17   ..Y...9^......Z.
    0070 - b3 43 85 5b 88 12 09 24-9e 03 31 e2 66 c8 2a e3   .C.[...$..1.f.*.
    0080 - c3 5d 6a 5a f0 49 0c 56-6e e1 39 7c 46 99 66 1c   .]jZ.I.Vn.9|F.f.
    0090 - 62 fa 54 04 f6 cd fd 7e-a7 20 a7 3f e9 3f 67 32   b.T....~. .?.?g2
    00a0 - a1 83 c3 d4 93 c7 37 f3-bf 28 b6 15 09 f8 08 47   ......7..(.....G
    00b0 - f1 54 6f 72 8a 90 7b b2-a6 92 95 da 3b d0 0e 45   .Tor..{.....;..E

    Start Time: 1509278594
    Timeout   : 300 (sec)
    Verify return code: 19 (self signed certificate in certificate chain)
---
DONE
END
