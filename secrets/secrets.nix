let
  # cat /etc/ssh/ssh_host_ed25519_key.pub on each machine
  ymir = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgjjvukAG0RvQfHj5Iy64XOFh9YbdnNAmgFUvzlnAEt";
  tartarus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMxbIyQnQFA1RFQKH4eHHWcT7Z0tCumerCsRMjlHgSPd";
  pochita = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHpE9pf7ZeNvpW1GxLLF8kB0Q8HQO7XSIea1Oe9qubKt";
  wallfacer = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOr8pQvLsNCHQdsBKWpziYTPjBkEcQy272kZ5Gqoaatt";
  apollo = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINsV8e8veX5/weeC8he+31aiNVZfQ82BpvSzARSM1uZF";
  artemis = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINd4wF1LicIvwpGQyajJsiUjeLV84nu4fsyJzxhbS+xK";

  osbm = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPfnV+qqUCJf92npNW4Jy0hIiepCJFBDJHXBHnUlNX0k";

  machines = [
    ymir
    tartarus
    pochita
    wallfacer
    apollo
  ];
in
{
  "network-manager.age".publicKeys = machines ++ [ osbm ];
  "ssh-key-private.age".publicKeys = machines ++ [ osbm ];
  "ssh-key-public.age".publicKeys = machines ++ [ osbm ];
  "cloudflare.age".publicKeys = machines ++ [ osbm ];
  "vaultwarden.age".publicKeys = machines ++ [ osbm ];
  "osbm-mail.age".publicKeys = machines ++ [ osbm ];
  "forgejo-mail.age".publicKeys = machines ++ [ osbm ];
  "vaultwarden-mail.age".publicKeys = machines ++ [ osbm ];
  "noreply-mail.age".publicKeys = machines ++ [ osbm ];
}
