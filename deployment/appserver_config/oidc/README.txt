Open ID Connect configuration


Installation Troubleshooting:

If you see an error from IQGeo Platform when you try to authenticate with OpenID Connect, you may 
have incorrectly configured the "issuer" key, which identifies the URI of the OpenID Connect 
provider. Please double check that address.

If you are seeing an error from the OpenID Connect provider, especially one which says something
like "client not found", then you may have a typo in the "client_id" in the config. Please double
check that setting with your OpenID Connect provider.
