echo ex.sh phar文件 解压目标文件
mkdir $2
php -dphar.readonly=0 empir extract $1 $2
