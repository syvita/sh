# allow localhost to communicate with itself
sudo iptables -A INPUT -i lo -j ACCEPT

# allow already established connection and related traffic
sudo iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# allow new ssh connections
sudo iptables -A INPUT -p tcp --dport ssh -j ACCEPT

# ////  POSTGRES  \\\\

# drop external
# sudo iptables -A INPUT -p tcp --dport 5432 -j DROP

# ////  API (3999, 3700)  \\\\

# drop external (we use a tunnel to route this publicly)
# sudo iptables -A INPUT -p tcp --dport 3999 -j DROP
# drop external to event listener
# sudo iptables -A INPUT -p tcp --dport 3700 -j DROP

# ////  STACKS NODE (20443, 20444, 8332, 8333)  \\\\

# allow public traffic to these ports, required for node syncing
sudo iptables -A INPUT -p tcp --dport 20443 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 20444 -j ACCEPT
sudo iptables -A OUTPUT -p tcp --dport 8332 -j ACCEPT
sudo iptables -A OUTPUT -p tcp --dport 8333 -j ACCEPT
sudo iptables -A OUTPUT -p tcp --dport 20443 -j ACCEPT
sudo iptables -A OUTPUT -p tcp --dport 20444 -j ACCEPT

# ////  DROP ALL OTHER TRAFFIC  \\\\

sudo iptables -A INPUT -j DROP