{
  username,
  uid,
  hostname,
  ...
}:

#############################################################
#
#  Host & Users configuration
#
#############################################################

{
  networking.hostName = hostname;
  networking.computerName = hostname;
  networking.localHostName = hostname;

  users.users."${username}" = {
    inherit uid;
    home = "/Users/${username}";
    description = username;
  };

  nix.settings.trusted-users = [ username ];
}
