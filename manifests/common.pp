

class ntp::common {

   $ntp_conf     = "/etc/ntp.conf"
   $ntpdate_conf = "/etc/default/ntpdate"

   $ntp_package = $operatingsystem ? {
      "Debian" => $lsbdistcodename ? {
          "sarge"  => "ntp-simple",
          "etch"   => "ntp-simple",
          default  => "ntp",
          },
      default  => "ntp",
   }

   $ntp_service = $operatingsystem ? {
      "Debian" => $lsbdistcodename ? {
         "sarge" => "ntp-server",
	 "etch"  => "ntp",
         default => "ntp",
	 },
      default  => "ntpd",
   }

   package { $ntp_package:
      ensure => installed
   }

   case $operatingsystem {
      "Debian": {
         package { 
            "ntpdate":
               ensure => installed;
         }

	 case $lsbdistcodename {
            "sarge": {
               service { "ntpdate": 
	          require => Package["ntpdate"]; 
	       }
	    }

	    "etch": {
               exec { "ntpdate":
	          command => "/usr/sbin/ntpdate-debian",
		  require => [ Package["ntpdate"], File["/etc/default/ntpdate"] ],
                  refreshonly => true;
	       }
            }
	       
	    "lenny": {
               exec { "ntpdate":
	          command => "/usr/sbin/ntpdate-debian",
		  require => [ Package["ntpdate"], File["/etc/default/ntpdate"] ],
                  refreshonly => true;
	       }
            }
	       
	 }



         # Only launch hwclock on physical machines
         if defined(Class['virtual']) {
           notice "Not doing hwclock on a virtual machine"
         } else {
	   exec { "hwclock":
              command => "/sbin/hwclock --systohc" ,
	      require => $lsbdistcodename ? {
	         "sarge" => Service["ntpdate"],
	         "etch"  => Exec["ntpdate"],
                 default => Exec["ntpdate"],
	         }
	   }
         }


	 service { $ntp_service:
	    require   => $lsbdistcodename ? {
	       "sarge" => [ Package[$ntp_package], Service["ntpdate"] ],
	       "etch"  => [ Package[$ntp_package], Exec["ntpdate"] ],
               default => [ Package[$ntp_package], Exec["ntpdate"] ],
	       },
	    subscribe => File["/etc/ntp.conf"];
	}

      }
         
      default: {
	 exec { "chkconfig":
	    command => "/sbin/chkconfig ntpd on"
	 }

	 service { $ntp_service:
	    require => [ Package[$ntp_package], Exec["chkconfig"] ]
	 }
      }
   }



     file {
        $ntp_conf:
           ensure  => present,
           mode    => 644,
           content => template("ntp/ntp.conf.erb"),
           require => Package[$ntp_package];

        $ntpdate_conf:
           ensure  => present,
           mode    => 644,
           content => template("ntp/ntpdate.erb"),
           require => Package[ntpdate],
      }

}



