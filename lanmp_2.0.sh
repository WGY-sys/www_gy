#!/bin/bash
# install LAMP and LNMP service scripts
NGHOME=/usr/local/nginx
WEBHOME=/usr/local/httpd
MYHOME=/usr/local/mysql
PHPHOME=/usr/local/php
INSPACK=/usr/local/src
INSHOME=/usr/local



read -p "请确认是否安装过LAMP或者LNMP [y/n] y:安装过 n:没 ? :" WGY
[ $WGY = "y" ] && echo "请删除相关的软件，在执行该脚本" && exit 4

#查看是否有需要文件的相关权限
[ $USER != "root" ] && echo "权限不足,请提权到root用户" && exit 20

echo ""

#安装依赖包
echo "正在安装相关程序包"
yum -y install libxml2-devel php-pear libcurl-devel libzip libzip-devel openssl-devel openssl bzip2-devel zlib-devel zlib libjpeg-devel libpng libpng-devel freetype-devel freetype pcre-devel apr-devel apr-util-devel gcc* cmake ncurses-devel autoconf automake &>/dev/null
if [ $? -eq 0 ]; then
	echo "相关程序安装成功"
else
	echo "相关程序包安装失败,请查看是否配置了yum源"
	exit 33
fi

echo ""

#确定安装环境
while true 
do
	#确认安装那种环境
	while true
	do
        	read -p "请输入你要配置的环境[1/2] 1为LAMP，2为LNMP:" LMP
			
        	expr $LMP + 1 &>/dev/null
        	if [ $? -eq 0 ] ; then

			if [ $LMP -eq 1 ] || [ $LMP -eq 2 ] ; then
				break
			else
				echo "Error!!! 请输入[1/2] 1为LAMP，2为LNMP" && continue
			fi
		
		else
			echo "Error!!! 请输入[1/2] 1为LAMP，2为LNMP" && continue
		fi

	done
	
	#确认安装包的路径
	read -p "请输入LAMP/LNMP安装包的目录(将他们放在一起,而且目录中文件的主名不要有同名如：不能同时存在nginx-1.1.1和nginx-2.2.2):" INSDIR


        if ls $INSDIR/mysql* &>/dev/null ; then
                mysql=$(ls $INSDIR/mysql*)
                echo "你的mysql压缩包所在的路径为: $mysql"
        else
                echo "你的mysql压缩包不存在"
        fi



        if ls $INSDIR/php* &>/dev/null ; then
                php=$(ls $INSDIR/php*)
                echo "你的php压缩包所在的路径为: $php"
        else
                echo "你的php压缩包不存在"
        fi



        if [ $LMP -eq 1 ] ; then

                if ls $INSDIR/httpd* &>/dev/null ; then
                        http=$(ls $INSDIR/httpd*)
                        echo "你的http/nginx压缩包所在的路径为: $http"
                else
                        echo "你的http/nginx压缩包不存在"
                fi

        else
                if ls $INSDIR/nginx* &>/dev/null ; then
                        http=$(ls $INSDIR/nginx*)
                        echo "你的http/nginx压缩包所在的路径为: $http"
                else
                        echo "你的http/nginx压缩包不存在"
                fi
        fi


echo ""

        read -p "是否确认？ [y/n] " bbb
        if [ $bbb == "y" ]; then
                break
        fi
done

echo ""

if [ "$LMP" -eq 1 ]; then
	echo "正在安装LAMP环境++++++++++++++++++++++++++++++++++++++++++++++++++"
else
	echo "正在安装LNMP环境++++++++++++++++++++++++++++++++++++++++++++++++++"
fi








################################################################函数配置################################################################
################################################################函数配置################################################################
################################################################函数配置################################################################
################################################################函数配置################################################################
################################################################函数配置################################################################
################################################################函数配置################################################################
################################################################函数配置################################################################
################################################################函数配置################################################################
# nginx service install script function
funnginx(){

#开始安装
#编译配置函数

insnginx(){
	./configure --prefix=./configure --prefix=${NGHOME} --with-http_dav_module --with-http_stub_status_module --with-http_addition_module --with-http_sub_module --with-http_flv_module --with-http_mp4_module --user=nginx --group=nginx
}

#判断是否安装过nginx服务
echo "正在测试是否安装过了nginx服务......."

rpm -qa |grep nginx &>/dev/null
if [ $? -eq 0 ]; then
        echo "检测到该系统已存在nginx服务，请先卸载了nginx在进行安装"
        exit 8
fi


#创建nginx运行用户
echo "正在创建nginx运行用户........."
/usr/bin/id nginx &>/dev/null
if [ $? -eq 0 ]; then
	echo "nginx用户已存在,无需创建......."
else
	/usr/sbin/useradd -M -s /sbin/nologin nginx &>/dev/null
	echo "nginx用户创建成功......"
fi



#判断软件包是否存在
if [ ! -f $http ]; then
        echo "未检查到nginx软件包"
        exit 1
else
        #解压
        echo "正在解压安装包............."
        tar -xf $http -C $INSPACK &>/dev/null
        if [ $? -ne 0 ]; then
                echo "解压nginx压缩包失败"
                exit 4
        fi
        echo "解压成功！！！"

        #开始编译安装
        cd $INSPACK/nginx*

        echo "开始编译前配置"
        insnginx &>/dev/null
        if [ $? -eq 0 ]; then
                echo "配置完成,开始编译"
                sleep 3
        else
                echo "配置失败,请检查是否安装了依赖包,或者该软件包是否为nginx的软件包"
                exit 2
        fi
        make -j 4 &>/dev/null && make install &>/dev/null
	if [ $? -eq 0 ]; then
                echo "nginx编译安装成功........"
        else
                echo "nginx编译安装失败........"
                exit 3
        fi
fi

#修改nginx安装目录相关权限
/usr/bin/chown -R nginx: ${NGHOME} &>/dev/null && echo "nginx安装目录相关权限修改成功" || echo "nginx安装目录相关权限修改失败,请手动修改"


#优化执行脚本的路径
ln -s ${NGHOME}/sbin/* ${INSHOME}/sbin/ &>/dev/null && echo "可执行文件优化成功" || echo "可执行文件优化失败,请手动优化"


#配置Nginx支持php解析
if [ -f ${NGHOME}/conf/nginx.conf ]; then
	cp ${NGHOME}/conf/nginx.conf ${NGHOME}/conf/nginx.conf.bak &>/dev/null
	sed -i 's/index  index.html index.htm;/index  index.php index.html;/'												${NGHOME}/conf/nginx.conf &>/dev/null

	sed -i '65c\location ~ \.php$ {' 																${NGHOME}/conf/nginx.conf &>/dev/null
	
	sed -i 's/#    root           html;/root           html;/' 													${NGHOME}/conf/nginx.conf &>/dev/null
	
	sed -i 's/#    fastcgi_pass   127.0.0.1:9000;/fastcgi_pass   127.0.0.1:9000;/'											${NGHOME}/conf/nginx.conf &>/dev/null
	
	sed -i 's/#    fastcgi_index  index.php;/fastcgi_index  index.php;/'												${NGHOME}/conf/nginx.conf &>/dev/null
	
	sed -i 's*#    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;*fastcgi_param  SCRIPT_FILENAME  /usr/local/nginx/html$fastcgi_script_name;*'	${NGHOME}/conf/nginx.conf &>/dev/null
	
	sed -i 's/#    include        fastcgi_params;/include        fastcgi_params;/'											${NGHOME}/conf/nginx.conf &>/dev/null
	
	sed -i '71c\         }' 																	${NGHOME}/conf/nginx.conf &>/dev/null

	echo "配置nginx解析php成功"
else
	echo "配置nginx解析php失败,请手动添加"
fi



echo "安装结束............................"
echo "=================================================
nginx安装目录: $NGHOME
启动脚本:      $NGHOME/sbin/nginx
配置文件:      ${NGHOME}/conf/nginx.conf
================================================="
echo ""
}






# httpd service install script function
funhttpd(){

#开始安装
#编译配置函数
inshttpd(){
	 ./configure --prefix=${WEBHOME} --enable-so --enable-rewrite --enable-modules=most --enable-mpms-shared=all
}

#判断是否安装过httpd服务
echo "正在测试是否安装过了httpd服务......."

rpm -qa |grep httpd &>/dev/null
if [ $? -eq 0 ]; then
        echo "检测到该系统已存在httpd服务，请先卸载了httpd在进行安装"
        exit 8
fi


echo ""

#判断软件包是否存在
if [ ! -f $http ]; then
        echo "未检查到httpd软件包"
        exit 1
else
        #解压
        echo "正在解压安装包............."
        tar -xf $http -C $INSPACK &>/dev/null
        if [ $? -ne 0 ]; then
                echo "解压http压缩包失败"
                exit 4
        fi
        echo "解压成功！！！"

        #开始编译安装
        cd $INSPACK/httpd-*

        echo "开始编译前配置"
        inshttpd &>/dev/null
        if [ $? -eq 0 ]; then
                echo "配置完成,开始编译"
                sleep 3
        else
                echo "配置失败,请检查是否安装了依赖包,或者该软件包是否为httpd的软件包"
                exit 2
        fi
	make -j 4 &>/dev/null && make install &>/dev/null
	if [ $? -eq 0 ]; then
                echo "安装成功！！！"
        else
                echo "安装失败"
                exit 3
        fi
fi

#优化可执行文件的路径
ln -s ${WEBHOME}/bin/* $INSHOME/bin/ &>/dev/null && echo "可执行文件路径>优化成功" || echo "可执行文件路径优化失败"

#配置httpd服务启动脚本
cp ${WEBHOME}/bin/apachectl /etc/init.d/httpd &>/dev/nul
if [ $? -eq 0 ]; then

        sed -i '1a\#chkconfig: 2345 45 68' /etc/init.d/httpd &>/dev/null && echo "启动脚本配置成功"

        /usr/sbin/chkconfig --add httpd &>/dev/null && echo "开机自启成功" || echo "开机自启失败,请查看/etc/init.d/下是否有启动脚本"

        service httpd start &>/dev/null && echo "服务启动成功" || echo "服务启动失败,请查看/etc/init.d/下是否有启动脚本"

else
        echo "启动脚本配置失败"
	exit 88
fi
echo "安装结束................................"
echo  "=================================================
apache安装目录: ${WEBHOME}
启动脚本:      /etc/init.d/httpd
配置文件:      ${WEBHOME}/conf/httpd.conf
================================================="
echo ""
}





#Mysql service install function
funmysql(){
#开始安装

#编译配置函数
cmakemy(){
cmake -DCMAKE_INSTALL_PREFIX=${MYHOME} -DMYSQL_UNIX_ADDR=/tmp/mysql.sock -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DWITH_EXTRA_CHARSETS=all -DMYSQL_DATADIR=${MYHOME}/data -DMYSQL-USER=mysql 
}

#初始化mysql函数
lnitimy(){
${MYHOME}/scripts/mysql_install_db --defaults-file=/etc/my.cnf --basedir=${MYHOME} --datadir=${MYHOME}/data --user=mysql
}

#判断是否安装过mysql或者mariadb
echo "正在测试是否安装过了maraidb数据库......."

rpm -qa |grep mariadb-server &>/dev/null
if [ $? -eq 0 ]; then
        echo "检测到该系统已存在数据库服务，请先卸载了maraidb在进行安装"
        exit 8
fi



#创建mysql运行用户
echo "正在创建mysql运行用户........."
        /usr/bin/id mysql &>/dev/null
        if [ $? -eq 0 ]; then
                echo "mysql用户已存在,无需创建......."
        else
                /usr/sbin/useradd -M -s /sbin/nologin mysql &>/dev/null
                echo "mysql用户创建成功......"
        fi



#判断软件包是否存在
if [ ! -f $mysql ]; then
        echo "未检查到mysql软件包,请查看软件包路径是否输入正确"
        exit 1
else
        #解压
        echo "正在解压mysql安装包............."
        tar -xf $mysql -C $INSPACK &>/dev/null
        if [ $? -ne 0 ]; then
                echo "解压mysql压缩包失败"
                exit 4
        fi
        echo "解压成功！！！"


        #开始编译安装
        cd $INSPACK/mysql-* &>/dev/null

        echo "开始mysql安装前配置"
        cmakemy &>/dev/null
        if [ $? -eq 0 ]; then
                echo "mysql配置完成,开始编译........"
                sleep 3
        else
                echo "配置失败,请检查是否安装了依赖包,或者该软件包是否为mysql的软件包"
                exit 2
        fi

        echo "开始编译安装mysql数据库"
        make -j 4 &>/dev/null && make install &>/dev/null
        if [ $? -eq 0 ]; then
                echo "mysql编译安装成功........"
        else
                echo "mysql编译安装失败........"
                exit 3
        fi
fi


#修改mysql安装目录相关权限
/usr/bin/chown -R mysql: ${MYHOME} &>/dev/null && echo "mysql安装目录相关权限修改成功" || echo "mysql安装目录相关权限修改失败,请手动修改"

#生成mysql配置文件
[ -f /etc/my.cnf ] && rm -rf /etc/my.cnf &>/dev/null
cp ${MYHOME}/support-files/my-default.cnf /etc/my.cnf &>/dev/null && echo "生成配置文件成功" || echo "生成配置文件成功失败,请手动生成配置文件" 

#优化可执行文件路径
ln -s ${MYHOME}/bin/* $INSHOME/bin/ &>/dev/null && echo "优化可执行文件成功" || echo "优化可执行文
件失败,请手动优化"

#配置启动脚本
cp $MYHOME/support-files/mysql.server /etc/init.d/mysqld &>/dev/null
if [ $? -eq 0 ]; then
        sed -i '4a\basedir=/usr/local/mysql' /etc/init.d/mysqld &>/dev/null && sed -i '5a\datadir=/usr/local/mysql/data' /etc/init.d/mysqld &>/dev/null && echo "启动脚本修改成功" || echo "启动脚本修改
失败"

else
        echo "启动脚本复制失败"
        exit 3
fi


#初始化数据库
lnitimy &>/dev/null && echo "初始化数据库成功"
if [ $? -ne 0 ]; then
        echo "初始化数据库失败,请检查autoconf安装包是否安装"
        exit 33
fi

#开启服务
/usr/sbin/chkconfig --add mysqld &>/dev/null && echo "开机自启成功" || echo ">开机自启失败,请查看/etc/init.d/下是否有启动脚本"
service mysqld start &>/dev/null && echo "服务启动成功" || echo "服务启动失败,请查看/etc/init.d/下是否有启动脚本"

echo "安装结束................................"
echo  "=================================================
mysql安装目录: $MYHOME
启动脚本:      /etc/init.d/mysqld
配置文件:      /etc/my.cnf
================================================="
echo ""

}





# PHP install scripts function
funphp(){
#开始安装

#编译LAMP环境的配置函数
LAMPHP(){
 ./configure --prefix=${PHPHOME} --with-mysql=${MYHOME} --with-mysqli=mysqlnd --with-apxs2=${WEBHOME}/bin/apxs --with-config-file-path=${PHPHOME} --enable-mbstring 
}

#编译LNMP环境的配置函数
LNMPHP(){
./configure --prefix=${PHPHOME} --with-config-file-path=${PHPHOME} --with-mysql=${MYHOME} --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl --enable-mbregex  --enable-fpm --enable-mbstring --with-gd --enable-mysqlnd --enable-gd-native-ttf --with-openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-soap --with-gettext 
}

#判断软件包是否存在
if [ ! -f $php ]; then
        echo "未检查到php软件包,请查看软件包路径是否输入正确"
        exit 1

else
	#解压
	echo "开始解压php包...."
	tar -xf $php -C ${INSPACK} &>/dev/null
	if [ $? -ne 0 ]; then
                echo "解压php包失败"
                exit 4
        fi
	echo "解压php包成功！！！"

	#开始进入安装过程
	cd ${INSPACK}/php* &>/dev/null
	echo "开始php安装前配置"
	
	#判断要安装那种环境
	if [ $LMP -eq 1 ]; then
		LAMPHP &>/dev/null
	else
		LNMPHP &>/dev/null
	fi

	#判读是否配置成功
	if [ $? -eq 0 ]; then
                echo "php配置完成,开始编译........"
        else
                echo "php配置失败,请检查是否安装了依赖包,或者该软件包是否为php的软件包"
                exit 2
        fi

	#正式开始编译
	make -j 4 &>/dev/null && make install &>/dev/null
		if [ $? -eq 0 ]; then
                	echo "php编译安装成功........"
        	else
               		echo "php编译安装失败........"
                	exit 3
       		fi

fi


#优化可执行文件路径
ln -s ${PHPHOME}/bin/* ${INSHOME}/bin/ &>/dev/null || echo "可执行文件优化失败"


cd ${INSPACK}/php* &>/dev/null 
PHPCONF=$(cp -rf php.ini-production ${PHPHOME}/php.ini)

#生成配置文件
$PHPCONF &>/dev/null && echo "php配置文件生成成功" || echo "php配置文件生成失败"



#配置LNMP支持php需要php-fpm的配置文件
if [ $LMP -eq 2 ]; then
	PHP_FPM=$(cp ${PHPHOME}/etc/php-fpm.conf.default ${PHPHOME}/etc/php-fpm.conf && cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm && chmod +x /etc/init.d/php-fpm && chkconfig --add php-fpm)

	${PHP_FPM} &>/dev/null
	if [ $? -ne 0 ]; then
		echo "php-fpm配置文件和启动脚本生成失败,请手动生成"
		exit 88
	else
		echo "php-fpm配置文件和启动脚本生成成功"
	fi
	
	#开启php-fpm模块   prot:9000
	service php-fpm start &>/dev/null start && echo "php-fpm模块开启成功" || echo "php-fpm 模块开启失败,请手动开启"

	#开启nginx服务
	nginx &>/dev/null && echo "nginx服务开启成功" || echo "nginx服务开启失败,请手动开启"
fi
 


#配置LAMP支持php
if [ $LMP -eq 1 ]; then

	#配置apache支持php
	echo "正在配置apache的配置文件"
	echo "AddType application/x-httpd-php .php" >>${WEBHOME}/conf/httpd.conf && echo "配置成功" || echo "配置失败"

	#检测apache是否支持php解析
	ls ${WEBHOME}/modules/httpd.exp &>/dev/null && ls ${WEBHOME}/modules/libphp5.so &>/dev/null && echo "检测到apache可以解析php" || echo "检测到apache无法解析php"


	#重启apache
	echo "正在重启apache服务"
	service httpd restart &>/dev/null
fi



if [ $LMP -eq 1 ]; then

	echo  "
=================================================
php安装目录: ${PHPHOME}
配置文件:    ${PHPHOME}/php.ini
=================================================
"
	echo ""

else
	echo  "
=================================================
php安装目录:     ${PHPHOME}
php-fpm启动脚本: /etc/init.d/php-fpm
配置文件:        ${PHPHOME}/php.ini
=================================================
"
	echo ""

fi

}


################################################################结束################################################################
################################################################结束################################################################
################################################################结束################################################################
################################################################结束################################################################
################################################################结束################################################################
################################################################结束################################################################






#正式安装
case $LMP in
	1)
		if funhttpd ; then
			echo "整个httpd服务安装配置成功,正在安装mysql服务配置......................."
			cat > $WEBHOME/html/index.php <<EOF
			<?php phpinfo(); ?>
EOF
		
			sleep 2
		
			funmysql
			if [ $? -eq 0 ]; then
				echo "整个mysql安装配置成功,正在安装php........................"
		
				sleep 2
		
				funphp && echo "整个LAMP安装配置成功,结束..................."
				if [ $? -ne 0 ]; then
					echo "php安装配置失败"
					exit 100
				fi
			else
		
				echo "mysql安装失败"
			fi
		
		else
			echo "httpd安装失败，正在退出"
			exit 99
		fi
	;;
	2)
		if funnginx ; then
                         echo "整个nginx服务安装配置成功,正在安装mysql服务配置......................."
			 cat > $NGHOME/html/index.php <<EOF
			 <?php phpinfo(); ?>
EOF
 
                         sleep 2
 
                         funmysql
                         if [ $? -eq 0 ]; then
                                 echo "整个mysql安装配置成功,正在安装php........................"
 
                                 sleep 2
 
                                 funphp && echo "整个LNMP,结束..................."
                                 if [ $? -ne 0 ]; then
                                         echo "php安装配置失败"
                                         exit 100
                                 fi
                         else
 
                                 echo "mysql安装失败"
                         fi
 
		else
                         echo "httpd安装失败，正在退出"
                         exit 99
		fi
esac

