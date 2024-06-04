#!/bin/bash
/usr/sbin/useradd -s /bin/bash -m ritesh;
mkdir /home/ritesh/.ssh;
chmod -R 700 /home/ritesh;
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXIc7d4e3PUgJcvPNFSSgq4Z8xPQH4AHXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXO7eQm7o0kNo7gJgK55oUGZgGKYAX6aex1SL/SZgxsD1isAxd8DjKrzRaCSwPws02CN4Ok+Xiz1u48yb3z22yXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXJ/C/UpMnrhwxIgfaSXKtaa5U2uoDbCj+VxfQntOec2gax2jIoSBXJaRr4yvKPQd0v+A1ItUV1+6Y2321Buheh9giAqSvn95BapHm2GZd7hqX9pmziLxiqB+J94CCVdfTFCnhG0CfGWuTFsqmmUcWX5HxujreKKUFD8nB5BZhPt+gBN0WiMqVWHN3Dj4WdCbrxWLfBX2KRwo/vIJQDXuCe0EF6IsRR3HzO+KA/K5yw/0KohPLVJ7C6hyUr5Ta/RlR6N2HMOA0= ritesh@DESKTOP-02A84PF" >> /home/ritesh/.ssh/authorized_keys;
chmod 600 /home/ritesh/.ssh/authorized_keys;
chown ritesh:ritesh /home/ritesh/.ssh -R;
echo "ritesh  ALL=(ALL)  NOPASSWD:ALL" > /etc/sudoers.d/ritesh;
chmod 440 /etc/sudoers.d/ritesh;
###############################################################################
yum install -y httpd;
systemctl start httpd && systemctl enable httpd;
echo "HelloWorld" >> /var/www/html/index.html
