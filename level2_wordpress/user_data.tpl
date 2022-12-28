#!/bin/bash
  db_username=${db_username}
  db_user_password=${db_user_password}
  db_name=${db_name}
  db_RDS=${db_RDS}
  sudo yum update -y
  sudo yum install -y httpd mariadb-server
  sudo systemctl start httpd && sudo systemctl enable httpd
  sudo systemctl start mariadb
  sudo usermod -a -G apache ec2-user
  sudo chown -R ec2-user:apache /var/www
  sudo chmod 2775 /var/www && find /var/www -type d -exec sudo chmod 2775 {} \;
  find /var/www -type f -exec sudo chmod 0664 {} \;
  sudo yum install epel-release yum-utils wget -y
  sudo amazon-linux-extras enable php8.0
  sudo yum clean metadata && sudo yum install yum install php-cli php-pdo php-fpm php-mysqlnd -y
  sudo curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
  sudo chmod +x wp-cli.phar
  sudo mv wp-cli.phar /usr/local/bin/wp
  wp core download --path=/var/www/html --allow-root
  wp config create --dbname=$db_name --dbuser=$db_username --dbpass=$db_user_password --dbhost=$db_RDS --path=/var/www/html --allow-root
  sudo chown -R apache:apache /var/www/html
  sudo systemctl restart httpd
  sudo cd /var/www/html
  sudo wget https://wordpress.org/latest.tar.gz
  sudo tar -xzf latest.tar.gz
  sudo systemctl restart httpd
