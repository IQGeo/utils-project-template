Open ID Connect configuration


Configuration Options:

The OIDC configuration can be set using environment variables. This is the recommended approach for most use cases, as it allows for flexible and dynamic configuration without modifying files directly.

If you require full control over the OIDC configuration, you may override the default by copying the example below into a file named conf.json in this directory. Edit the values as needed for your environment.

Example conf.json
{
    "httpc_params": {
        "verify": false
    },
    "clients": {
        "iqgeo-oidc": {
            "issuer": "http://keycloak.local:8080/realms/iqgeo",
            "client_id": "iqgeo-oidc",
            "client_secret": "qpyu1mCm8zvvKTXRnKxwap1A6xMChuY6",
            "redirect_uris": [
                "{myw_ext_base_url}/auth",
                "{myw_ext_base_url}/auth?redirect_to=index",
                "{myw_ext_base_url}/auth/anywhere/myw_oidc_auth_engine"
            ],
            "post_logout_redirect_uris": ["{myw_ext_base_url}"],
            "behaviour": {
                "response_types": ["code"],
                "scope": ["openid", "profile", "roles"],
                "token_endpoint_auth_method": ["client_secret_basic", "client_secret_post"]
            },
            "services": {
                "discovery": {
                    "class": "oidcrp.oidc.provider_info_discovery.ProviderInfoDiscovery",
                    "kwargs": {}
                },
                "authorization": {
                    "class": "oidcrp.oidc.authorization.Authorization",
                    "kwargs": {}
                },
                "accesstoken": {
                    "class": "oidcrp.oidc.access_token.AccessToken",
                    "kwargs": {}
                },
                "userinfo": {
                    "class": "oidcrp.oidc.userinfo.UserInfo",
                    "kwargs": {}
                },
                "end_session": {
                    "class": "oidcrp.oidc.end_session.EndSession",
                    "kwargs": {}
                },
                "refresh_access_token": {
                    "class": "oidcrp.oidc.refresh_access_token.RefreshAccessToken",
                    "kwargs": {}
                }
            },
            "add_ons": {
                "pkce": {
                    "function": "oidcrp.oauth2.add_on.pkce.add_support",
                    "kwargs": {
                        "code_challenge_length": 64,
                        "code_challenge_method": "S256"
                    }
                }
            }
        }
    }
}


Troubleshooting:

If you see an error from IQGeo Platform when you try to authenticate with OpenID Connect, check the "issuer" key, which identifies the URI of the OpenID Connect provider. Ensure it is correct.

If you see an error from the OpenID Connect provider, such as "client not found", verify the "client_id" value matches your provider's configuration.