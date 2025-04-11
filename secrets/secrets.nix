let
  ymir = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgjjvukAG0RvQfHj5Iy64XOFh9YbdnNAmgFUvzlnAEt";
  tartarus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMxbIyQnQFA1RFQKH4eHHWcT7Z0tCumerCsRMjlHgSPd";
  pochita = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHpE9pf7ZeNvpW1GxLLF8kB0Q8HQO7XSIea1Oe9qubKt";

  osbm = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPfnV+qqUCJf92npNW4Jy0hIiepCJFBDJHXBHnUlNX0k";

  machines = [
    ymir
    tartarus
    pochita
  ];
in {
  "network-manager.age".publicKeys = machines ++ [osbm];
  "ssh-key-private.age".publicKeys = machines ++ [osbm];
  "ssh-key-public.age".publicKeys = machines ++ [osbm];
  "cloudflare.age".publicKeys = machines ++ [osbm];
}
