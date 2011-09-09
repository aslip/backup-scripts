Configuration needed to run tests.

You must setup a passwordless ssh login to your machine from you (i.e. you must be able
to login to username@localhost being a username@localhost). For this you need these lines
in sshd_config (already there in Ubuntu 10.10):

    RSAAuthentication yes
    PubkeyAuthentication yes
    AuthorizedKeysFile %h/.ssh/authorized_keys # not needed in most cases - is a default setting

and then just add your public key to your authorized_keys file:

    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

To test your setup, type:

    ssh username@localhost

If you were able to successfully login without a password prompt, then everything is ok.

