---
title: "BNC and AWS"
layout: post
date: 2016-06-07 06:54
description: "IRC Bouncer (ZNC) and Amazon Web Service (EC2)"
tag:
- IRC
- AWS
blog: true
---

As a Developer (and especially for FOSS contributing) I need to be always on communication tools like IRC, but I had two problems: First: I can’t connect from multiple devices at the same time with same nickname (which identify me), Second and more important: missing discussions while not connected (especially for the channels without log). That’s why I decided to use [IRC bouncers][1] to resolve this.

There are multiple bouncers providers ([free][2] and [limited][3]/paid). I’ve tested a couple of them but they did not satisfy me (limited servers, servers drops, security concerns..etc).

To overcome this I decided to install a bouncer by my own, so I used [ZNC][4], a really good bouncer with multiple modules who do exactly the job.<br /> 

<div class="text-center" markdown="1">
![ZNC Bouncer][14]
</div>

At the beginning, I used [Openshift][5] (here is [quickstart][6]), but again I wasn’t fully satisfied (requires an ongoing ssh connection, the service stops after a while of not been connected..etc).

Finally I decided to use a VPS, so I used [Amazon Web Service][7] to do this ! First, I [setup an EC2][8] Instance (Ubuntu) with an [Elastic IP][9] (free tier with a [billing alarm][10]), Next, I connected using SSH then I [setup the ZNC Bouncer][11].<br />
The last thing to take care of was the security group of the EC2 instance from the management console , so I added the ZNC port as TCP inbound port and the IRC servers default port 6697 as TCP outbound port.

After all this, the bouncer was ready and now I am able to [connect][12] to as many IRC servers as I want without losing my session, and get connected with multiple devices and I can edit specific configs (like increasing the log buffer) for every channel or server from the web interface (`http://<elastic_IP>:<znc_port>`) or from the [line command][13] on the IRC client.

To access the control panel from my domain, I've [added a subdomain][15] that points to the IP address of my EC2 server from my domain control pannel. I've checked if this with the command: `$ host <sub.domain.tld>`<br />
Now to access the control panel I simply go to `https://<sub.domain.tld>:<znc_port>`. 

By default `/whois` shows the default AWS's hostname. To change this I've requested a [reverse DNS][16] record. I got a respond from amazon next day saying that my request has been configured. I've checked this with the command: `$ host <elastic_IP>`<br />
I reconnected the ZNC to the IRC server: `/msg *status connect`<br />
And now `/whois` show my new hostname correctly !

Cheers,<br />
Mouaad

[1]: https://en.wikipedia.org/wiki/BNC_(software)#IRC
[2]: http://wiki.znc.in/Providers
[3]: https://www.irccloud.com/
[4]: http://wiki.znc.in/ZNC
[5]: https://www.openshift.com/about/index.html
[6]: https://github.com/cjryan/znc-openshift-quickstart
[7]: https://aws.amazon.com/
[8]: http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EC2_GetStarted.html#ec2-launch-instance_linux
[9]: http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html#using-instance-addressing-eips-allocating
[10]: http://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/free-tier-alarms.html
[11]: https://www.digitalocean.com/community/tutorials/how-to-install-znc-an-irc-bouncer-on-an-ubuntu-vps
[12]: http://wiki.znc.in/HexChat
[13]: http://wiki.znc.in/Using_commands
[14]: http://wiki.znc.in/images/4/4f/Overview_network_scheme.png
[15]: https://uk.godaddy.com/help/add-a-subdomain-that-points-to-an-ip-address-4080
[16]: http://aws.amazon.com/fr/ec2/faqs/#Can_I_configure_the_reverse_DNS_record_for_my_Elastic_IP_address
