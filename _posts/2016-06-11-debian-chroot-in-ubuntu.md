---
title: "Debian Chroot in Ubuntu"
layout: post
date: 2016-06-11 20:51
description:
tag:
- Debian
- Ubuntu
- GSOC
blog: true
---

In order to develop and package for Debian, a testing environment is required, that's why I've setup a Debian [chroot][3] environment in my computer (Ubuntu) using Debootstrap.

<div class="text-center">
<img src="{{ site.url }}/assets/images/blog/chroot-debian.png" alt="Chroot using Debootstrap Simplified Diagram">
<figcaption class="caption">Chroot using Debootstrap Simplified Diagram</figcaption>
</div>

To do this  I've run the following commands:
{% highlight bash %}
$ sudo apt-get install schroot dchroot debootstrap
$ sudo debootstrap sid /sid-root http://httpredir.debian.org/debian/
{% endhighlight %}
Then I appended to the file `/etc/fstab` the following lines:
{% highlight text %}
/home/mouaad      /sid-root/home/mouaad         none    bind            0       0
/opt              /sid-root/opt                 none    bind            0       0
/export           /sid-root/export		none    bind            0       0
/tmp              /sid-root/tmp                 none    bind            0       0
/dev              /sid-root/dev                 none    bind            0       0
proc-chroot       /sid-root/proc                proc    defaults        0       0
devpts-chroot     /sid-root/dev/pts	        devpts  defaults        0       0
binfmt_misc	  /sid-root/proc/sys/fs/binfmt_misc  binfmt_misc rw,nosuid,nodev,noexec,relatime 0 0
sysfs		  /sid-root/sys                 sysfs   rw,nosuid,nodev,noexec,relatime  0  0
{% endhighlight %}
{% highlight bash %}
$ mount -a
{% endhighlight %}
To the file `/etc/schroot/schroot.conf` I appended:
{% highlight text %}
[sid-root]
description=Debian sid
directory=/sid-root
aliases=default
users=mouaad
{% endhighlight %}
And finaly :
{% highlight bash %}
$ sudo su -c 'echo "stretch /sid-root" > /etc/dchroot.conf'
{% endhighlight %}

Now to change to chroot is simply type:
{% highlight bash %}
$ dchroot #sudo chroot for root
{% endhighlight %}

Now that I am on chroot I've run the following commands to setup the environement for packaging:
{% highlight bash %}
$ apt-get update
$ apt-get install debconf devscripts gnupg
$ apt-get install locales
$ locale-gen
{% endhighlight %}

And finaly, the debian chroot environement is ready !

Cheers,<br />
Mouaad

####  Sources:
* [https://wiki.debian.org/Debootstrap][1]
* [https://wiki.ubuntu.com/DebootstrapChroot][2]

[1]: https://wiki.debian.org/Debootstrap
[2]: https://wiki.ubuntu.com/DebootstrapChroot
[3]: https://en.wikipedia.org/wiki/Chroot
