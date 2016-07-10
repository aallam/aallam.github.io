---
title: "Debconf into Debian Packages"
layout: post
date: 2016-07-10 03:09
description:
tag:
- Debian
- GSoC
blog: true
jemoji:
---

As part of my GSoC project, I had to find a way to ask users questions and install the packages depending on the given answers, my specific case was to ask the user to select an entry from multiple choices, to achieve this, I used debconf.

So what is debconf ?

> Debconf is a backend database, with a frontend that talks to it and presents an interface to the user. There can be many different types of frontends, from plain text to a web frontend. The frontend also talks to a special config script in the control section of a Debian package, and it can talk to postinst scripts and other scripts as well, all using a special protocol. These scripts tell the frontend what values they need from the database, and the frontend asks the user questions to get those values if they aren't set.

Even better, we can make sure that the users get the questions in their own languages; and the perfect way to do this ? `po-debconf` !

<div class="text-center" markdown="1">
![Debconf Frontend][5]
</div>

###Steps:

* Install `debconf` and `po-debconf`:
{% highlight bash %}
$ apt install debconf po-debconf
{% endhighlight %} 

* Create `debian/templates` file, an underscore before a field name indicates that the field is translatable. Example:

{% highlight control %}
Template: packagename/something
Type: select
Choices: choice1, choice2
Default: choice1
_Description: A short description here
 A longer description here about the quastion.
{% endhighlight %}

* Create debian/config file, `packagename/somthing` is the same as in `debian/templates`:

{% highlight sh %}
#!/bin/sh

set -e

# Source debconf library.
. /usr/share/debconf/confmodule

# Run template
db_input high packagename/something || true
db_go

#DEBHELPER#

exit 0
{% endhighlight %}

* Create the folder `debian/po`
{% highlight bash %}
$ cd debian && mkdir po
{% endhighlight %}

* Create the file `debian/po/PORFILES.in`:
{% highlight bash %}
$ echo "[type: gettext/rfc822deb] templates" > po/POTFILES.in
{% endhighlight %}

* Generate the `debian/po/templates.pot`:
{% highlight bash %}
$ debconf-updatepo
{% endhighlight %}

* Add `debconf` and `po-debconf` to `debconf/control` as dependenties:

{% highlight debcontrol %}
Depends: debconf,
         po-debconf,
         ${misc:Depends}
{% endhighlight %}


* Get and use the result (in `debian/postinit` for example with the variable `$RET`):

{% highlight sh %}
#!/bin/sh

set -e

# Source debconf library.
. /usr/share/debconf/confmodule
db_get packagename/something

case "$1" in
    configure)
        make -C /var/cache/packagename/ DL_MIRROR="$RET" install
    ;;

    abort-upgrade|abort-remove|abort-deconfigure)
    ;;

    *)
        echo "postinst called with unknown argument \`$1'" >&2
        exit 1
    ;;
esac

#DEBHELPER#

exit 0
{% endhighlight %}

* We can purge the database when purging the package with the command `db_purge` command in `debian/postrm`, example:

{% highlight sh %}
#!/bin/sh

set -e

case "$1" in
    purge)
        rm -rf /var/cache/packagename
        if [ -e /usr/share/debconf/confmodule ]
        then
                # Source debconf library and purge db
                . /usr/share/debconf/confmodule
                db_purge
        fi
        ;;

    remove|upgrade|failed-upgrade|abort-install|abort-upgrade|disappear)
        ;;

    *)
        echo "postrm called with unknown argument \`$1'" >&2
        exit 1
        ;;
esac

#DEBHELPER#

exit 0
{% endhighlight %}

* We can add the entry `packagename.postrm.debhelper` to `.gitignore`.

###Examples:

* [Google Android M2 Repository Installer][1]
* [Google Android SDK Docs Installer][2] 

###Sources

* [The debconf programmer's tutorial][3]
* [The package po-debconf manuel][4]

[1]: https://github.com/Aallam/debian_google-android-m2repository-installer
[2]: https://github.com/Aallam/debian_google-android-sdk-docs-installer
[3]: http://www.fifi.org/doc/debconf-doc/tutorial.html
[4]: http://manpages.ubuntu.com/manpages/wily/man7/po-debconf.7.html
[5]: {{ site.url }}/assets/images/blog/debconf.png
